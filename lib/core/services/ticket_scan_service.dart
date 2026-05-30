import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════
//  TICKET SCAN SERVICE — Admin/Sopir → User & Super Admin
//
//  SINKRONISASI 2: Scan Tiket Real-Time
//  When the driver scans a ticket QR Code:
//   1. Lookup booking by bookingCode
//   2. Validate status == 'paid' (not already used)
//   3. Update status → 'completed'
//
//  DAMPAK REAL-TIME:
//  - User's ETicketPage StreamBuilder sees status change to 'completed'
//    → QR Code becomes "TIKET TELAH DIGUNAKAN" stamp
//  - Super Admin's TransactionReportPage StreamBuilder sees label
//    change from green (Paid) to blue (Completed) instantly
//  - Admin's TripManifestPage passenger list updates validation mark
// ═══════════════════════════════════════════════════════════
class TicketScanService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────
  //  SCAN TICKET — Update status from 'paid' → 'completed'
  // ─────────────────────────────────────────────────────
  /// Scans a ticket by its [bookingCode] (from QR data) or [bookingId].
  ///
  /// Returns [ScanResult] with success status and booking details.
  static Future<ScanResult> scanTicketAndUpdateStatus({
    String? bookingCode,
    String? bookingId,
  }) async {
    assert(
      bookingCode != null || bookingId != null,
      'Either bookingCode or bookingId must be provided',
    );

    try {
      // ── Look up booking ──
      DocumentSnapshot? bookingSnap;

      if (bookingId != null && bookingId.isNotEmpty) {
        // Direct lookup by document ID
        bookingSnap = await _db.collection('bookings').doc(bookingId).get();
      } else if (bookingCode != null && bookingCode.isNotEmpty) {
        // Query by bookingCode field
        final query = await _db
            .collection('bookings')
            .where('bookingCode', isEqualTo: bookingCode)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          bookingSnap = query.docs.first;
        }
      }

      // ── Booking not found ──
      if (bookingSnap == null || !bookingSnap.exists) {
        return ScanResult(
          success: false,
          message: 'Tiket tidak ditemukan.',
          errorCode: ScanError.notFound,
        );
      }

      final data = bookingSnap.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String? ?? '';

      // ── Already used ──
      if (currentStatus == 'completed') {
        return ScanResult(
          success: false,
          message: 'Tiket sudah digunakan sebelumnya.',
          errorCode: ScanError.alreadyUsed,
          passengerName: data['userName'] as String?,
          seatNumbers: (data['seatNumbers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(),
        );
      }

      // ── Cancelled booking ──
      if (currentStatus == 'cancelled') {
        return ScanResult(
          success: false,
          message: 'Tiket telah dibatalkan.',
          errorCode: ScanError.cancelled,
        );
      }

      // ── Not yet paid ──
      if (currentStatus == 'pending') {
        return ScanResult(
          success: false,
          message: 'Tiket belum dibayar.',
          errorCode: ScanError.unpaid,
        );
      }

      // ── Valid: Update status to 'completed' ──
      await _db.collection('bookings').doc(bookingSnap.id).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ScanResult(
        success: true,
        message: 'Tiket berhasil divalidasi!',
        bookingId: bookingSnap.id,
        bookingCode: data['bookingCode'] as String?,
        passengerName: data['userName'] as String?,
        seatNumbers: (data['seatNumbers'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        origin: data['origin'] as String?,
        destination: data['destination'] as String?,
      );
    } catch (e) {
      return ScanResult(
        success: false,
        message: 'Gagal memvalidasi tiket: $e',
        errorCode: ScanError.unknown,
      );
    }
  }

  // ─────────────────────────────────────────────────────
  //  BATCH VALIDATE — Mark multiple bookings as completed
  // ─────────────────────────────────────────────────────
  /// Validates all 'paid' bookings for a specific fleet.
  /// Useful for "validate all remaining" action.
  static Future<int> validateAllForFleet(String fleetId) async {
    final query = await _db
        .collection('bookings')
        .where('fleetId', isEqualTo: fleetId)
        .where('status', isEqualTo: 'paid')
        .get();

    if (query.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    return query.docs.length;
  }
}

// ─────────────────────────────────────────────────────
//  SCAN RESULT
// ─────────────────────────────────────────────────────
enum ScanError { notFound, alreadyUsed, cancelled, unpaid, unknown }

class ScanResult {
  final bool success;
  final String message;
  final ScanError? errorCode;
  final String? bookingId;
  final String? bookingCode;
  final String? passengerName;
  final List<int>? seatNumbers;
  final String? origin;
  final String? destination;

  const ScanResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.bookingId,
    this.bookingCode,
    this.passengerName,
    this.seatNumbers,
    this.origin,
    this.destination,
  });

  String get seatLabel =>
      seatNumbers?.map((s) => 'No. $s').join(', ') ?? '-';
}
