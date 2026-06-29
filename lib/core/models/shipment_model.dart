import 'package:cloud_firestore/cloud_firestore.dart';

class ShipmentModel {
  final String? id;
  final String userId;
  final String userName;
  final String userPhone;
  final String? driverId;
  final String? driverName;
  final String origin;
  final String destination;
  final String description;
  final double weight;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? notes;
  final String? bookingId;
  final String? fleetId;
  final String? fleetName;

  // New fields
  final String? senderName;
  final String? senderPhone;
  final String? receiverName;
  final String? receiverPhone;
  final String? receiverAddress;
  final String? packageSize; // kecil | sedang | besar
  final int? packagePrice;
  final String? paymentMethod; // cod | midtrans
  final String? paymentStatus; // unpaid | paid
  final String? packageCode; // Unique receipt number assigned on admin approval

  const ShipmentModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.driverId,
    this.driverName,
    required this.origin,
    required this.destination,
    required this.description,
    this.weight = 0,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.notes,
    this.bookingId,
    this.fleetId,
    this.fleetName,
    this.senderName,
    this.senderPhone,
    this.receiverName,
    this.receiverPhone,
    this.receiverAddress,
    this.packageSize,
    this.packagePrice,
    this.paymentMethod,
    this.paymentStatus,
    this.packageCode,
  });

  factory ShipmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ShipmentModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      userPhone: d['userPhone'] as String? ?? '',
      driverId: d['driverId'] as String?,
      driverName: d['driverName'] as String?,
      origin: d['origin'] as String? ?? '',
      destination: d['destination'] as String? ?? '',
      description: d['description'] as String? ?? '',
      weight: (d['weight'] as num?)?.toDouble() ?? 0,
      status: d['status'] as String? ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      pickedUpAt: (d['pickedUpAt'] as Timestamp?)?.toDate(),
      deliveredAt: (d['deliveredAt'] as Timestamp?)?.toDate(),
      notes: d['notes'] as String?,
      bookingId: d['bookingId'] as String?,
      fleetId: d['fleetId'] as String?,
      fleetName: d['fleetName'] as String?,
      senderName: d['senderName'] as String?,
      senderPhone: d['senderPhone'] as String?,
      receiverName: d['receiverName'] as String?,
      receiverPhone: d['receiverPhone'] as String?,
      receiverAddress: d['receiverAddress'] as String?,
      packageSize: d['packageSize'] as String?,
      packagePrice: (d['packagePrice'] as num?)?.toInt(),
      paymentMethod: d['paymentMethod'] as String?,
      paymentStatus: d['paymentStatus'] as String?,
      packageCode: d['packageCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'userPhone': userPhone,
    'driverId': driverId,
    'driverName': driverName,
    'origin': origin,
    'destination': destination,
    'description': description,
    'weight': weight,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
    'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    'notes': notes,
    'bookingId': bookingId,
    'fleetId': fleetId,
    'fleetName': fleetName,
    'senderName': senderName,
    'senderPhone': senderPhone,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'receiverAddress': receiverAddress,
    'packageSize': packageSize,
    'packagePrice': packagePrice,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'packageCode': packageCode,
  };

  ShipmentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? driverId,
    String? driverName,
    String? origin,
    String? destination,
    String? description,
    double? weight,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? notes,
    String? bookingId,
    String? fleetId,
    String? fleetName,
    String? senderName,
    String? senderPhone,
    String? receiverName,
    String? receiverPhone,
    String? receiverAddress,
    String? packageSize,
    int? packagePrice,
    String? paymentMethod,
    String? paymentStatus,
    String? packageCode,
  }) =>
      ShipmentModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userPhone: userPhone ?? this.userPhone,
        driverId: driverId ?? this.driverId,
        driverName: driverName ?? this.driverName,
        origin: origin ?? this.origin,
        destination: destination ?? this.destination,
        description: description ?? this.description,
        weight: weight ?? this.weight,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        pickedUpAt: pickedUpAt ?? this.pickedUpAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        notes: notes ?? this.notes,
        bookingId: bookingId ?? this.bookingId,
        fleetId: fleetId ?? this.fleetId,
        fleetName: fleetName ?? this.fleetName,
        senderName: senderName ?? this.senderName,
        senderPhone: senderPhone ?? this.senderPhone,
        receiverName: receiverName ?? this.receiverName,
        receiverPhone: receiverPhone ?? this.receiverPhone,
        receiverAddress: receiverAddress ?? this.receiverAddress,
        packageSize: packageSize ?? this.packageSize,
        packagePrice: packagePrice ?? this.packagePrice,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        packageCode: packageCode ?? this.packageCode,
      );
}
