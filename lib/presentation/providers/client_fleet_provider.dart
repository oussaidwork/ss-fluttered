import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/client_fleet.dart';

final clientFleetByClientProvider = StreamProvider.family<List<ClientFleet>, String>((ref, clientId) {
  return firestore.collection('client_fleet').where('clientId', isEqualTo: clientId).where('isDeleted', isEqualTo: false).snapshots().map(
    (snap) => snap.docs.map((d) => ClientFleet.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

final allClientFleetProvider = StreamProvider<List<ClientFleet>>((ref) {
  return firestore.collection('client_fleet').where('isDeleted', isEqualTo: false).snapshots().map(
    (snap) => snap.docs.map((d) => ClientFleet.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});
