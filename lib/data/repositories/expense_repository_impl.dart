import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/expense.dart';
import '../../domain/enums/expense_category.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final DatabaseDataSource _ds;

  ExpenseRepositoryImpl(this._ds);

  @override
  Stream<List<Expense>> watchExpenses({ExpenseCategory? category}) {
    if (category != null) {
      return _ds.streamQueryMulti(
        FirestorePaths.expenses,
        filters: [QueryFilter(field: 'category', value: category.value)],
        orderByField: 'timestamp',
        orderByDescending: true,
      ).map(
        (snap) => snap.docs
            .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>))
            .toList(),
      );
    }

    return _ds.streamQuery(
      FirestorePaths.expenses,
      orderByField: 'timestamp',
      orderByDescending: true,
    ).map(
      (snap) => snap.docs
          .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<void> createExpense(Expense expense) async {
    await _ds.setDoc(FirestorePaths.expenses, expense.id, expense.toMap());
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _ds.updateDoc(FirestorePaths.expenses, expense.id, expense.toMap());
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _ds.deleteDoc(FirestorePaths.expenses, id);
  }
}
