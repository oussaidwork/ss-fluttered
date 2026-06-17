import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../enums/expense_category.dart';

class Expense {
  final String id;
  final String description;
  final double amount;
  final double? quantity;
  final ExpenseCategory? category;
  final DateTime timestamp;
  final String? recordedBy;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    this.quantity,
    this.category,
    required this.timestamp,
    this.recordedBy,
  });

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    double? quantity,
    ExpenseCategory? category,
    DateTime? timestamp,
    String? recordedBy,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'quantity': quantity,
      'category': category?.value,
      'timestamp': Timestamp.fromDate(timestamp),
      'recordedBy': recordedBy,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble(),
      category: map['category'] != null
          ? ExpenseCategory.fromString(map['category'] as String)
          : null,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: map['recordedBy'] as String?,
    );
  }
}
