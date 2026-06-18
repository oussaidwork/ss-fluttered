import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/debt.dart';

enum _DatePreset { all, today, week, month }
enum _TxnType { all, sales, payments, debts }

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  _DatePreset _datePreset = _DatePreset.all;
  _TxnType _txnType = _TxnType.all;

  DateTime? get _dateFrom {
    final now = DateTime.now();
    switch (_datePreset) {
      case _DatePreset.all:
        return null;
      case _DatePreset.today:
        return DateTime(now.year, now.month, now.day);
      case _DatePreset.week:
        return now.subtract(const Duration(days: 7));
      case _DatePreset.month:
        return DateTime(now.year, now.month, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Transaction Ledger',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFilterBar(),
          const SizedBox(height: 20),
          _buildKpiBar(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('Date:', style: TextStyle(color: Colors.white54)),
          const SizedBox(width: 8),
          ..._DatePreset.values.map((preset) {
            final labels = {_DatePreset.all: 'All', _DatePreset.today: 'Today', _DatePreset.week: 'Week', _DatePreset.month: 'Month'};
            final selected = _datePreset == preset;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(labels[preset]!),
                selected: selected,
                selectedColor: const Color(0xFF0066CC),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white54),
                onSelected: (_) => setState(() => _datePreset = preset),
              ),
            );
          }),
          const SizedBox(width: 24),
          const Text('Type:', style: TextStyle(color: Colors.white54)),
          const SizedBox(width: 8),
          ..._TxnType.values.map((type) {
            final labels = {_TxnType.all: 'All', _TxnType.sales: 'Sales', _TxnType.payments: 'Payments', _TxnType.debts: 'Debts'};
            final selected = _txnType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(labels[type]!),
                selected: selected,
                selectedColor: const Color(0xFF0066CC),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white54),
                onSelected: (_) => setState(() => _txnType = type),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKpiBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: _dateFrom != null
          ? firestore
              .collection('sales')
              .where('isDeleted', isEqualTo: false)
              .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateFrom!))
              .snapshots()
          : firestore.collection('sales').where('isDeleted', isEqualTo: false).snapshots(),
      builder: (ctx, salesSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _dateFrom != null
              ? firestore
                  .collection('payments')
                  .where('isDeleted', isEqualTo: false)
                  .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateFrom!))
                  .snapshots()
              : firestore.collection('payments').where('isDeleted', isEqualTo: false).snapshots(),
          builder: (ctx, paymentsSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: _dateFrom != null
                  ? firestore
                      .collection('debts')
                      .where('isDeleted', isEqualTo: false)
                      .where('created', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateFrom!))
                      .snapshots()
                  : firestore.collection('debts').where('isDeleted', isEqualTo: false).snapshots(),
              builder: (ctx, debtsSnap) {
                double totalSales = 0;
                double totalCollected = 0;
                double totalOutstanding = 0;

                if (salesSnap.hasData) {
                  for (final doc in salesSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalSales += (data['totalAmount'] as num?)?.toDouble() ?? 0;
                  }
                }
                if (paymentsSnap.hasData) {
                  for (final doc in paymentsSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? '';
                    if (status == 'COMPLETED') {
                      totalCollected += (data['amount'] as num?)?.toDouble() ?? 0;
                    }
                  }
                }
                if (debtsSnap.hasData) {
                  for (final doc in debtsSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalOutstanding += (data['amount'] as num?)?.toDouble() ?? 0;
                  }
                }
                final net = totalSales + totalCollected - totalOutstanding;

                return Row(
                  children: [
                    _kpiCard('Revenue', totalSales, const Color(0xFF0066CC), Icons.trending_up),
                    const SizedBox(width: 12),
                    _kpiCard('Collected', totalCollected, const Color(0xFF84CC16), Icons.check_circle_outline),
                    const SizedBox(width: 12),
                    _kpiCard('Outstanding', totalOutstanding, const Color(0xFFF59E0B), Icons.warning_amber_outlined),
                    const SizedBox(width: 12),
                    _kpiCard('Net', net, Colors.white, Icons.account_balance_wallet),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _kpiCard(String label, double value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  '${value.toStringAsFixed(2)} DA',
                  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('sales').where('isDeleted', isEqualTo: false).snapshots(),
      builder: (ctx, salesSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('payments').where('isDeleted', isEqualTo: false).snapshots(),
          builder: (ctx, paymentsSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('debts').where('isDeleted', isEqualTo: false).snapshots(),
              builder: (ctx, debtsSnap) {
                final List<_TransactionItem> items = [];

                if (salesSnap.hasData && _txnType != _TxnType.payments && _txnType != _TxnType.debts) {
                  for (final doc in salesSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final sale = Sale.fromMap(data);
                    if (_dateFrom != null && sale.timestamp != null && sale.timestamp!.isBefore(_dateFrom!)) continue;
                    items.add(_TransactionItem(
                      timestamp: sale.timestamp ?? DateTime.now(),
                      type: 'SALE',
                      sale: sale,
                      payment: null,
                      debt: null,
                    ));
                  }
                }

                if (paymentsSnap.hasData && _txnType != _TxnType.sales && _txnType != _TxnType.debts) {
                  for (final doc in paymentsSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final payment = Payment.fromMap(data);
                    if (_dateFrom != null && payment.createdAt.isBefore(_dateFrom!)) continue;
                    items.add(_TransactionItem(
                      timestamp: payment.createdAt,
                      type: 'PAYMENT',
                      sale: null,
                      payment: payment,
                      debt: null,
                    ));
                  }
                }

                if (debtsSnap.hasData && _txnType != _TxnType.sales && _txnType != _TxnType.payments) {
                  for (final doc in debtsSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final debt = Debt.fromMap(data);
                    if (_dateFrom != null && debt.created.isBefore(_dateFrom!)) continue;
                    items.add(_TransactionItem(
                      timestamp: debt.created,
                      type: 'DEBT',
                      sale: null,
                      payment: null,
                      debt: debt,
                    ));
                  }
                }

                items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_dateFrom != null ? Icons.event_busy : Icons.receipt_long, size: 64, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text('No transactions found', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, idx) => _buildTransactionCard(items[idx]),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(_TransactionItem item) {
    return Card(
      color: const Color(0xFF1A2332),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.all(16),
        leading: _txnIcon(item.type),
        title: Row(
          children: [
            _txnBadge(item.type),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _txnTitle(item),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _formatDateTime(item.timestamp),
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Text(
          _txnAmount(item),
          style: TextStyle(
            color: _txnAmountColor(item),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        children: [_txnDetails(item)],
      ),
    );
  }

  Widget _txnIcon(String type) {
    switch (type) {
      case 'SALE':
        return const CircleAvatar(
          backgroundColor: Color(0xFF0066CC),
          radius: 18,
          child: Icon(Icons.local_gas_station, color: Colors.white, size: 18),
        );
      case 'PAYMENT':
        return const CircleAvatar(
          backgroundColor: Color(0xFF84CC16),
          radius: 18,
          child: Icon(Icons.payments, color: Colors.white, size: 18),
        );
      case 'DEBT':
        return const CircleAvatar(
          backgroundColor: Color(0xFFF59E0B),
          radius: 18,
          child: Icon(Icons.money_off, color: Colors.white, size: 18),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.white24,
          radius: 18,
          child: Icon(Icons.help_outline, color: Colors.white, size: 18),
        );
    }
  }

  Widget _txnBadge(String type) {
    final colors = {
      'SALE': const Color(0xFF0066CC),
      'PAYMENT': const Color(0xFF84CC16),
      'DEBT': const Color(0xFFF59E0B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (colors[type] ?? Colors.white24).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(type, style: TextStyle(color: colors[type], fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _txnTitle(_TransactionItem item) {
    switch (item.type) {
      case 'SALE':
        final s = item.sale!;
        return 'Sale #${s.id.substring(0, s.id.length > 6 ? 6 : s.id.length).toUpperCase()}';
      case 'PAYMENT':
        return 'Payment from client';
      case 'DEBT':
        final d = item.debt!;
        return d.driverName ?? 'Unassigned debt';
      default:
        return '';
    }
  }

  String _txnAmount(_TransactionItem item) {
    switch (item.type) {
      case 'SALE':
        return '+${item.sale!.totalAmount.toStringAsFixed(2)} DA';
      case 'PAYMENT':
        return '+${item.payment!.amount.toStringAsFixed(2)} DA';
      case 'DEBT':
        return '-${item.debt!.amount.toStringAsFixed(2)} DA';
      default:
        return '';
    }
  }

  Color _txnAmountColor(_TransactionItem item) {
    switch (item.type) {
      case 'SALE':
        return const Color(0xFF84CC16);
      case 'PAYMENT':
        return const Color(0xFF84CC16);
      case 'DEBT':
        return const Color(0xFFEF4444);
      default:
        return Colors.white;
    }
  }

  Widget _txnDetails(_TransactionItem item) {
    switch (item.type) {
      case 'SALE':
        final s = item.sale!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('Total', '${s.totalAmount.toStringAsFixed(2)} DA'),
            if (s.paymentTypeId != null) _detailLine('Payment Method', s.paymentTypeId!),
            if (s.notes != null && s.notes!.isNotEmpty) _detailLine('Notes', s.notes!),
          ],
        );
      case 'PAYMENT':
        final p = item.payment!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('Amount', '${p.amount.toStringAsFixed(2)} DA'),
            _detailLine('Status', p.status.value),
            if (p.paymentTypeId != null) _detailLine('Method', p.paymentTypeId!),
            if (p.dueDate != null) _detailLine('Due Date', _formatDate(p.dueDate!)),
          ],
        );
      case 'DEBT':
        final d = item.debt!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('Amount', '${d.amount.toStringAsFixed(2)} DA'),
            if (d.dueDate != null) _detailLine('Due Date', _formatDate(d.dueDate!)),
            if (d.driverName != null) _detailLine('Driver', d.driverName!),
            if (d.vehiclePlate != null) _detailLine('Plate', d.vehiclePlate!),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _TransactionItem {
  final DateTime timestamp;
  final String type;
  final Sale? sale;
  final Payment? payment;
  final Debt? debt;

  const _TransactionItem({
    required this.timestamp,
    required this.type,
    this.sale,
    this.payment,
    this.debt,
  });
}
