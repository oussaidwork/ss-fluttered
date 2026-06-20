import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/expense.dart';
import '../../domain/enums/expense_category.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl._();
  static final _instance = ExpenseRepositoryImpl._();
  factory ExpenseRepositoryImpl() => _instance;

  @override
  Stream<List<Expense>> watchExpenses({ExpenseCategory? category}) {
    Query query = firestore
        .collection(FirestorePaths.expenses)
        .orderBy('timestamp', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.value);
    }

    return query.snapshots().map(
          (snap) =>
              snap.docs.map((d) => Expense.fromMap(d.data() as Map<String, dynamic>)).toList(),
        );
  }

  @override
  Future<void> createExpense(Expense expense) async {
    await firestore
        .collection(FirestorePaths.expenses)
        .doc(expense.id)
        .set(expense.toMap());
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await firestore
        .collection(FirestorePaths.expenses)
        .doc(expense.id)
        .update(expense.toMap());
  }

  @override
  Future<void> deleteExpense(String id) async {
    await firestore.collection(FirestorePaths.expenses).doc(id).delete();
  }
}

final expenseRepository = ExpenseRepositoryImpl();
