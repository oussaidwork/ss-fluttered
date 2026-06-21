import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

class ClientImportPage extends StatefulWidget {
  const ClientImportPage({super.key});

  @override
  State<ClientImportPage> createState() => _ClientImportPageState();
}

// ──────────────────────────────────────────────────────────────
// Data models
// ──────────────────────────────────────────────────────────────

class _SaleEntry {
  DateTime? date;
  String fleet;
  String plate;
  String product;
  double? qty;
  double? price;
  double? subtotal;
  String paymentType;
  String ref;

  _SaleEntry({
    this.date,
    this.fleet = '',
    this.plate = '',
    this.product = '',
    this.qty,
    this.price,
    this.subtotal,
    this.paymentType = '',
    this.ref = '',
  });
}

class _PaymentEntry {
  double amount;
  String method;

  _PaymentEntry({this.amount = 0, this.method = ''});
}

class _ClientPreview {
  String name;
  String? clientId;
  bool isExisting;
  double existingBalance;
  List<_SaleEntry> sales;
  List<_PaymentEntry> payments;
  double totalSales;
  double totalPayments;

  _ClientPreview({
    required this.name,
    this.clientId,
    this.isExisting = false,
    this.existingBalance = 0,
    List<_SaleEntry>? sales,
    List<_PaymentEntry>? payments,
    this.totalSales = 0,
    this.totalPayments = 0,
  })  : sales = sales ?? [],
        payments = payments ?? [];

  double get balanceChange => totalSales - totalPayments;
  double get newBalance => existingBalance + balanceChange;
}

// ──────────────────────────────────────────────────────────────
// Page
// ──────────────────────────────────────────────────────────────

class _ClientImportPageState extends State<ClientImportPage> {
  bool _isLoading = false;
  bool _parsed = false;
  bool _importing = false;
  String? _error;
  Map<String, int>? _result;

  List<_ClientPreview> _clients = [];
  List<String> _warnings = [];

  // Resolved references
  Map<String, String> _gasTypeMap = {}; // "DIESEL" -> gas_type id
  Map<String, String> _paymentTypeMap = {}; // "DEBT" -> payment_type id, "CASH" -> id

  Future<void> _pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _parsed = false;
      _clients = [];
      _warnings = [];
    });

    try {
      await _loadReferenceData();
      final jsonStr = utf8.decode(result.files.single.bytes!);
      final clients = await _parseJson(jsonStr);
      setState(() {
        _clients = clients;
        _parsed = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReferenceData() async {
    // Load gas types by name
    final gasSnap = await firestore.collection('gas_types').where('isDeleted', isEqualTo: false).get();
    for (final doc in gasSnap.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').toUpperCase().trim();
      final id = doc.id;
      // Map both the full name and common abbreviations
      _gasTypeMap[name] = id;
      if (name.contains('DIESEL') || name.contains('GAZOLE') || name.contains('GASOIL')) {
        _gasTypeMap['DIESEL'] = id;
        _gasTypeMap['GASOIL'] = id;
        _gasTypeMap['GAZOLE'] = id;
      }
      if (name.contains('SUPER') || name.contains('ESSENCE')) {
        _gasTypeMap['SUPER'] = id;
        _gasTypeMap['ESSENCE'] = id;
      }
    }

    // Load payment types by name
    final paySnap = await firestore.collection('payment_types').where('isDeleted', isEqualTo: false).get();
    for (final doc in paySnap.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').toUpperCase().trim();
      _paymentTypeMap[name] = doc.id;
      // Common mappings
      if (name == 'CASH' || name == 'ESPÈCES' || name.contains('CASH')) _paymentTypeMap['CASH'] = doc.id;
      if (name == 'DEBT' || name == 'CREDIT' || name.contains('DEBT')) _paymentTypeMap['DEBT'] = doc.id;
      if (name == 'CARD' || name == 'CB' || name.contains('CARTE')) _paymentTypeMap['CARD'] = doc.id;
      if (name == 'CHECK' || name == 'CHÈQUE' || name.contains('CHEQUE')) _paymentTypeMap['CHECK'] = doc.id;
    }
  }

  Future<List<_ClientPreview>> _parseJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as List<dynamic>;
    final clients = <_ClientPreview>[];

    for (final entry in data) {
      final map = entry as Map<String, dynamic>;
      final name = (map['client_name'] as String? ?? '').trim();
      if (name.isEmpty) continue;

      // Look up existing client
      final existingSnap = await firestore
          .collection('clients')
          .where('name', isEqualTo: name)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      String? clientId;
      bool isExisting = false;
      double existingBalance = 0;

      if (existingSnap.docs.isNotEmpty) {
        clientId = existingSnap.docs.first.id;
        isExisting = true;
        final d = existingSnap.docs.first.data();
        existingBalance = (d['currentBalance'] as num?)?.toDouble() ?? 0;
      }

      final items = map['items'] as List<dynamic>? ?? [];
      final sales = <_SaleEntry>[];
      final payments = <_PaymentEntry>[];

      for (final item in items) {
        final i = item as Map<String, dynamic>;
        final type = (i['type'] as String? ?? '').toUpperCase().trim();

        if (type == 'SALE') {
          final qty = (i['qty'] as num?)?.toDouble();
          final price = (i['price'] as num?)?.toDouble();
          double? subtotal;
          if (qty != null && price != null) subtotal = qty * price;
          else subtotal = (i['subtotal'] as num?)?.toDouble();

          sales.add(_SaleEntry(
            date: _parseDate(i['date'] as String?),
            fleet: (i['fleet'] as String? ?? '').toString().trim(),
            plate: (i['plate'] as String? ?? '').toString().trim(),
            product: (i['product'] as String? ?? '').toString().trim(),
            qty: qty,
            price: price,
            subtotal: subtotal,
            paymentType: (i['payment'] as String? ?? '').toString().trim(),
            ref: (i['ref'] as String? ?? '').toString().trim(),
          ));
        } else if (type == 'PAYMENT') {
          payments.add(_PaymentEntry(
            amount: (i['amount'] as num?)?.toDouble() ?? 0,
            method: (i['payment'] as String? ?? '').toString().trim(),
          ));
        }
      }

      final totalSales = sales.fold(0.0, (sum, s) => sum! + (s.subtotal ?? 0));
      final totalPayments = payments.fold(0.0, (sum, p) => sum! + p.amount);

      clients.add(_ClientPreview(
        name: name,
        clientId: clientId,
        isExisting: isExisting,
        existingBalance: existingBalance,
        sales: sales,
        payments: payments,
        totalSales: totalSales,
        totalPayments: totalPayments,
      ));
    }

    return clients;
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  Future<void> _importToFirestore() async {
    if (_clients.isEmpty || _importing) return;
    setState(() => _importing = true);

    try {
      int clientsCreated = 0;
      int clientsUpdated = 0;
      int salesCount = 0;
      int saleItemsCount = 0;
      int paymentsCount = 0;

      for (final client in _clients) {
        final batch = firestore.batch();

        // 1. Create or update client
        final clientId = client.clientId ?? firestore.collection('clients').doc().id;
        if (!client.isExisting) clientsCreated++;
        else clientsUpdated++;

        batch.set(firestore.collection('clients').doc(clientId), {
          'name': client.name,
          'currentBalance': client.newBalance,
          'isDeleted': false,
          if (!client.isExisting) ...{
            'phone': null,
            'creditLimit': 0,
            'address': null,
            'email': null,
          },
        }, SetOptions(merge: true));

        // 2. Process sales
        for (final sale in client.sales) {
          final saleId = firestore.collection('sales').doc().id;
          final saleDate = sale.date ?? DateTime.now();

          // Get resolved references
          final gasTypeId = _gasTypeMap[sale.product.toUpperCase()];
          final paymentTypeId = _paymentTypeMap[sale.paymentType.toUpperCase()];

          // Create sale record
          batch.set(firestore.collection('sales').doc(saleId), {
            'id': saleId,
            'clientId': clientId,
            'totalPrice': sale.subtotal ?? 0,
            'paymentType': sale.paymentType,
            'paymentTypeId': paymentTypeId ?? '',
            'timestamp': Timestamp.fromDate(saleDate),
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'saleType': 'FUEL',
            'volume': sale.qty,
            'unitPrice': sale.price,
            'driverName': sale.fleet,
            'vehiclePlate': sale.plate,
            'notes': sale.ref,
            'isDeleted': false,
          });
          salesCount++;

          // Create sale item
          final itemId = firestore.collection('sale_items').doc().id;
          batch.set(firestore.collection('sale_items').doc(itemId), {
            'id': itemId,
            'saleId': saleId,
            'saleType': 'FUEL',
            'gasTypeId': gasTypeId ?? '',
            'volume': sale.qty ?? 0,
            'unitPrice': sale.price ?? 0,
            'lineTotal': sale.subtotal ?? 0,
            'quantity': sale.qty ?? 1,
            'driverName': sale.fleet,
            'vehiclePlate': sale.plate,
            'notes': sale.ref,
            'timestamp': Timestamp.fromDate(saleDate),
          });
          saleItemsCount++;

          // Create debt entry if payment type is DEBT
          if (sale.paymentType.toUpperCase() == 'DEBT' && (sale.subtotal ?? 0) > 0) {
            final debtId = firestore.collection('debts').doc().id;
            batch.set(firestore.collection('debts').doc(debtId), {
              'id': debtId,
              'clientId': clientId,
              'amount': sale.subtotal,
              'type': 'debt',
              'description': sale.ref,
              'date': Timestamp.fromDate(saleDate),
              'isDeleted': false,
            });
          }
        }

        // 3. Process payments
        for (final payment in client.payments) {
          if (payment.amount <= 0) continue;

          final payId = firestore.collection('payments').doc().id;
          final paymentTypeId = _paymentTypeMap[payment.method.toUpperCase()];

          batch.set(firestore.collection('payments').doc(payId), {
            'id': payId,
            'clientId': clientId,
            'amount': payment.amount,
            'paymentTypeId': paymentTypeId ?? '',
            'paymentMethod': payment.method,
            'status': 'COMPLETED',
            'isDeleted': false,
          });
          paymentsCount++;
        }

        await batch.commit();
      }

      setState(() {
        _result = {
          'clients_created': clientsCreated,
          'clients_updated': clientsUpdated,
          'sales': salesCount,
          'sale_items': saleItemsCount,
          'payments': paymentsCount,
        };
        _importing = false;
      });

      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import complete: $salesCount sales, $paymentsCount payments, $clientsCreated new clients'),
            backgroundColor: cs.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _importing = false;
      });
    }
  }

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────

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
              Icon(Icons.people, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Client Data Import',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const Spacer(),
              if (!_parsed && !_isLoading)
                ElevatedButton.icon(
                  onPressed: _pickAndParse,
                  icon: const Icon(Icons.file_upload, size: 18),
                  label: const Text('Select JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              if (_parsed && !_importing && _result == null)
                ElevatedButton.icon(
                  onPressed: _clients.any((c) => c.sales.isEmpty && c.payments.isEmpty) ? null : _importToFirestore,
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Import to Firestore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.secondary,
                    foregroundColor: cs.surface,
                    disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
                    disabledForegroundColor: cs.onSurface.withValues(alpha: 0.24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a JSON file with client sales and payments to preview and import.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            Expanded(
              child: Center(child: CircularProgressIndicator(color: cs.primary)),
            ),

          if (_error != null) _buildError(cs),

          if (_result != null) _buildResults(cs),

          if (_parsed && _result == null) Expanded(child: _buildPreview(cs)),

          if (!_parsed && !_isLoading && _error == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file, color: cs.onSurface.withValues(alpha: 0.24), size: 64),
                    const SizedBox(height: 16),
                    Text('Select a client data JSON file to begin',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.error.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildResults(ColorScheme cs) {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.secondary.withAlpha(60)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: cs.secondary, size: 48),
              const SizedBox(height: 16),
              Text('Import Complete!',
                  style: TextStyle(color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...(_result?.entries ?? []).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${e.key}: ',
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 14)),
                        Text('${e.value}',
                            style: TextStyle(
                                color: cs.secondary, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(' records', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 14)),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => setState(() {
                  _parsed = false;
                  _clients = [];
                  _result = null;
                  _error = null;
                }),
                child: const Text('Import Another'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              _summaryBadge('Clients', '${_clients.length}', cs,
                  _clients.where((c) => c.isExisting).length,
                  _clients.where((c) => !c.isExisting).length),
              const SizedBox(width: 24),
              _summaryBadge('Sales',
                  '${_clients.fold(0, (sum, c) => sum! + c.sales.length)}', cs),
              const SizedBox(width: 24),
              _summaryBadge('Payments',
                  '${_clients.fold(0, (sum, c) => sum! + c.payments.length)}', cs),
              const SizedBox(width: 24),
              _summaryBadge('Total Sales',
                  '${_clients.fold(0.0, (sum, c) => sum! + c.totalSales).toStringAsFixed(2)} MAD', cs),
              const SizedBox(width: 24),
              _summaryBadge('Total Payments',
                  '${_clients.fold(0.0, (sum, c) => sum! + c.totalPayments).toStringAsFixed(2)} MAD', cs),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: _clients.length,
            itemBuilder: (context, i) => _buildClientCard(_clients[i], cs),
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(_ClientPreview client, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: client.isExisting
                      ? cs.primary.withAlpha(40)
                      : cs.secondary.withAlpha(40),
                  child: Text(
                    client.name[0].toUpperCase(),
                    style: TextStyle(
                      color: client.isExisting ? cs.primary : cs.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.name,
                          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
                      Row(
                        children: [
                          Icon(
                            client.isExisting ? Icons.check_circle : Icons.add_circle,
                            size: 12,
                            color: client.isExisting ? cs.primary : cs.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            client.isExisting ? 'Existing client (ID: ${client.clientId?.substring(0, 8)}...)' : 'New client',
                            style: TextStyle(
                              fontSize: 11,
                              color: client.isExisting ? cs.primary : cs.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _miniStat('Sales', '${client.sales.length}', cs.primary),
                const SizedBox(width: 16),
                _miniStat('Payments', '${client.payments.length}', cs.tertiary),
                const SizedBox(width: 16),
                _miniStat('Balance', '${client.totalSales.toStringAsFixed(0)} MAD', cs.secondary),
              ],
            ),
          ),

          if (client.sales.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, size: 14, color: cs.onSurface.withValues(alpha: 0.38)),
                  const SizedBox(width: 6),
                  Text('Sales', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Total: ${client.totalSales.toStringAsFixed(2)} MAD',
                      style: TextStyle(color: cs.secondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('DATE', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                  Expanded(flex: 2, child: Text('FLEET', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                  Expanded(flex: 2, child: Text('PLATE', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                  Expanded(flex: 2, child: Text('PRODUCT', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                  Expanded(flex: 2, child: Text('QTY', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                  Expanded(flex: 2, child: Text('PRICE', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                  Expanded(flex: 3, child: Text('SUBTOTAL', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                  Expanded(flex: 2, child: Text('PAYMENT', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                  Expanded(flex: 2, child: Text('REF', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                ],
              ),
            ),
            ...client.sales.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(s.date != null ? '${s.date!.year}-${s.date!.month.toString().padLeft(2, '0')}-${s.date!.day.toString().padLeft(2, '0')}' : '-',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 11))),
                      Expanded(flex: 2, child: Text(s.fleet, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 11))),
                      Expanded(flex: 2, child: Text(s.plate, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 11, fontFamily: 'monospace'))),
                      Expanded(flex: 2, child: Text(s.product, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 11))),
                      Expanded(flex: 2, child: Text(s.qty?.toStringAsFixed(0) ?? '-', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 11))),
                      Expanded(flex: 2, child: Text(s.price?.toStringAsFixed(2) ?? '-', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 11))),
                      Expanded(flex: 3, child: Text(
                        s.subtotal?.toStringAsFixed(2) ?? '-',
                        style: TextStyle(
                          color: s.subtotal != null ? cs.secondary : cs.onSurface.withValues(alpha: 0.38),
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: s.subtotal != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      )),
                      Expanded(flex: 2, child: _paymentBadge(s.paymentType, cs)),
                      Expanded(flex: 2, child: Text(s.ref, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 11, fontFamily: 'monospace'))),
                    ],
                  ),
                )),
          ],

          if (client.payments.isNotEmpty) ...[
            Divider(color: cs.onSurface.withValues(alpha: 0.12), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.payments, size: 14, color: cs.onSurface.withValues(alpha: 0.38)),
                  const SizedBox(width: 6),
                  Text('Payments', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Total: ${client.totalPayments.toStringAsFixed(2)} MAD',
                      style: TextStyle(color: cs.tertiary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('AMOUNT', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                  Expanded(flex: 3, child: Text('METHOD', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 10))),
                ],
              ),
            ),
            ...client.payments.map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text('${p.amount.toStringAsFixed(2)} MAD',
                            style: TextStyle(color: cs.tertiary, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      ),
                      Expanded(flex: 3, child: _paymentBadge(p.method, cs)),
                    ],
                  ),
                )),
          ],

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Text('Balance Impact: ', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12)),
                Text(
                  '${client.balanceChange >= 0 ? '+' : ''}${client.balanceChange.toStringAsFixed(2)} MAD',
                  style: TextStyle(
                    color: client.balanceChange >= 0 ? cs.secondary : cs.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Text('New Balance: ', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12)),
                Text(
                  '${client.newBalance.toStringAsFixed(2)} MAD',
                  style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (client.isExisting) ...[
                  const SizedBox(width: 16),
                  Text('(was ${client.existingBalance.toStringAsFixed(2)} MAD)',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(String label, String value, ColorScheme cs, [int? existing, int? newCount]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
        if (existing != null && newCount != null)
          Text('$existing existing, $newCount new',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 10)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(color: color.withAlpha(150), fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _paymentBadge(String type, ColorScheme cs) {
    final isDebt = type.toUpperCase() == 'DEBT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDebt ? cs.tertiary.withAlpha(30) : cs.secondary.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: isDebt ? cs.tertiary : cs.secondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
