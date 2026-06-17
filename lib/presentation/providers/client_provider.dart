import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/client.dart';

final clientsProvider = StreamProvider<List<Client>>((ref) {
  return firestore.collection('clients').where('isDeleted', isEqualTo: false).orderBy('name').snapshots().map(
    (snap) => snap.docs.map((d) => Client.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});
