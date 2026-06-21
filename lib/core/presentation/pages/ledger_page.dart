import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/client_fleet.dart';
import '../../../presentation/providers/client_provider.dart';
import '../../../presentation/providers/client_fleet_provider.dart';

enum _DatePreset { all, today, week, month }
enum _TxnType { all, sales, payments, debts }

class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key});

  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  _DatePreset _datePreset = _DatePreset.all;
  _TxnType _txnType = _TxnType.all;
  Client? _selectedClient;
  String? _selectedVehiclePlate;

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
    final cs = Theme.of(context).colorScheme;
    final clientsAsync = ref.watch(clientsProvider);
    final fleetAsync = _selectedClient != null
        ? ref.watch(clientFleetByClientProvider(_selectedClient!.id))
        : const AsyncData<List<ClientFleet>>([]);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.book, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Transaction Ledger',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Client selector
          _buildClientSelector(clientsAsync),
          const SizedBox(height: 12),

          // Fleet vehicle chips
          if (_selectedClient != null)
            _buildFleetChips(fleetAsync),

          // Filter bar
          _buildFilterBar(),
          const SizedBox(height: 20),

          // KPI bar
          _buildKpiBar(),
          const SizedBox(height: 20),

          // Transaction list
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelector(AsyncValue<List<Client>> clientsAsync) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: cs.secondary, size: 20),
          const SizedBox(width: 12),
          Text('Client:', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
          const SizedBox(width: 12),
          Expanded(
            child: clientsAsync.when(
              data: (clients) => DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedClient?.id,
                  isExpanded: true,
                  dropdownColor: cs.surfaceContainerHighest,
                  style: TextStyle(color: cs.onSurface),
                  hint: Text('All Clients', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38))),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Clients', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
                    ),
                    ...clients.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name, style: TextStyle(color: cs.onSurface)),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedVehiclePlate = null;
                      if (val == null) {
                        _selectedClient = null;
                      } else {
                        _selectedClient = clients.firstWhere((c) => c.id == val);
                      }
                    });
                  },
                ),
              ),
              loading: () => SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
              ),
              error: (_, _) => Text('Error loading clients', style: TextStyle(color: cs.error)),
            ),
          ),
          if (_selectedClient != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Balance: ${_selectedClient!.currentBalance.toStringAsFixed(2)} DA',
                  style: TextStyle(color: cs.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFleetChips(AsyncValue<List<ClientFleet>> fleetAsync) {
    final cs = Theme.of(context).colorScheme;
    return fleetAsync.when(
      data: (fleet) {
        if (fleet.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_car, color: cs.primaryContainer, size: 18),
                  const SizedBox(width: 8),
                  Text('Fleet Vehicles', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                  const SizedBox(width: 8),
                  Text('(${fleet.length})', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: fleet.map((v) {
                  final selected = _selectedVehiclePlate == v.plateNumber;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVehiclePlate = selected ? null : v.plateNumber;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primaryContainer.withValues(alpha: 0.2)
                            : cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? cs.primaryContainer
                              : cs.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping,
                            size: 14,
                            color: selected ? cs.primaryContainer : cs.onSurface.withValues(alpha: 0.54),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            v.plateNumber,
                            style: TextStyle(
                              color: selected ? cs.primaryContainer : cs.onSurface.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (v.driverName != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${v.driverName})',
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildFilterBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('Date:', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
          const SizedBox(width: 8),
          ..._DatePreset.values.map((preset) {
            final labels = {_DatePreset.all: 'All', _DatePreset.today: 'Today', _DatePreset.week: 'Week', _DatePreset.month: 'Month'};
            final selected = _datePreset == preset;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(labels[preset]!),
                selected: selected,
                selectedColor: cs.primary,
                backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                labelStyle: TextStyle(color: selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.54)),
                onSelected: (_) => setState(() => _datePreset = preset),
              ),
            );
          }),
          const SizedBox(width: 24),
          Text('Type:', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
          const SizedBox(width: 8),
          ..._TxnType.values.map((type) {
            final labels = {_TxnType.all: 'All', _TxnType.sales: 'Sales', _TxnType.payments: 'Payments', _TxnType.debts: 'Debts'};
            final selected = _txnType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(labels[type]!),
                selected: selected,
                selectedColor: cs.primary,
                backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                labelStyle: TextStyle(color: selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.54)),
                onSelected: (_) => setState(() => _txnType = type),
              ),
            );
          }),
          const Spacer(),
          // Active client tag
          if (_selectedClient != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, size: 14, color: cs.secondary),
                  const SizedBox(width: 6),
                  Text(
                    _selectedClient!.name,
                    style: TextStyle(color: cs.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (_selectedVehiclePlate != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '/ $_selectedVehiclePlate',
                      style: TextStyle(color: cs.primaryContainer, fontSize: 11),
                    ),
                  ],
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedClient = null;
                      _selectedVehiclePlate = null;
                    }),
                    child: Icon(Icons.close, size: 14, color: cs.onSurface.withValues(alpha: 0.38)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiBar() {
    final clientId = _selectedClient?.id;

    Stream<QuerySnapshot> salesStream() {
      Query q = firestore.collection('sales').where('isDeleted', isEqualTo: false);
      if (clientId != null) {
        q = q.where('clientId', isEqualTo: clientId);
      }
      if (_dateFrom != null) {
        q = q.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateFrom!));
      }
      return q.snapshots();
    }

    Stream<QuerySnapshot> paymentsStream() {
      Query q = firestore.collection('payments').where('isDeleted', isEqualTo: false);
      if (clientId != null) {
        q = q.where('clientId', isEqualTo: clientId);
      }
      if (_dateFrom != null) {
        q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateFrom!));
      }
      return q.snapshots();
    }

    Stream<QuerySnapshot> debtsStream() {
      Query q = firestore.collection('debts').where('isDeleted', isEqualTo: false);
      if (clientId != null) {
        q = q.where('clientId', isEqualTo: clientId);
      }
      if (_selectedVehiclePlate != null) {
        q = q.where('vehiclePlate', isEqualTo: _selectedVehiclePlate);
      }
      if (_dateFrom != null) {
        q = q.where('created', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateFrom!));
      }
      return q.snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: salesStream(),
      builder: (ctx, salesSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: paymentsStream(),
          builder: (ctx, paymentsSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: debtsStream(),
              builder: (ctx, debtsSnap) {
                final cs = Theme.of(ctx).colorScheme;
                double totalSales = 0;
                double totalCollected = 0;
                double totalOutstanding = 0;

                if (salesSnap.hasData) {
                  for (final doc in salesSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalSales += (data['totalPrice'] as num?)?.toDouble() ?? 0;
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
                    _kpiCard('Revenue', totalSales, cs.primary, Icons.trending_up),
                    const SizedBox(width: 12),
                    _kpiCard('Collected', totalCollected, cs.secondary, Icons.check_circle_outline),
                    const SizedBox(width: 12),
                    _kpiCard('Outstanding', totalOutstanding, cs.tertiary, Icons.warning_amber_outlined),
                    const SizedBox(width: 12),
                    _kpiCard('Net', net, cs.onSurface, Icons.account_balance_wallet),
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
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
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
                Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12)),
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
    final cs = Theme.of(context).colorScheme;
    final clientId = _selectedClient?.id;

    Stream<QuerySnapshot> salesStream() {
      Query q = firestore.collection('sales').where('isDeleted', isEqualTo: false);
      if (clientId != null) {
        q = q.where('clientId', isEqualTo: clientId);
      }
      return q.orderBy('timestamp', descending: true).snapshots();
    }

    Stream<QuerySnapshot> paymentsStream() {
      Query q = firestore.collection('payments').where('isDeleted', isEqualTo: false);
      if (clientId != null) {
        q = q.where('clientId', isEqualTo: clientId);
      }
      return q.orderBy('createdAt', descending: true).snapshots();
    }

    Stream<QuerySnapshot> debtsStream() {
      Query q = firestore.collection('debts').where('isDeleted', isEqualTo: false);
      if (clientId != null) {
        q = q.where('clientId', isEqualTo: clientId);
      }
      if (_selectedVehiclePlate != null) {
        q = q.where('vehiclePlate', isEqualTo: _selectedVehiclePlate);
      }
      return q.orderBy('created', descending: true).snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: salesStream(),
      builder: (ctx, salesSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: paymentsStream(),
          builder: (ctx, paymentsSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: debtsStream(),
              builder: (ctx, debtsSnap) {
                final List<_TransactionItem> items = [];

                if (salesSnap.hasData && _txnType != _TxnType.payments && _txnType != _TxnType.debts) {
                  for (final doc in salesSnap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final sale = Sale.fromMap(data);
                    if (_selectedVehiclePlate != null) continue; // cannot filter sales by plate without sale_items
                    if (_dateFrom != null && sale.timestamp.isBefore(_dateFrom!)) continue;
                    items.add(_TransactionItem(
                      timestamp: sale.timestamp,
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
                    if (_selectedVehiclePlate != null && debt.vehiclePlate != _selectedVehiclePlate) continue;
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
                        Icon(_dateFrom != null ? Icons.event_busy : Icons.receipt_long, size: 64, color: cs.onSurface.withValues(alpha: 0.24)),
                        const SizedBox(height: 16),
                        Text('No transactions found', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 16)),
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
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
                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _formatDateTime(item.timestamp),
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12),
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
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case 'SALE':
        return CircleAvatar(
          backgroundColor: cs.primary,
          radius: 18,
          child: Icon(Icons.local_gas_station, color: cs.onSurface, size: 18),
        );
      case 'PAYMENT':
        return CircleAvatar(
          backgroundColor: cs.secondary,
          radius: 18,
          child: Icon(Icons.payments, color: cs.onSurface, size: 18),
        );
      case 'DEBT':
        return CircleAvatar(
          backgroundColor: cs.tertiary,
          radius: 18,
          child: Icon(Icons.money_off, color: cs.onSurface, size: 18),
        );
      default:
        return CircleAvatar(
          backgroundColor: cs.onSurface.withValues(alpha: 0.24),
          radius: 18,
          child: Icon(Icons.help_outline, color: cs.onSurface, size: 18),
        );
    }
  }

  Widget _txnBadge(String type) {
    final cs = Theme.of(context).colorScheme;
    final Map<String, Color> colors = {
      'SALE': cs.primary,
      'PAYMENT': cs.secondary,
      'DEBT': cs.tertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (colors[type] ?? cs.onSurface.withValues(alpha: 0.24)).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(type, style: TextStyle(color: colors[type], fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _txnTitle(_TransactionItem item) {
    switch (item.type) {
      case 'SALE':
        final s = item.sale!;
        final clientTag = _selectedClient != null ? _selectedClient!.name : '';
        final shortId = s.id.length > 6 ? s.id.substring(0, 6) : s.id;
        return clientTag.isNotEmpty ? '$clientTag - Sale #${shortId.toUpperCase()}' : 'Sale #${shortId.toUpperCase()}';
      case 'PAYMENT':
        final clientTag = _selectedClient != null ? _selectedClient!.name : '';
        return clientTag.isNotEmpty ? 'Payment from $clientTag' : 'Payment from client';
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
        return '+${item.sale!.totalPrice.toStringAsFixed(2)} DA';
      case 'PAYMENT':
        return '+${item.payment!.amount.toStringAsFixed(2)} DA';
      case 'DEBT':
        return '-${item.debt!.amount.toStringAsFixed(2)} DA';
      default:
        return '';
    }
  }

  Color _txnAmountColor(_TransactionItem item) {
    final cs = Theme.of(context).colorScheme;
    switch (item.type) {
      case 'SALE':
        return cs.secondary;
      case 'PAYMENT':
        return cs.secondary;
      case 'DEBT':
        return cs.error;
      default:
        return cs.onSurface;
    }
  }

  Widget _txnDetails(_TransactionItem item) {
    switch (item.type) {
      case 'SALE':
        return _buildSaleDetails(item.sale!);
      case 'PAYMENT':
        return _buildPaymentDetails(item.payment!);
      case 'DEBT':
        return _buildDebtDetails(item.debt!);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSaleDetails(Sale s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Total', '${s.totalPrice.toStringAsFixed(2)} DA'),
        if (s.paymentTypeId != null) _detailRow('Payment Method', s.paymentTypeId!),
        if (s.notes != null && s.notes!.isNotEmpty) _detailRow('Notes', s.notes!),
        // Show client name in sale details when not filtered by client
        if (_selectedClient == null && s.clientId != null)
          StreamBuilder<DocumentSnapshot>(
            stream: firestore.collection('clients').doc(s.clientId).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
              final clientName = (snap.data!.data() as Map<String, dynamic>?)?
                ['name'] as String? ?? '';
              return clientName.isNotEmpty
                  ? _detailRow('Client', clientName)
                  : const SizedBox.shrink();
            },
          ),
        const SizedBox(height: 8),
        // Sale items section
        _SaleItemsSection(saleId: s.id),
      ],
    );
  }

  Widget _buildPaymentDetails(Payment p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Amount', '${p.amount.toStringAsFixed(2)} DA'),
        _detailRow('Status', p.status.value),
        if (p.paymentTypeId != null) _detailRow('Method', p.paymentTypeId!),
        if (p.dueDate != null) _detailRow('Due Date', _formatDate(p.dueDate!)),
        // Show client name in payment details when not filtered by client
        if (_selectedClient == null && p.clientId != null)
          StreamBuilder<DocumentSnapshot>(
            stream: firestore.collection('clients').doc(p.clientId).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
              final clientName = (snap.data!.data() as Map<String, dynamic>?)?
                ['name'] as String? ?? '';
              return clientName.isNotEmpty
                  ? _detailRow('Client', clientName)
                  : const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildDebtDetails(Debt d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow('Amount', '${d.amount.toStringAsFixed(2)} DA'),
        if (d.dueDate != null) _detailRow('Due Date', _formatDate(d.dueDate!)),
        if (d.driverName != null) _detailRow('Driver', d.driverName!),
        if (d.vehiclePlate != null) _detailRow('Vehicle Plate', d.vehiclePlate!),
        // Show client name in debt details when not filtered by client
        if (_selectedClient == null && d.clientId.isNotEmpty)
          StreamBuilder<DocumentSnapshot>(
            stream: firestore.collection('clients').doc(d.clientId).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
              final clientName = (snap.data!.data() as Map<String, dynamic>?)?
                ['name'] as String? ?? '';
              return clientName.isNotEmpty
                  ? _detailRow('Client', clientName)
                  : const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: cs.onSurface, fontSize: 13)),
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

/// Internal widget that loads and displays sale_items for a given sale.
class _SaleItemsSection extends ConsumerWidget {
  final String saleId;
  const _SaleItemsSection({required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final itemsAsync = ref.watch(_saleItemsBySaleProvider(saleId));
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    _itemTypeIcon(cs, item.saleType.value),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity.toStringAsFixed(0)}x ${item.saleType.value}',
                            style: TextStyle(color: cs.onSurface, fontSize: 12),
                          ),
                          if (item.vehiclePlate != null || item.driverName != null)
                            Text(
                              [
                                if (item.driverName != null) item.driverName,
                                if (item.vehiclePlate != null) item.vehiclePlate,
                              ].join(' - '),
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.lineTotal.toStringAsFixed(2)} DA',
                      style: TextStyle(color: cs.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
      loading: () => SizedBox(
        height: 20,
        child: Center(child: SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        )),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _itemTypeIcon(ColorScheme cs, String type) {
    final icons = {
      'FUEL': Icons.local_gas_station,
      'PRODUCT': Icons.shopping_bag,
      'SERVICE': Icons.build,
    };
    return Icon(icons[type] ?? Icons.receipt, size: 14, color: cs.onSurface.withValues(alpha: 0.38));
  }
}

/// Provider that streams sale_items for a given sale ID.
final _saleItemsBySaleProvider = StreamProvider.family<List<SaleItem>, String>((ref, saleId) {
  return firestore
      .collection('sale_items')
      .where('saleId', isEqualTo: saleId)
      .snapshots()
      .map((snap) => snap.docs.map((d) => SaleItem.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList());
});

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
