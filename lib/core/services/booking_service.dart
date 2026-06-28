import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking_model.dart';

// ═══════════════════════════════════════════════════════════
//  BOOKING SERVICE — "Timestamp Expiration" Anti-Ghost-Seat
//
//  ARSITEKTUR BARU:
//  ┌─────────────────────────────────────────────────────┐
//  │  seat_locks/{fleetId}_{date}                        │
//  │  ├─ seats: { "1": {bookingId, status, expiryDate} } │
//  │  └─ Single-doc lock → 100% atomic transaction       │
//  ├─────────────────────────────────────────────────────┤
//  │  bookings/{bookingId}                               │
//  │  ├─ selectedSeatLabels, status, expiryDate          │
//  │  └─ StreamBuilder source for real-time seat UI      │
//  └─────────────────────────────────────────────────────┘
//
//  FLOW:
//  1. createBooking → reads seat_locks doc (atomic lock)
//     → checks each seat (paid/used = SOLD, pending+active = LOCKED)
//     → expired pending = AVAILABLE (overwritten)
//     → creates booking doc + updates seat_locks + deducts fleet seats
//
//  2. confirmPayment → updates booking + seat_locks (pending→paid)
//
//  3. cancelBooking → updates booking + removes from seat_locks
//     → restores fleet availableSeats
//
//  4. cleanupExpiredBookings → batch-cancels expired pending bookings
//     → called on seat selection page init (client-side GC)
//
//  ANTI GHOST-SEAT:
//  - 15-min expiryDate on pending bookings
//  - Client-side filter ignores expired pending (UI)
//  - Cleanup function cancels expired pending (Firestore)
//  - Payment page auto-cancels on timer expiry
// ═══════════════════════════════════════════════════════════
class BookingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Duration for pending booking expiry.
  static const Duration kExpiryDuration = Duration(minutes: 15);

  /// Generate the seat_locks document ID for a fleet+date pair.
  static String _lockDocId(String fleetId, String departureDate) =>
      '${fleetId}_${departureDate.replaceAll(' ', '_')}';

  // ─────────────────────────────────────────────────────
  //  CREATE BOOKING — Atomic Transaction with Seat Locks
  // ─────────────────────────────────────────────────────
  /// Creates a pending booking while atomically locking seats.
  ///
  /// Transaction reads **seat_locks** doc (single-doc lock pattern)
  /// to guarantee no race condition / double-booking.
  ///
  /// Returns the created [BookingModel] with its Firestore ID.
  /// Throws [SeatAlreadyBookedException] if selected seats are taken.
  /// Throws [InsufficientSeatsException] if not enough fleet seats.
  /// Throws [FleetNotFoundException] if fleet doc is missing.
  static Future<BookingModel> createBooking(BookingModel booking) async {
    final now = DateTime.now();
    final expiryDate = now.add(kExpiryDuration);

    final lockDocId = _lockDocId(booking.fleetId, booking.departureDate);
    final lockRef = _db.collection('seat_locks').doc(lockDocId);
    final fleetRef = _db.collection('fleets').doc(booking.fleetId);
    final bookingsRef = _db.collection('bookings');

    return await _db.runTransaction<BookingModel>((transaction) async {
      // ── STEP 1: Read seat_locks document (atomic lock) ──
      final lockSnap = await transaction.get(lockRef);
      final lockData =
          lockSnap.exists ? lockSnap.data() : null;
      final seatEntries = Map<String, dynamic>.from(
        lockData?['seats'] ?? {},
      );

      // ── STEP 2: Read fleet document ──
      final fleetSnap = await transaction.get(fleetRef);
      if (!fleetSnap.exists) {
        throw FleetNotFoundException(booking.fleetId);
      }
      final fleetData = fleetSnap.data()!;
      final int totalSeats =
          (fleetData['totalSeats'] as num?)?.toInt() ?? 0;
      final String fleetName =
          fleetData['name'] as String? ?? 'Unknown Fleet';

      // ── STEP 3: Check each selected seat against lock map ──
      // KEY: Exclude the CURRENT USER's own pending locks.
      // If a user had a previous pending booking, they can re-book.
      final currentUserId = booking.userId;
      final conflicted = <String>[];
      for (final seat in booking.selectedSeatLabels) {
        if (seatEntries.containsKey(seat)) {
          final entry = Map<String, dynamic>.from(
            seatEntries[seat] as Map<dynamic, dynamic>,
          );
          final status = entry['status'] as String? ?? '';
          final lockUserId = entry['userId'] as String? ?? '';

          if (status == 'paid' || status == 'used') {
            // Permanently sold — conflict (regardless of who)
            conflicted.add(seat);
          } else if (status == 'pending') {
            final exp = (entry['expiryDate'] as Timestamp?)?.toDate();
            if (exp != null && exp.isAfter(now)) {
              // Active pending — only conflict if ANOTHER user owns it
              if (lockUserId != currentUserId) {
                conflicted.add(seat);
              }
              // else: current user's own lock → allow overwrite
            }
            // else: expired pending → treat as available
          }
        }
      }

      if (conflicted.isNotEmpty) {
        throw SeatAlreadyBookedException(conflicted);
      }

      // ── STEP 4: Check fleet seat count ──
      // Compute real availability from seat_locks (not stale
      // fleets.availableSeats). Count seats that are actively
      // locked: paid/used/validated = permanent, pending+not-expired
      // by another user = temporary lock.
      int activeLockCount = 0;
      for (final entry in seatEntries.values) {
        final e = Map<String, dynamic>.from(entry as Map);
        final st = e['status'] as String? ?? '';
        if (st == 'paid' || st == 'used' || st == 'validated') {
          activeLockCount++;
        } else if (st == 'pending') {
          final exp = (e['expiryDate'] as Timestamp?)?.toDate();
          if (exp != null && exp.isAfter(now)) {
            // Active pending by another user counts as locked
            final lockUserId = e['userId'] as String? ?? '';
            if (lockUserId != currentUserId) {
              activeLockCount++;
            }
          }
        }
      }
      final int availableSeats = (totalSeats - activeLockCount).clamp(0, totalSeats);

      if (availableSeats < booking.seatsBooked) {
        throw InsufficientSeatsException(
          requested: booking.seatsBooked,
          available: availableSeats,
        );
      }

      // ── STEP 5: Generate booking code & doc ref ──
      final code = _generateBookingCode();
      final newBookingRef = bookingsRef.doc();

      // ── STEP 6: Update seat_locks with new entries ──
      for (final seat in booking.selectedSeatLabels) {
        seatEntries[seat] = {
          'bookingId': newBookingRef.id,
          'userId': booking.userId,
          'status': 'pending',
          'expiryDate': Timestamp.fromDate(expiryDate),
        };
      }
      transaction.set(
        lockRef,
        {
          'seats': seatEntries,
          'fleetId': booking.fleetId,
          'departureDate': booking.departureDate,
        },
        SetOptions(merge: true),
      );

      // ── STEP 7: Create booking document ──
      final bookingWithMeta = booking.copyWith(
        id: newBookingRef.id,
        fleetName: fleetName,
        bookingCode: code,
        status: BookingStatus.pending,
        expiryDate: expiryDate,
      );
      transaction.set(newBookingRef, bookingWithMeta.toMap());

      // ── STEP 8: Sync fleet availableSeats (computed) ──
      transaction.update(fleetRef, {
        'availableSeats': (availableSeats - booking.seatsBooked).clamp(0, totalSeats),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return bookingWithMeta;
    });
  }

  // ─────────────────────────────────────────────────────
  //  CONFIRM PAYMENT — pending → paid (atomic)
  // ─────────────────────────────────────────────────────
  /// Marks a pending booking as paid, and updates seat_locks
  /// entries to 'paid' (removes expiryDate — permanent lock).
  static Future<void> confirmPayment(String bookingId) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((transaction) async {
      // ════════════════════════════════════════════════════
      // PHASE 1: ALL READS FIRST (Firestore requirement)
      // ════════════════════════════════════════════════════
      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) return;

      final data = bookingSnap.data()!;
      final currentStatus = data['status'] as String? ?? '';

      // Only confirm if booking is still pending
      if (currentStatus == 'pending') {
        final fleetId = data['fleetId'] as String? ?? '';
        final dateStr = data['departureDate'] as String? ?? '';
        final seatLabels =
            List<String>.from(data['selectedSeatLabels'] ?? []);

        // Read seat_locks (conditionally, but BEFORE any write)
        DocumentSnapshot? lockSnap;
        DocumentReference? lockRef;
        if (fleetId.isNotEmpty &&
            dateStr.isNotEmpty &&
            seatLabels.isNotEmpty) {
          lockRef =
              _db.collection('seat_locks').doc(_lockDocId(fleetId, dateStr));
          lockSnap = await transaction.get(lockRef);
        }

        // ════════════════════════════════════════════════════
        // PHASE 2: LOGIC & VALIDATION
        // ════════════════════════════════════════════════════
        Map<String, dynamic>? updatedSeats;
        if (lockSnap != null && lockSnap.exists && lockRef != null) {
          final seats = Map<String, dynamic>.from(
            (lockSnap.data() as Map<String, dynamic>?)?['seats'] ?? {},
          );
          for (final seat in seatLabels) {
            if (seats.containsKey(seat)) {
              final entry =
                  Map<String, dynamic>.from(seats[seat] as Map);
              if (entry['bookingId'] == bookingId) {
                seats[seat] = {
                  'bookingId': bookingId,
                  'status': 'paid',
                };
              }
            }
          }
          updatedSeats = seats;
        }

        // ════════════════════════════════════════════════════
        // PHASE 3: ALL WRITES LAST
        // ════════════════════════════════════════════════════
        transaction.update(bookingRef, {
          'status': BookingStatus.paid.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (updatedSeats != null && lockRef != null) {
          transaction.update(lockRef, {'seats': updatedSeats});
        }
      } else if (currentStatus == 'paid') {
        // Admin fee payment for reschedule — write marker
        transaction.update(bookingRef, {
          'adminFeePaidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ─────────────────────────────────────────────────────
  //  CANCEL BOOKING — Atomic cancel + seat release
  // ─────────────────────────────────────────────────────
  /// Cancels a pending booking, removes from seat_locks,
  /// and restores fleet availableSeats. All atomic.
  static Future<void> cancelBooking(String bookingId) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((transaction) async {
      // ════════════════════════════════════════════════════
      // PHASE 1: ALL READS FIRST (Firestore requirement)
      // ════════════════════════════════════════════════════
      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) return;

      final data = bookingSnap.data()!;
      final status = data['status'] as String? ?? '';

      // Allow cancel for pending AND paid bookings
      if (status != 'pending' && status != 'paid') return;

      final fleetId = data['fleetId'] as String? ?? '';
      final dateStr = data['departureDate'] as String? ?? '';
      final seatLabels =
          List<String>.from(data['selectedSeatLabels'] ?? []);
      final seatsBooked =
          (data['seatsBooked'] as num?)?.toInt() ?? seatLabels.length;
      final totalPrice =
          (data['totalPrice'] as num?)?.toInt() ?? 0;

      // Read seat_locks BEFORE any write
      DocumentSnapshot? lockSnap;
      DocumentReference? lockRef;
      if (fleetId.isNotEmpty && dateStr.isNotEmpty) {
        lockRef =
            _db.collection('seat_locks').doc(_lockDocId(fleetId, dateStr));
        lockSnap = await transaction.get(lockRef);
      }

      // Read fleet doc BEFORE any write
      DocumentSnapshot? fleetSnap;
      DocumentReference? fleetRef;
      if (fleetId.isNotEmpty && seatsBooked > 0) {
        fleetRef = _db.collection('fleets').doc(fleetId);
        fleetSnap = await transaction.get(fleetRef);
      }

      // ════════════════════════════════════════════════════
      // PHASE 2: LOGIC & VALIDATION
      // ════════════════════════════════════════════════════
      Map<String, dynamic>? updatedSeats;
      if (lockSnap != null && lockSnap.exists && lockRef != null) {
        final seats = Map<String, dynamic>.from(
          (lockSnap.data() as Map<String, dynamic>?)?['seats'] ?? {},
        );
        for (final seat in seatLabels) {
          if (seats.containsKey(seat)) {
            final entry =
                Map<String, dynamic>.from(seats[seat] as Map);
            if (entry['bookingId'] == bookingId) {
              seats.remove(seat);
            }
          }
        }
        updatedSeats = seats;
      }

      // Compute real availability from seat_locks after removal
      int? newAvailableSeats;
      if (fleetSnap != null && fleetSnap.exists && fleetRef != null) {
        final fleetData = fleetSnap.data() as Map<String, dynamic>;
        final total =
            (fleetData['totalSeats'] as num?)?.toInt() ?? 0;
        // Count remaining active locks
        final remainingSeats = updatedSeats ?? <String, dynamic>{};
        int activeLocks = 0;
        for (final entry in remainingSeats.values) {
          final e = Map<String, dynamic>.from(entry as Map);
          final st = e['status'] as String? ?? '';
          if (st == 'paid' || st == 'used' || st == 'validated' || st == 'pending') {
            activeLocks++;
          }
        }
        newAvailableSeats = (total - activeLocks).clamp(0, total);
      }

      // ════════════════════════════════════════════════════
      // PHASE 3: ALL WRITES LAST
      // ════════════════════════════════════════════════════
      final updates = <String, dynamic>{
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Mark refund if paid (80% refund, 20% penalty)
      if (status == 'paid') {
        final penaltyAmount = (totalPrice * 0.2).round();
        final refundAmount = totalPrice - penaltyAmount;
        updates['refundAmount'] = refundAmount;
        updates['refundPenalty'] = penaltyAmount;
        updates['refundStatus'] = 'pending';
        updates['refundProcessedAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(bookingRef, updates);

      if (updatedSeats != null && lockRef != null) {
        transaction.update(lockRef, {'seats': updatedSeats});
      }

      if (newAvailableSeats != null && fleetRef != null) {
        transaction.update(fleetRef, {
          'availableSeats': newAvailableSeats,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Reschedule booking to a new date. Charges 10% admin fee.
  static Future<int> rescheduleBooking(
    String bookingId,
    String newDepartureDate,
    String newDepartureTime,
  ) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);
    int adminFee = 0;

    await _db.runTransaction((transaction) async {
      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) return;

      final data = bookingSnap.data()!;
      final status = data['status'] as String? ?? '';

      // Only reschedule pending or paid bookings
      if (status != 'pending' && status != 'paid') return;

      final fleetId = data['fleetId'] as String? ?? '';
      final oldDateStr = data['departureDate'] as String? ?? '';
      final seatLabels =
          List<String>.from(data['selectedSeatLabels'] ?? []);

      if (fleetId.isEmpty || oldDateStr.isEmpty) return;

      final oldLockRef =
          _db.collection('seat_locks').doc(_lockDocId(fleetId, oldDateStr));
      final newLockRef =
          _db.collection('seat_locks').doc(_lockDocId(fleetId, newDepartureDate));

      // Read both lock docs
      final oldLockSnap = await transaction.get(oldLockRef);
      final newLockSnap = await transaction.get(newLockRef);

      // Read fleet doc
      final fleetRef = _db.collection('fleets').doc(fleetId);
      final fleetSnap = await transaction.get(fleetRef);
      if (!fleetSnap.exists) return;
      final fleetData = fleetSnap.data() as Map<String, dynamic>;
      final totalSeats = (fleetData['totalSeats'] as num?)?.toInt() ?? 0;

      // Remove seats from old lock
      Map<String, dynamic> oldSeats = {};
      if (oldLockSnap.exists) {
        oldSeats = Map<String, dynamic>.from(
          (oldLockSnap.data() as Map?)?['seats'] ?? {},
        );
      }
      for (final seat in seatLabels) {
        if (oldSeats.containsKey(seat)) {
          final entry = Map<String, dynamic>.from(oldSeats[seat] as Map);
          if (entry['bookingId'] == bookingId) {
            oldSeats.remove(seat);
          }
        }
      }

      // Check availability on new date
      Map<String, dynamic> newSeats = {};
      if (newLockSnap.exists) {
        newSeats = Map<String, dynamic>.from(
          (newLockSnap.data() as Map?)?['seats'] ?? {},
        );
      }

      int activeNewLocks = 0;
      for (final entry in newSeats.values) {
        final e = Map<String, dynamic>.from(entry as Map);
        final st = e['status'] as String? ?? '';
        if (st == 'paid' || st == 'used' || st == 'validated' || st == 'pending') {
          activeNewLocks++;
        }
      }
      final availableOnNew = totalSeats - activeNewLocks;
      if (availableOnNew < seatLabels.length) {
        throw Exception(
          'Hanya $availableOnNew kursi tersedia pada tanggal $newDepartureDate',
        );
      }

      // Add seats to new lock
      for (final seat in seatLabels) {
        newSeats[seat] = {
          'bookingId': bookingId,
          'status': status,
          'expiryDate': data['expiryDate'],
        };
      }

      // Compute new availableSeats for new date
      activeNewLocks = 0;
      if (newLockSnap.exists) {
        for (final entry in newSeats.values) {
          final e = Map<String, dynamic>.from(entry as Map);
          final st = e['status'] as String? ?? '';
          if (st == 'paid' || st == 'used' || st == 'validated' || st == 'pending') {
            activeNewLocks++;
          }
        }
      }
      final newAvailableNew = (totalSeats - activeNewLocks).clamp(0, totalSeats);

      // Biaya admin 10% (tidak mengubah totalPrice untuk booking paid)
      final currentTotalPrice = (data['totalPrice'] as num?)?.toInt() ?? 0;
      adminFee = (currentTotalPrice * 0.1).round();

      final updates = <String, dynamic>{
        'departureDate': newDepartureDate,
        'departureTime': newDepartureTime,
        'adminFee': FieldValue.increment(adminFee),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // Untuk pending: tambahkan admin fee ke totalPrice (belum bayar)
      // Untuk paid: totalPrice tetap, admin fee dibayar terpisah via Midtrans
      if (status == 'pending') {
        updates['totalPrice'] = currentTotalPrice + adminFee;
      }

      // ALL WRITES
      transaction.update(bookingRef, updates);

      transaction.update(oldLockRef, {'seats': oldSeats});
      transaction.set(newLockRef, {'seats': newSeats}, SetOptions(merge: true));

      transaction.update(fleetRef, {
        'availableSeats': newAvailableNew,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return adminFee;
  }

  // ─────────────────────────────────────────────────────
  //  CLEANUP EXPIRED — Client-side GC for ghost seats
  // ─────────────────────────────────────────────────────
  /// Finds all expired pending bookings for a fleet+date,
  /// cancels them, removes from seat_locks, restores seats.
  ///
  /// Called on seat selection page init as a "client GC"
  /// since there is no Cloud Function to do this server-side.
  static Future<int> cleanupExpiredBookings({
    required String fleetId,
    required String departureDate,
  }) async {
    int cleaned = 0;
    final now = Timestamp.fromDate(DateTime.now());

    try {
      // Query expired pending bookings for this fleet+date
      final expiredSnap = await _db
          .collection('bookings')
          .where('fleetId', isEqualTo: fleetId)
          .where('departureDate', isEqualTo: departureDate)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in expiredSnap.docs) {
        final data = doc.data();
        final expiryTs = data['expiryDate'] as Timestamp?;

        // Skip if no expiryDate or not yet expired
        if (expiryTs == null) continue;
        if (expiryTs.compareTo(now) > 0) continue;

        // This booking is expired → cancel it
        try {
          await cancelBooking(doc.id);
          cleaned++;
        } catch (_) {
          // Silent — best-effort cleanup
        }
      }
    } catch (_) {
      // Silent — cleanup is best-effort
    }

    return cleaned;
  }

  // ─────────────────────────────────────────────────────
  //  BOOK SEAT (Legacy — simple seat deduction only)
  // ─────────────────────────────────────────────────────
  static Future<bool> bookSeat({
    required String fleetId,
    required int seatsToBook,
  }) async {
    final fleetRef = _db.collection('fleets').doc(fleetId);

    try {
      return await _db.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(fleetRef);
        if (!snapshot.exists) {
          throw Exception('Armada tidak ditemukan (ID: $fleetId)');
        }
        final data = snapshot.data()!;
        final int totalSeats =
            (data['totalSeats'] as num?)?.toInt() ?? 0;

        // Query active bookings to compute real availability
        // (can't do Firestore query in transaction, so use
        //  totalSeats from fleet doc as upper bound — the
        //  seat_locks-based check in createBooking() is the
        //  real guard. This legacy method just does a simple
        //  deduction on the fleet counter.)
        final int currentAvailable =
            (data['availableSeats'] as num?)?.toInt() ?? totalSeats;
        if (currentAvailable < seatsToBook) return false;
        transaction.update(fleetRef, {
          'availableSeats': (currentAvailable - seatsToBook).clamp(0, totalSeats),
        });
        return true;
      });
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────
  //  RELEASE SEAT (Legacy)
  // ─────────────────────────────────────────────────────
  static Future<void> releaseSeat({
    required String fleetId,
    required int seatsToRelease,
  }) async {
    final fleetRef = _db.collection('fleets').doc(fleetId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(fleetRef);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final int available =
          (data['availableSeats'] as num?)?.toInt() ?? totalSeatsFrom(data);
      final int total = (data['totalSeats'] as num?)?.toInt() ?? 0;
      final newAvailable = (available + seatsToRelease).clamp(0, total);
      transaction.update(fleetRef, {'availableSeats': newAvailable});
    });
  }

  /// Helper to extract totalSeats from fleet data.
  static int totalSeatsFrom(Map<String, dynamic> data) =>
      (data['totalSeats'] as num?)?.toInt() ?? 0;

  // ─────────────────────────────────────────────────────
  //  STREAMS — Real-time queries
  // ─────────────────────────────────────────────────────

  /// Stream of all bookings for a specific user.
  static Stream<List<BookingModel>> userBookingsStream(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BookingModel.fromFirestore(d)).toList());
  }

  /// Stream of bookings for a specific fleet (for Admin/Sopir manifest).
  static Stream<List<BookingModel>> fleetBookingsStream(String fleetId) {
    return _db
        .collection('bookings')
        .where('fleetId', isEqualTo: fleetId)
        .where('status', whereIn: ['paid', 'used', 'completed'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BookingModel.fromFirestore(d)).toList());
  }

  /// Stream of ALL bookings for a fleet (all statuses).
  static Stream<List<BookingModel>> allFleetBookingsStream(String fleetId) {
    return _db
        .collection('bookings')
        .where('fleetId', isEqualTo: fleetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BookingModel.fromFirestore(d)).toList());
  }

  /// Stream of a single booking document (for e-ticket / payment).
  static Stream<BookingModel?> bookingStream(String bookingId) {
    return _db
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return BookingModel.fromFirestore(snap);
    });
  }

  /// One-time read of a booking document.

  // ─────────────────────────────────────────────────────
  //  HELPER — Generate human-readable booking code
  // ─────────────────────────────────────────────────────
  static String _generateBookingCode() {
    final rng = Random();
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const digits = '0123456789';
    final buf = StringBuffer('TRV-');
    for (var i = 0; i < 3; i++) {
      buf.write(letters[rng.nextInt(letters.length)]);
    }
    for (var i = 0; i < 3; i++) {
      buf.write(digits[rng.nextInt(digits.length)]);
    }
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────
//  CUSTOM EXCEPTIONS
// ─────────────────────────────────────────────────────
class InsufficientSeatsException implements Exception {
  final int requested;
  final int available;

  const InsufficientSeatsException({
    required this.requested,
    required this.available,
  });

  @override
  String toString() =>
      'Kursi tidak cukup: diminta $requested, tersedia $available';
}

class FleetNotFoundException implements Exception {
  final String fleetId;
  const FleetNotFoundException(this.fleetId);

  @override
  String toString() => 'Armada tidak ditemukan (ID: $fleetId)';
}

class SeatAlreadyBookedException implements Exception {
  final List<String> conflictedSeats;
  const SeatAlreadyBookedException(this.conflictedSeats);

  @override
  String toString() =>
      'Kursi ${conflictedSeats.join(", ")} sudah dipesan orang lain';
}

