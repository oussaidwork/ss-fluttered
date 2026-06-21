import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/client.dart';
import '../../../presentation/providers/client_provider.dart';

/// ────────────────────────────────────────────────────────────────
/// Clients Ledger & Credit Manager
/// Monitor client balances, credit lines, and recorded payments.
/// ────────────────────────────────────────────────────────────────
class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  String _searchQuery = '';
  bool _showArchived = false;
  int _tableTabIndex = 0;
  String? _selectedClientId;

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────

  bool _clientMatches(Client c) =>
      _searchQuery.isEmpty ||
      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (c.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
      (c.plateNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _TopHeaderWidget(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildClientList()),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: _buildDetails()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  LEFT — CLIENT LIST
  // ─────────────────────────────────────────────────────────────

  Widget _buildClientList() {
    final cs = Theme.of(context).colorScheme;
    final clientsAsync = ref.watch(
      _showArchived ? archivedClientsProvider : clientsProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clients Ledger & Credit Manager',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'Monitor client balances, credit lines, and recorded payments.',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
        ),
        const SizedBox(height: 20),

        // Active / Archived tabs
        Row(
          children: [
            _buildTab(
              'Active',
              count: ref.watch(clientsProvider).whenOrNull(data: (l) => l.length) ?? 0,
              isActive: !_showArchived,
              onTap: () => setState(() {
                _showArchived = false;
                _selectedClientId = null;
              }),
            ),
            const SizedBox(width: 8),
            _buildTab(
              'Archived',
              count: ref.watch(archivedClientsProvider).whenOrNull(data: (l) => l.length) ?? 0,
              isActive: _showArchived,
              onTap: () => setState(() {
                _showArchived = true;
                _selectedClientId = null;
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Search clients...',
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.38)),
            prefixIcon: Icon(Icons.search, color: cs.onSurface.withValues(alpha: 0.38)),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        const SizedBox(height: 16),

        // Client tiles
        Expanded(
          child: clientsAsync.when(
            data: (clients) {
              final filtered = clients.where(_clientMatches).toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                        size: 48,
                        color: cs.onSurface.withValues(alpha: 0.24),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No clients match "$_searchQuery"'
                            : _showArchived
                                ? 'No archived clients'
                                : 'No clients yet',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38)),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) => _buildClientTile(filtered[i]),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: cs.secondary),
            ),
            error: (err, _) => Center(
              child: Text('Error: $err', style: TextStyle(color: cs.error)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, {required int count, required bool isActive, VoidCallback? onTap}) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? cs.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: cs.onSurface.withValues(alpha: 0.12)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? cs.onSurface : cs.onSurface.withValues(alpha: 0.54),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: cs.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientTile(Client client) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedClientId == client.id;

    final overLimit = client.creditLimit != null &&
        client.currentBalance > 0 &&
        client.currentBalance >= client.creditLimit!;
    final balanceColor = overLimit
        ? cs.error
        : client.currentBalance > 0
            ? cs.tertiary
            : cs.secondary;

    return GestureDetector(
      onTap: () => setState(() => _selectedClientId = client.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border(left: BorderSide(color: cs.secondary, width: 4))
              : null,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isSelected ? cs.secondary : cs.surfaceContainerHighest,
            child: Text(
              _initials(client.name),
              style: TextStyle(
                color: isSelected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            client.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
          ),
          subtitle: client.phone != null
              ? Text(client.phone!, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11))
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt(client.currentBalance)} MAD',
                style: TextStyle(color: balanceColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                client.creditLimit != null
                    ? 'Limit: ${client.creditLimit!.toStringAsFixed(0)}'
                    : 'No limit',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11),
              ),
            ],
          ),
          dense: true,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ─────────────────────────────────────────────────────────────
  //  RIGHT — CLIENT DETAILS
  // ─────────────────────────────────────────────────────────────

  Widget _buildDetails() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildStatsRow(),
        const SizedBox(height: 24),
        if (_selectedClientId != null)
          _buildClientProfile()
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 56, color: cs.onSurface.withValues(alpha: 0.24)),
                  const SizedBox(height: 16),
                  Text('Select a client', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a client from the list to view details',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final cs = Theme.of(context).colorScheme;
    final clientsAsync = ref.watch(clientsProvider);
    return clientsAsync.when(
      data: (clients) {
        final withBalance = clients.where((c) => c.currentBalance != 0).length;
        final outstanding = clients.fold<double>(0, (s, c) => s + c.currentBalance);
        final overLimit = clients.where((c) {
          if (c.creditLimit == null || c.creditLimit! <= 0) return c.currentBalance > 0;
          return c.currentBalance >= c.creditLimit!;
        }).length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _miniCard(cs, Icons.people_outline, 'TOTAL CLIENTS', '${clients.length}', cs.primary),
            _miniCard(cs, Icons.trending_up, 'WITH BALANCE', '$withBalance', cs.tertiary),
            _miniCard(cs, Icons.attach_money, 'OUTSTANDING', '${_fmt(outstanding)} MAD', cs.error),
            _miniCard(cs, Icons.shield_outlined, 'OVER LIMIT', '$overLimit', cs.error),
          ],
        );
      },
      loading: () => _statsRowPlaceholder(),
      error: (_, _) => _statsRowPlaceholder(),
    );
  }

  Widget _statsRowPlaceholder() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (_) => const SizedBox(width: 150, height: 62)),
    );
  }

  Widget _miniCard(ColorScheme cs, IconData icon, String title, String value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  CLIENT PROFILE + TRANSACTIONS
  // ─────────────────────────────────────────────────────────────

  Widget _buildClientProfile() {
    final clientsAsync = ref.watch(
      _showArchived ? archivedClientsProvider : clientsProvider,
    );

    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: clientsAsync.when(
        data: (clients) {
          final client = clients.where((c) => c.id == _selectedClientId).firstOrNull;
          if (client == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off, size: 48, color: cs.onSurface.withValues(alpha: 0.24)),
                  const SizedBox(height: 12),
                  Text('Client not found', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38))),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileCard(cs, client),
                const SizedBox(height: 20),
                _buildActionButtons(cs, client),
                const SizedBox(height: 20),
                _buildTransactionHistory(cs, client.id),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: cs.secondary)),
        error: (_, _) => Center(
          child: Text('Error loading client', style: TextStyle(color: cs.error)),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ColorScheme cs, Client client) {
    final overLimit = client.creditLimit != null &&
        client.currentBalance > 0 &&
        client.currentBalance >= client.creditLimit!;
    final borderColor = overLimit ? cs.error.withAlpha(150) : cs.onSurface.withValues(alpha: 0.24);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.surfaceContainerHighest,
                        child: Text(
                          _initials(client.name),
                          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                client.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              if (overLimit) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.error.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Over Limit Alert',
                                    style: TextStyle(
                                      color: cs.error.withValues(alpha: 0.75),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (client.phone != null) ...[
                        Icon(Icons.phone, size: 14, color: cs.onSurface.withValues(alpha: 0.38)),
                        const SizedBox(width: 4),
                        Text(client.phone!, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                        const SizedBox(width: 20),
                      ],
                      if (client.plateNumber != null) ...[
                        Icon(Icons.directions_car, size: 14, color: cs.onSurface.withValues(alpha: 0.38)),
                        const SizedBox(width: 4),
                        Text(client.plateNumber!, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13)),
                        const SizedBox(width: 20),
                      ],
                      Icon(Icons.security, size: 14, color: cs.onSurface.withValues(alpha: 0.38)),
                      const SizedBox(width: 4),
                      Text(
                        client.creditLimit != null
                            ? 'Credit Limit: ${client.creditLimit!.toStringAsFixed(0)} MAD'
                            : 'No credit limit',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),

              // Active balance display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ACTIVE BALANCE',
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.38), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmt(client.currentBalance)} MAD',
                      style: TextStyle(
                        fontSize: 22,
                        color: client.currentBalance > 0 ? cs.error : cs.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: cs.onSurface.withValues(alpha: 0.12), height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricItem(cs, 'TOTAL SALES', '${_fmt(client.currentBalance)} MAD', cs.onSurface),
              _metricItem(cs, 'TOTAL PAYMENTS', '0.00 MAD', cs.secondary),
              _metricItem(cs,
                'CREDIT USED (%)',
                client.creditLimit != null && client.creditLimit! > 0
                    ? '${((client.currentBalance / client.creditLimit!) * 100).toStringAsFixed(0)}%'
                    : 'N/A',
                client.creditLimit != null &&
                        client.creditLimit! > 0 &&
                        client.currentBalance >= client.creditLimit!
                    ? cs.error
                    : cs.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(ColorScheme cs, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.38), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme cs, Client client) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showRecordSaleDialog(client),
          icon: const Icon(Icons.trending_up, size: 18),
          label: const Text('RECORD SALE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.secondary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _showRecordPaymentDialog(client),
          icon: const Icon(Icons.trending_down, size: 18),
          label: const Text('RECORD PAYMENT'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.secondary,
            side: BorderSide(color: cs.secondary),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TRANSACTION HISTORY TABLE
  // ─────────────────────────────────────────────────────────────

  Widget _buildTransactionHistory(ColorScheme cs, String clientId) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Table header tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.12))),
            ),
            child: Row(
              children: [
                _tableTab(cs,
                  'Fuel / Sales',
                  count: ref.watch(clientSalesProvider(clientId)).whenOrNull(data: (l) => l.length) ?? 0,
                  isActive: _tableTabIndex == 0,
                  onTap: () => setState(() => _tableTabIndex = 0),
                ),
                _tableTab(cs,
                  'Payments Received',
                  count: ref.watch(clientPaymentsProvider(clientId)).whenOrNull(data: (l) => l.length) ?? 0,
                  isActive: _tableTabIndex == 1,
                  onTap: () => setState(() => _tableTabIndex = 1),
                ),
                _tableTab(cs,
                  'Outstanding Debts',
                  count: ref.watch(clientDebtsProvider(clientId)).whenOrNull(data: (l) => l.length) ?? 0,
                  isActive: _tableTabIndex == 2,
                  onTap: () => setState(() => _tableTabIndex = 2),
                ),
              ],
            ),
          ),
          // Table body
          SizedBox(
            height: 260,
            child: IndexedStack(
              index: _tableTabIndex,
              children: [
                _buildSalesTab(cs, clientId),
                _buildPaymentsTab(cs, clientId),
                _buildDebtsTab(cs, clientId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableTab(ColorScheme cs, String label, {required int count, required bool isActive, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive ? cs.secondary.withAlpha(30) : cs.onSurface.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? cs.secondary : cs.onSurface.withValues(alpha: 0.38),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTab(ColorScheme cs, String clientId) {
    final salesAsync = ref.watch(clientSalesProvider(clientId));
    return salesAsync.when(
      data: (sales) {
        if (sales.isEmpty) return _emptyTable(cs, 'No sales recorded');
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sales.length,
          separatorBuilder: (_, _) => Divider(color: cs.onSurface.withValues(alpha: 0.12), height: 1),
          itemBuilder: (_, i) {
            final sale = sales[i];
            final dateStr = DateFormat('dd/MM/yyyy').format(sale.timestamp);
            final typeStr = sale.saleType.value;
            return _transactionRow(cs,
              name: sale.driverName ?? sale.id.substring(0, 6).toUpperCase(),
              date: dateStr,
              subtitle: sale.vehiclePlate ?? 'N/A',
              badge: typeStr,
              badgeColor: typeStr == 'FUEL' ? cs.primary.withValues(alpha: 0.85) : cs.secondaryContainer,
              detail: sale.volume != null && sale.unitPrice != null
                  ? '${sale.volume!.toStringAsFixed(2)}L  ${_fmt(sale.unitPrice!)} MAD'
                  : '',
              total: '${_fmt(sale.totalPrice)} MAD',
              tag: typeStr == 'FUEL' ? 'Debt' : 'Sale',
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: cs.secondary)),
      error: (_, _) => _emptyTable(cs, 'Error loading sales'),
    );
  }

  Widget _buildPaymentsTab(ColorScheme cs, String clientId) {
    final paymentsAsync = ref.watch(clientPaymentsProvider(clientId));
    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) return _emptyTable(cs, 'No payments received');
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: payments.length,
          separatorBuilder: (_, _) => Divider(color: cs.onSurface.withValues(alpha: 0.12), height: 1),
          itemBuilder: (_, i) {
            final p = payments[i];
            final dateStr = DateFormat('dd/MM/yyyy').format(p.createdAt);
            final statusColor = p.status.isPending
                ? cs.tertiary
                : p.status.isSettled
                    ? cs.secondary
                    : cs.onSurface.withValues(alpha: 0.54);
            return _transactionRow(cs,
              name: p.checkNumber != null ? 'Check #${p.checkNumber}' : 'Cash Payment',
              date: dateStr,
              subtitle: p.notes ?? '',
              badge: p.status.value,
              badgeColor: statusColor,
              detail: p.checkBankName ?? '',
              total: '${_fmt(p.amount)} MAD',
              tag: p.status.isPending ? 'Pending' : p.status.value,
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: cs.secondary)),
      error: (_, _) => _emptyTable(cs, 'Error loading payments'),
    );
  }

  Widget _buildDebtsTab(ColorScheme cs, String clientId) {
    final debtsAsync = ref.watch(clientDebtsProvider(clientId));
    return debtsAsync.when(
      data: (debts) {
        if (debts.isEmpty) return _emptyTable(cs, 'No outstanding debts');
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: debts.length,
          separatorBuilder: (_, _) => Divider(color: cs.onSurface.withValues(alpha: 0.12), height: 1),
          itemBuilder: (_, i) {
            final d = debts[i];
            final dateStr = d.dueDate != null
                ? DateFormat('dd/MM/yyyy').format(d.dueDate!)
                : 'No due date';
            return _transactionRow(cs,
              name: d.driverName ?? 'Debt #${d.id.substring(0, 6).toUpperCase()}',
              date: dateStr,
              subtitle: d.vehiclePlate ?? 'N/A',
              badge: 'DEBT',
              badgeColor: cs.error,
              detail: '',
              total: '${_fmt(d.amount)} MAD',
              tag: 'Overdue',
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: cs.secondary)),
      error: (_, _) => _emptyTable(cs, 'Error loading debts'),
    );
  }

  Widget _emptyTable(ColorScheme cs, String message) {
    return Center(
      child: Text(message, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 14)),
    );
  }

  Widget _transactionRow(ColorScheme cs, {
    required String name,
    required String date,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required String detail,
    required String total,
    required String tag,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$date / $subtitle',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '• $badge',
              style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          if (detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(detail, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13)),
            ),
          const Spacer(),
          Text(
            total,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.24)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(tag, style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.38))),
          ),
          const SizedBox(width: 12),
          Icon(Icons.edit_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.24)),
          const SizedBox(width: 8),
          Icon(Icons.cancel_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.24)),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline, size: 16, color: cs.onSurface.withValues(alpha: 0.24)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  DIALOGS
  // ─────────────────────────────────────────────────────────────

  Future<void> _showRecordSaleDialog(Client client) async {
    final volumeCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '10.79');
    final driverCtrl = TextEditingController();
    final plateCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.trending_up, color: cs.secondary, size: 22),
              const SizedBox(width: 8),
              Text('Record Sale', style: TextStyle(color: cs.onSurface)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(cs, volumeCtrl, 'Volume (L)', Icons.opacity, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _dialogField(cs, priceCtrl, 'Unit Price (MAD)', Icons.attach_money, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _dialogField(cs, driverCtrl, 'Driver Name', Icons.person),
                const SizedBox(height: 12),
                _dialogField(cs, plateCtrl, 'Vehicle Plate', Icons.directions_car),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (volumeCtrl.text.isEmpty) return;
                await _saveSale(
                  client: client,
                  volume: double.tryParse(volumeCtrl.text) ?? 0,
                  unitPrice: double.tryParse(priceCtrl.text) ?? 0,
                  driverName: driverCtrl.text.trim(),
                  vehiclePlate: plateCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.secondary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Record Sale'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      volumeCtrl.dispose();
      priceCtrl.dispose();
      driverCtrl.dispose();
      plateCtrl.dispose();
    }
  }

  Future<void> _showRecordPaymentDialog(Client client) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.trending_down, color: cs.secondary, size: 22),
              const SizedBox(width: 8),
              Text('Record Payment', style: TextStyle(color: cs.onSurface)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(cs, amountCtrl, 'Amount (MAD)', Icons.attach_money, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _dialogField(cs, notesCtrl, 'Notes / Reference', Icons.notes),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountCtrl.text.isEmpty) return;
                await _savePayment(
                  client: client,
                  amount: double.tryParse(amountCtrl.text) ?? 0,
                  notes: notesCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.secondary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Record Payment'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      amountCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  Widget _dialogField(ColorScheme cs, TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
        prefixIcon: Icon(icon, color: cs.onSurface.withValues(alpha: 0.38), size: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.onSurface.withAlpha(25)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.secondary),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: cs.onSurface.withAlpha(10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _saveSale({
    required Client client,
    required double volume,
    required double unitPrice,
    required String driverName,
    required String vehiclePlate,
  }) async {
    final total = volume * unitPrice;
    final newBalance = client.currentBalance + total;
    final now = DateTime.now();

    final docRef = firestore.collection('sales').doc();
    await docRef.set({
      'id': docRef.id,
      'saleType': 'FUEL',
      'volume': volume,
      'unitPrice': unitPrice,
      'totalPrice': total,
      'driverName': driverName.isNotEmpty ? driverName : null,
      'vehiclePlate': vehiclePlate.isNotEmpty ? vehiclePlate : null,
      'clientId': client.id,
      'timestamp': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'isDeleted': false,
    });

    await firestore.collection('clients').doc(client.id).update({
      'currentBalance': newBalance,
    });
  }

  Future<void> _savePayment({
    required Client client,
    required double amount,
    required String notes,
  }) async {
    final newBalance = (client.currentBalance - amount).clamp(0, double.infinity);
    final now = DateTime.now();

    final docRef = firestore.collection('payments').doc();
    await docRef.set({
      'id': docRef.id,
      'amount': amount,
      'status': 'COMPLETED',
      'notes': notes.isNotEmpty ? notes : null,
      'clientId': client.id,
      'createdAt': Timestamp.fromDate(now),
      'isDeleted': false,
    });

    await firestore.collection('clients').doc(client.id).update({
      'currentBalance': newBalance,
    });
  }
}

// ────────────────────────────────────────────────────────────────
//  TOP HEADER WIDGET  (fuel prices, user, date/time)
// ────────────────────────────────────────────────────────────────

class _TopHeaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final timeStr = DateFormat('dd/MM HH:mm').format(now);

    return Container(
      height: 64,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _fuelTag('DIESEL', '11.96', cs),
          const SizedBox(width: 8),
          _fuelTag('SUPER', '12.25', cs),
          const Spacer(),
          Text('OUSSAID - ', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
          Text('SUPERUSER', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38))),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeStr,
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fuelTag(String fuel, String price, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: cs.secondary.withAlpha(60)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 14, color: cs.secondary.withAlpha(180)),
          const SizedBox(width: 4),
          Text(
            '$fuel $price',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
