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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Expense Tracking',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showExpenseDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTotalSummary(),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('expenses')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }
                final expenses = snapshot.data!.docs
                    .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();
                return _buildExpenseTable(expenses);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('expenses').snapshots(),
      builder: (context, snapshot) {
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
            color: const Color(0xFF1A2332),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Color(0xFFEF4444), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Expenses', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    '${total.toStringAsFixed(2)} DA',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
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
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${snapshot.data?.docs.length ?? 0} records',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No expenses recorded', style: TextStyle(fontSize: 18, color: Colors.white54)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showExpenseDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Record First Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTable(List<Expense> expenses) {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
            columns: const [
              DataColumn(label: Text('Description', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Qty', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Category', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Date', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Recorded By', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            ],
            rows: expenses.map((expense) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    expense.description,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  )),
                  DataCell(Text(
                    '${expense.amount.toStringAsFixed(2)} DA',
                    style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                  )),
                  DataCell(Text(
                    expense.quantity != null ? expense.quantity!.toStringAsFixed(0) : '--',
                    style: const TextStyle(color: Colors.white70),
                  )),
                  DataCell(_buildCategoryBadge(expense.category)),
                  DataCell(Text(
                    _formatDate(expense.timestamp),
                    style: const TextStyle(color: Colors.white70),
                  )),
                  DataCell(Text(
                    expense.recordedBy ?? '--',
                    style: const TextStyle(color: Colors.white70),
                  )),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Color(0xFF0066CC)),
                          onPressed: () => _showExpenseDialog(expense: expense),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
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

  Widget _buildCategoryBadge(ExpenseCategory? category) {
    if (category == null) {
      return const Text('--', style: TextStyle(color: Colors.white38));
    }
    final colors = {
      ExpenseCategory.supplies: const Color(0xFF0066CC),
      ExpenseCategory.maintenance: const Color(0xFFF59E0B),
      ExpenseCategory.salary: const Color(0xFF84CC16),
      ExpenseCategory.utilities: const Color(0xFF8B5CF6),
      ExpenseCategory.rent: const Color(0xFFEF4444),
      ExpenseCategory.transport: const Color(0xFF06B6D4),
      ExpenseCategory.other: Colors.white54,
    };
    final color = colors[category] ?? Colors.white54;
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
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit : Icons.add_circle, color: const Color(0xFF0066CC), size: 22),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Expense' : 'Add Expense', style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(descCtrl, 'Description', Icons.description),
                  const SizedBox(height: 12),
                  _buildTextField(amountCtrl, 'Amount (DA)', Icons.attach_money, 
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(qtyCtrl, 'Quantity', Icons.inventory_2, 
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseCategory>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF1A2332),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0066CC)),
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
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF0066CC),
                                surface: Color(0xFF1A2332),
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
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(selectedDate), style: const TextStyle(color: Colors.white)),
                          const Icon(Icons.calendar_today, color: Color(0xFF0066CC), size: 20),
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
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in description and amount'),
                        backgroundColor: Color(0xFFEF4444),
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
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                          backgroundColor: Color(0xFFEF4444),
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
                        const SnackBar(
                          content: Text('You must be logged in to save expenses'),
                          backgroundColor: Color(0xFFEF4444),
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
                      const SnackBar(
                        content: Text('Expense saved successfully'),
                        backgroundColor: Color(0xFF84CC16),
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
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                }

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() {}));
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0066CC)),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${expense.description}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await firestore.collection('expenses').doc(expense.id).update({'isDeleted': true});
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
