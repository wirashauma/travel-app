import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════
//  DATA DICTIONARY — Firestore Collections & Field Mapping
// ═══════════════════════════════════════════════════════════
//
//  Collection: users/{uid}
//  ┌─────────────────┬──────────┬─────────────────────────┐
//  │ Field           │ Type     │ Description             │
//  ├─────────────────┼──────────┼─────────────────────────┤
//  │ uid             │ String   │ Firebase Auth UID       │
//  │ email           │ String   │ User email              │
//  │ namaLengkap     │ String   │ Full name               │
//  │ nomorHp         │ String   │ Phone number            │
//  │ role            │ String   │ 'user'|'admin'|'super_admin' │
//  │ isSuspended     │ bool     │ Account suspended flag  │
//  │ assignedFleetId │ String?  │ Fleet ID for admin/sopir│
//  │ photoUrl        │ String?  │ Profile photo URL       │
//  │ createdAt       │ Timestamp│ Registration date       │
//  └─────────────────┴──────────┴─────────────────────────┘
//
//  Collection: fleets/{fleetId}
//  ┌─────────────────┬──────────┬─────────────────────────┐
//  │ Field           │ Type     │ Description             │
//  ├─────────────────┼──────────┼─────────────────────────┤
//  │ name            │ String   │ Fleet/armada name       │
//  │ imageUrl        │ String   │ Vehicle photo URL       │
//  │ totalSeats      │ int      │ Total seat capacity     │
//  │ availableSeats  │ int      │ Remaining seats         │
//  │ description     │ String   │ Fleet description       │
//  │ createdAt       │ Timestamp│ Created date            │
//  │ updatedAt       │ Timestamp│ Last modified date      │
//  └─────────────────┴──────────┴─────────────────────────┘
//
//  Collection: routes/{routeId}
//  ┌─────────────────┬──────────┬─────────────────────────┐
//  │ Field           │ Type     │ Description             │
//  ├─────────────────┼──────────┼─────────────────────────┤
//  │ from            │ String   │ Origin city name        │
//  │ to              │ String   │ Destination city name   │
//  │ distance        │ int      │ Distance in km          │
//  │ price           │ int      │ Price in Rp             │
//  │ duration        │ String   │ e.g. "5 jam 30 menit"  │
//  │ createdAt       │ Timestamp│ Created date            │
//  └─────────────────┴──────────┴─────────────────────────┘
//
//  Collection: bookings/{bookingId}
//  ┌─────────────────┬──────────┬─────────────────────────┐
//  │ Field           │ Type     │ Description             │
//  ├─────────────────┼──────────┼─────────────────────────┤
//  │ userId          │ String   │ Booker's UID            │
//  │ userName        │ String   │ Booker's full name      │
//  │ fleetId         │ String   │ Reference to fleet doc  │
//  │ fleetName       │ String   │ Denormalised fleet name │
//  │ routeId         │ String?  │ Reference to route doc  │
//  │ origin          │ String   │ Origin city             │
//  │ destination     │ String   │ Destination city        │
//  │ departureDate   │ String   │ "dd MMM yyyy"           │
//  │ seatNumbers     │ List<int>│ Selected seat numbers   │
//  │ seatsBooked     │ int      │ Number of seats booked  │
//  │ totalPrice      │ int      │ Total price in Rp       │
//  │ status          │ String   │ 'pending'|'paid'|'completed'|'cancelled' │
//  │ bookingCode     │ String   │ Human-readable code     │
//  │ createdAt       │ Timestamp│ Timestamp of booking    │
//  │ updatedAt       │ Timestamp│ Last status change      │
//  └─────────────────┴──────────┴─────────────────────────┘
//
// ═══════════════════════════════════════════════════════════

/// Booking status enum with Firestore string mapping.
enum BookingStatus {
  pending,
  paid,
  validated, // ticket pre-validated before departure day
  used,       // ticket scanned on departure day
  completed,  // legacy — kept for backward compat
  cancelled;

  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.paid:
        return 'paid';
      case BookingStatus.validated:
        return 'validated';
      case BookingStatus.used:
        return 'used';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Returns true when the ticket has been scanned (validated, used, OR legacy completed).
  bool get isValidated => this == validated || this == used || this == completed;

  static BookingStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'paid':
        return BookingStatus.paid;
      case 'validated':
        return BookingStatus.validated;
      case 'used':
        return BookingStatus.used;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }
}

/// Immutable model for a booking document in Firestore.
class BookingModel {
  final String? id;
  final String userId;
  final String userName;
  final String fleetId;
  final String fleetName;
  final String? routeId;
  final String origin;
  final String destination;
  final String departureDate;
  final List<int> seatNumbers;
  final List<String> selectedSeatLabels; // e.g. ['1A', '2B']
  final int seatsBooked;
  final int totalPrice;
  final BookingStatus status;
  final String bookingCode;
  final DateTime? expiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? refundAmount;
  final int? refundPenalty;
  final String? refundStatus;

  const BookingModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.fleetId,
    required this.fleetName,
    this.routeId,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.seatNumbers,
    this.selectedSeatLabels = const [],
    required this.seatsBooked,
    required this.totalPrice,
    this.status = BookingStatus.paid,
    required this.bookingCode,
    this.expiryDate,
    this.createdAt,
    this.updatedAt,
    this.refundAmount,
    this.refundPenalty,
    this.refundStatus,
  });

  /// Create from Firestore document snapshot.
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      fleetId: d['fleetId'] as String? ?? '',
      fleetName: d['fleetName'] as String? ?? '',
      routeId: d['routeId'] as String?,
      origin: d['origin'] as String? ?? '',
      destination: d['destination'] as String? ?? '',
      departureDate: d['departureDate'] as String? ?? '',
      seatNumbers: (d['seatNumbers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      selectedSeatLabels: (d['selectedSeatLabels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      seatsBooked: (d['seatsBooked'] as num?)?.toInt() ?? 1,
      totalPrice: (d['totalPrice'] as num?)?.toInt() ?? 0,
      status: BookingStatus.fromString(d['status'] as String? ?? 'pending'),
      bookingCode: d['bookingCode'] as String? ?? '',
      expiryDate: (d['expiryDate'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      refundAmount: (d['refundAmount'] as num?)?.toInt(),
      refundPenalty: (d['refundPenalty'] as num?)?.toInt(),
      refundStatus: d['refundStatus'] as String?,
    );
  }

  /// Convert to Firestore map for writing.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'bookingId': id,
      'userId': userId,
      'userName': userName,
      'fleetId': fleetId,
      'fleetName': fleetName,
      if (routeId != null) 'routeId': routeId,
      'origin': origin,
      'destination': destination,
      'departureDate': departureDate,
      'seatNumbers': seatNumbers,
      'selectedSeatLabels': selectedSeatLabels,
      'seatsBooked': seatsBooked,
      'totalPrice': totalPrice,
      'status': status.value,
      'bookingCode': bookingCode,
      if (expiryDate != null)
        'expiryDate': Timestamp.fromDate(expiryDate!),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (refundAmount != null) 'refundAmount': refundAmount,
      if (refundPenalty != null) 'refundPenalty': refundPenalty,
      if (refundStatus != null) 'refundStatus': refundStatus,
    };
  }

  /// Create a copy with updated fields.
  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? fleetId,
    String? fleetName,
    String? routeId,
    String? origin,
    String? destination,
    String? departureDate,
    List<int>? seatNumbers,
    List<String>? selectedSeatLabels,
    int? seatsBooked,
    int? totalPrice,
    BookingStatus? status,
    String? bookingCode,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? refundAmount,
    int? refundPenalty,
    String? refundStatus,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      fleetId: fleetId ?? this.fleetId,
      fleetName: fleetName ?? this.fleetName,
      routeId: routeId ?? this.routeId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      seatNumbers: seatNumbers ?? this.seatNumbers,
      selectedSeatLabels: selectedSeatLabels ?? this.selectedSeatLabels,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      bookingCode: bookingCode ?? this.bookingCode,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      refundAmount: refundAmount ?? this.refundAmount,
      refundPenalty: refundPenalty ?? this.refundPenalty,
      refundStatus: refundStatus ?? this.refundStatus,
    );
  }
}
