import '../entities/expense.dart';
import '../enums/expense_category.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpenses({ExpenseCategory? category});
  Future<void> createExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
}
