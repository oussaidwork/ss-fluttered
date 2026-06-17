import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/expense.dart';

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  return firestore.collection('expenses').orderBy('timestamp', descending: true).snapshots().map(
    (snap) => snap.docs.map((d) => Expense.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});
