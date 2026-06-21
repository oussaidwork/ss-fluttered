import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../data/auth/firebase_auth_provider.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/enums/expense_category.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Expense Tracking',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showExpenseDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTotalSummary(cs),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('expenses')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final innerCs = Theme.of(context).colorScheme;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: innerCs.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(innerCs);
                }
                final expenses = snapshot.data!.docs
                    .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();
                return _buildExpenseTable(expenses, innerCs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary(ColorScheme cs) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('expenses').snapshots(),
      builder: (context, snapshot) {
        final innerCs = Theme.of(context).colorScheme;
        double total = 0;
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total += (data['amount'] as num?)?.toDouble() ?? 0;
          }
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: innerCs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: innerCs.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: innerCs.error, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Expenses', style: TextStyle(color: innerCs.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '${total.toStringAsFixed(2)} DA',
                    style: TextStyle(
                      color: innerCs.error,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: innerCs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${snapshot.data?.docs.length ?? 0} records',
                  style: TextStyle(color: innerCs.onSurface.withValues(alpha: 0.54), fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 64, color: cs.onSurface.withValues(alpha: 0.24)),
          const SizedBox(height: 16),
          Text('No expenses recorded', style: TextStyle(fontSize: 18, color: cs.onSurface.withValues(alpha: 0.54))),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showExpenseDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Record First Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTable(List<Expense> expenses, ColorScheme cs) {
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(cs.onSurface.withValues(alpha: 0.05)),
            columns: [
              DataColumn(label: Text('Description', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Amount', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Qty', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Category', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Date', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Recorded By', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Actions', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600))),
            ],
            rows: expenses.map((expense) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    expense.description,
                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
                  )),
                  DataCell(Text(
                    '${expense.amount.toStringAsFixed(2)} DA',
                    style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                  )),
                  DataCell(Text(
                    expense.quantity != null ? expense.quantity!.toStringAsFixed(0) : '--',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                  )),
                  DataCell(_buildCategoryBadge(expense.category, cs)),
                  DataCell(Text(
                    _formatDate(expense.timestamp),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                  )),
                  DataCell(Text(
                    expense.recordedBy ?? '--',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                  )),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 18, color: cs.primary),
                          onPressed: () => _showExpenseDialog(expense: expense),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                          onPressed: () => _deleteExpense(expense),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(ExpenseCategory? category, ColorScheme cs) {
    if (category == null) {
      return Text('--', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38)));
    }
    final colors = {
      ExpenseCategory.supplies: cs.primary,
      ExpenseCategory.maintenance: cs.tertiary,
      ExpenseCategory.salary: cs.secondary,
      ExpenseCategory.utilities: cs.secondaryContainer,
      ExpenseCategory.rent: cs.error,
      ExpenseCategory.transport: cs.primaryContainer,
      ExpenseCategory.other: cs.onSurface.withValues(alpha: 0.54),
    };
    final color = colors[category] ?? cs.onSurface.withValues(alpha: 0.54);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        category.value,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  Future<void> _showExpenseDialog({Expense? expense}) async {
    final isEdit = expense != null;
    final descCtrl = TextEditingController(text: expense?.description ?? '');
    final amountCtrl = TextEditingController(
      text: expense != null ? expense.amount.toString() : '',
    );
    final qtyCtrl = TextEditingController(
      text: expense?.quantity != null ? expense!.quantity.toString() : '',
    );
    ExpenseCategory selectedCategory = expense?.category ?? ExpenseCategory.other;
    DateTime selectedDate = expense?.timestamp ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dialogCs = Theme.of(ctx).colorScheme;
          return AlertDialog(
          backgroundColor: dialogCs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit : Icons.add_circle, color: dialogCs.primary, size: 22),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Expense' : 'Add Expense', style: TextStyle(color: dialogCs.onSurface)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(descCtrl, 'Description', Icons.description, dialogCs),
                  const SizedBox(height: 12),
                  _buildTextField(amountCtrl, 'Amount (DA)', Icons.attach_money, dialogCs,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(qtyCtrl, 'Quantity', Icons.inventory_2, dialogCs,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseCategory>(
                    value: selectedCategory,
                    dropdownColor: dialogCs.surfaceContainerHighest,
                    style: TextStyle(color: dialogCs.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: dialogCs.onSurface.withValues(alpha: 0.54)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: dialogCs.onSurface.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: dialogCs.primary),
                      ),
                    ),
                    items: ExpenseCategory.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.value),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickerCs = Theme.of(context).colorScheme;
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: pickerCs.primary,
                                surface: pickerCs.surfaceContainerHighest,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && ctx.mounted) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: dialogCs.onSurface.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(selectedDate), style: TextStyle(color: dialogCs.onSurface)),
                          Icon(Icons.calendar_today, color: dialogCs.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: dialogCs.onSurface.withValues(alpha: 0.54))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: const Text('Please fill in description and amount'),
                        backgroundColor: dialogCs.error,
                      ),
                    );
                  }
                  return;
                }
                
                try {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter a valid amount'),
                          backgroundColor: dialogCs.error,
                        ),
                      );
                    }
                    return;
                  }
                  
                  final quantity = qtyCtrl.text.trim().isEmpty 
                      ? null 
                      : double.tryParse(qtyCtrl.text.trim());

                  final currentUser = firebaseAuthProvider.currentUser;
                  if (currentUser == null) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text('You must be logged in to save expenses'),
                          backgroundColor: dialogCs.error,
                        ),
                      );
                    }
                    return;
                  }

                  await _saveExpense(
                    id: expense?.id,
                    description: descCtrl.text.trim(),
                    amount: amount,
                    quantity: quantity,
                    category: selectedCategory,
                    timestamp: selectedDate,
                    recordedBy: currentUser.email ?? currentUser.uid,
                    isEdit: isEdit,
                  );
                  
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: const Text('Expense saved successfully'),
                        backgroundColor: dialogCs.secondary,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    String errorMessage = 'Error saving expense: $e';
                    if (e.toString().contains('permission-denied')) {
                      errorMessage = 'Permission denied: You may not be logged in or your account lacks the required permissions.';
                    }
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: dialogCs.error,
                      ),
                    );
                  }
                }

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogCs.primary,
                foregroundColor: dialogCs.onSurface,
              ),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        );
},
      ),
    ).then((_) => setState(() {}));
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, ColorScheme cs,
      {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
        prefixIcon: Icon(icon, color: cs.onSurface.withValues(alpha: 0.38), size: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.primary),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _saveExpense({
    String? id,
    required String description,
    required double amount,
    double? quantity,
    required ExpenseCategory category,
    required DateTime timestamp,
    required String recordedBy,
    required bool isEdit,
  }) async {
    final now = DateTime.now();
    final data = {
      'description': description,
      'amount': amount,
      'quantity': quantity,
      'category': category.value,
      'timestamp': Timestamp.fromDate(timestamp),
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(now),
    };
    if (isEdit && id != null) {
      await firestore.collection('expenses').doc(id).update(data);
    } else {
      final docRef = firestore.collection('expenses').doc();
      data['id'] = docRef.id;
      await docRef.set(data);
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final deleteCs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: deleteCs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Expense', style: TextStyle(color: deleteCs.onSurface)),
          content: Text(
            'Delete "${expense.description}"?',
            style: TextStyle(color: deleteCs.onSurface.withValues(alpha: 0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: deleteCs.onSurface.withValues(alpha: 0.54))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: deleteCs.error),
              child: Text('Delete', style: TextStyle(color: deleteCs.onSurface)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await firestore.collection('expenses').doc(expense.id).update({'isDeleted': true});
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
