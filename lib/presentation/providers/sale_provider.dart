import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/sale.dart';

final todaySalesProvider = StreamProvider<List<Sale>>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return firestore.collection('sales')
    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
    .where('isDeleted', isEqualTo: false)
    .orderBy('timestamp', descending: true)
    .snapshots()
    .map((snap) => snap.docs.map((d) => Sale.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList());
});

final allSalesProvider = StreamProvider<List<Sale>>((ref) {
  return firestore.collection('sales')
    .where('isDeleted', isEqualTo: false)
    .orderBy('timestamp', descending: true)
    .snapshots()
    .map((snap) => snap.docs.map((d) => Sale.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList());
});
