import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipment_model.dart';
import 'firestore_dijkstra_service.dart';

class ShipmentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<ShipmentModel> create(ShipmentModel shipment) async {
    final ref = _db.collection('shipments').doc();
    final now = DateTime.now();
    final data = shipment.copyWith(id: ref.id, createdAt: now).toMap();
    await ref.set(data);
    return ShipmentModel.fromFirestore(await ref.get());
  }

  static Future<void> updateStatus(
    String shipmentId,
    String newStatus, {
    String? driverId,
    String? driverName,
    String? notes,
  }) async {
    final ref = _db.collection('shipments').doc(shipmentId);
    final now = DateTime.now();
    final updates = <String, dynamic>{
      'status': newStatus,
      'updatedAt': Timestamp.fromDate(now),
    };
    if (driverId != null) updates['driverId'] = driverId;
    if (driverName != null) updates['driverName'] = driverName;
    if (notes != null) updates['notes'] = notes;
    if (newStatus == 'picked_up') updates['pickedUpAt'] = Timestamp.fromDate(now);
    if (newStatus == 'delivered') updates['deliveredAt'] = Timestamp.fromDate(now);
    await ref.update(updates);
  }

  static Stream<List<ShipmentModel>> userShipmentsStream(String userId) {
    return _db
        .collection('shipments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => ShipmentModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Stream<List<ShipmentModel>> driverShipmentsStream(String driverId) {
    return _db
        .collection('shipments')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => ShipmentModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Stream<List<ShipmentModel>> fleetShipmentsStream(String fleetId) {
    return _db
        .collection('shipments')
        .where('fleetId', isEqualTo: fleetId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => ShipmentModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Stream<ShipmentModel> shipmentStream(String shipmentId) {
    return _db
        .collection('shipments')
        .doc(shipmentId)
        .snapshots()
        .map((doc) => ShipmentModel.fromFirestore(doc));
  }

  static Future<void> updatePaymentStatus(
    String shipmentId, {
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    final ref = _db.collection('shipments').doc(shipmentId);
    await ref.update({
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Stream<List<ShipmentModel>> pendingShipmentsStream() {
    return _db
        .collection('shipments')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => ShipmentModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream of pending shipments filtered by fleet IDs (for driver).
  static Stream<List<ShipmentModel>> pendingShipmentsForFleetsStream(List<String> fleetIds) {
    if (fleetIds.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('shipments')
        .where('fleetId', whereIn: fleetIds)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ShipmentModel.fromFirestore(d))
            .where((s) => s.status == 'pending')
            .toList());
  }

  /// Find fleets whose route covers the given origin → destination.
  static Future<List<Map<String, dynamic>>> getMatchingFleets(String origin, String destination) async {
    final fleets = await FirebaseFirestore.instance.collection('fleets').get();
    final matching = <Map<String, dynamic>>[];
    for (final doc in fleets.docs) {
      final data = doc.data();
      final fOrigin = data['origin'] as String? ?? '';
      final fDest = data['destination'] as String? ?? '';
      if (fOrigin.isEmpty || fDest.isEmpty) continue;
      final covered = await FirestoreDijkstraService.instance.isRouteCovered(fOrigin, fDest, origin, destination);
      if (covered) {
        matching.add({'id': doc.id, ...data});
      }
    }
    return matching;
  }
}
