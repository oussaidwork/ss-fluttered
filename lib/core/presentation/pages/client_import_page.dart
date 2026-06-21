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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import complete: $salesCount sales, $paymentsCount payments, $clientsCreated new clients'),
            backgroundColor: const Color(0xFF84CC16),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Client Data Import',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              if (!_parsed && !_isLoading)
                ElevatedButton.icon(
                  onPressed: _pickAndParse,
                  icon: const Icon(Icons.file_upload, size: 18),
                  label: const Text('Select JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              if (_parsed && !_importing && _result == null)
                ElevatedButton.icon(
                  onPressed: _clients.any((c) => c.sales.isEmpty && c.payments.isEmpty) ? null : _importToFirestore,
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Import to Firestore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84CC16),
                    foregroundColor: const Color(0xFF0B1220),
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a JSON file with client sales and payments to preview and import.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0066CC))),
            ),

          if (_error != null) _buildError(),

          if (_result != null) _buildResults(),

          if (_parsed && _result == null) Expanded(child: _buildPreview()),

          if (!_parsed && !_isLoading && _error == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file, color: Colors.white24, size: 64),
                    SizedBox(height: 16),
                    Text('Select a client data JSON file to begin',
                        style: TextStyle(color: Colors.white38, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Expanded(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF84CC16).withAlpha(60)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF84CC16), size: 48),
              const SizedBox(height: 16),
              const Text('Import Complete!',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...(_result?.entries ?? []).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${e.key}: ',
                            style: const TextStyle(color: Colors.white54, fontSize: 14)),
                        Text('${e.value}',
                            style: const TextStyle(
                                color: Color(0xFF84CC16), fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(' records', style: const TextStyle(color: Colors.white54, fontSize: 14)),
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

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              _summaryBadge('Clients', '${_clients.length}',
                  _clients.where((c) => c.isExisting).length,
                  _clients.where((c) => !c.isExisting).length),
              const SizedBox(width: 24),
              _summaryBadge('Sales',
                  '${_clients.fold(0, (sum, c) => sum! + c.sales.length)}'),
              const SizedBox(width: 24),
              _summaryBadge('Payments',
                  '${_clients.fold(0, (sum, c) => sum! + c.payments.length)}'),
              const SizedBox(width: 24),
              _summaryBadge('Total Sales',
                  '${_clients.fold(0.0, (sum, c) => sum! + c.totalSales).toStringAsFixed(2)} MAD'),
              const SizedBox(width: 24),
              _summaryBadge('Total Payments',
                  '${_clients.fold(0.0, (sum, c) => sum! + c.totalPayments).toStringAsFixed(2)} MAD'),
            ],
          ),
        ),

        // Client cards
        Expanded(
          child: ListView.builder(
            itemCount: _clients.length,
            itemBuilder: (context, i) => _buildClientCard(_clients[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(_ClientPreview client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF111A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: client.isExisting
                      ? const Color(0xFF0066CC).withAlpha(40)
                      : const Color(0xFF84CC16).withAlpha(40),
                  child: Text(
                    client.name[0].toUpperCase(),
                    style: TextStyle(
                      color: client.isExisting ? const Color(0xFF0066CC) : const Color(0xFF84CC16),
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
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      Row(
                        children: [
                          Icon(
                            client.isExisting ? Icons.check_circle : Icons.add_circle,
                            size: 12,
                            color: client.isExisting ? const Color(0xFF0066CC) : const Color(0xFF84CC16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            client.isExisting ? 'Existing client (ID: ${client.clientId?.substring(0, 8)}...)' : 'New client',
                            style: TextStyle(
                              fontSize: 11,
                              color: client.isExisting ? const Color(0xFF0066CC) : const Color(0xFF84CC16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _miniStat('Sales', '${client.sales.length}', const Color(0xFF0066CC)),
                const SizedBox(width: 16),
                _miniStat('Payments', '${client.payments.length}', const Color(0xFFEAB308)),
                const SizedBox(width: 16),
                _miniStat('Balance', '${client.totalSales.toStringAsFixed(0)} MAD', const Color(0xFF84CC16)),
              ],
            ),
          ),

          // Sales table
          if (client.sales.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  const Text('Sales', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Total: ${client.totalSales.toStringAsFixed(2)} MAD',
                      style: const TextStyle(color: Color(0xFF84CC16), fontSize: 12)),
                ],
              ),
            ),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('DATE', style: TextStyle(color: Colors.white24, fontSize: 10))),
                  Expanded(flex: 2, child: Text('FLEET', style: TextStyle(color: Colors.white24, fontSize: 10))),
                  Expanded(flex: 2, child: Text('PLATE', style: TextStyle(color: Colors.white24, fontSize: 10))),
                  Expanded(flex: 2, child: Text('PRODUCT', style: TextStyle(color: Colors.white24, fontSize: 10))),
                  Expanded(flex: 2, child: Text('QTY', style: TextStyle(color: Colors.white24, fontSize: 10))),
                  Expanded(flex: 2, child: Text('PRICE', style: TextStyle(color: Colors.white24, fontSize: 10))),
                  Expanded(flex: 3, child: Text('SUBTOTAL', style: TextStyle(color: Colors.white24, fontSize: 10))),
                  Expanded(flex: 2, child: Text('PAYMENT', style: TextStyle(color: Colors.white24, fontSize: 10))),
                  Expanded(flex: 2, child: Text('REF', style: TextStyle(color: Colors.white24, fontSize: 10))),
                ],
              ),
            ),
            ...client.sales.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(s.date != null ? '${s.date!.year}-${s.date!.month.toString().padLeft(2, '0')}-${s.date!.day.toString().padLeft(2, '0')}' : '-',
                          style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      Expanded(flex: 2, child: Text(s.fleet, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      Expanded(flex: 2, child: Text(s.plate, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'))),
                      Expanded(flex: 2, child: Text(s.product, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      Expanded(flex: 2, child: Text(s.qty?.toStringAsFixed(0) ?? '-', style: const TextStyle(color: Colors.white54, fontSize: 11))),
                      Expanded(flex: 2, child: Text(s.price?.toStringAsFixed(2) ?? '-', style: const TextStyle(color: Colors.white54, fontSize: 11))),
                      Expanded(flex: 3, child: Text(
                        s.subtotal?.toStringAsFixed(2) ?? '-',
                        style: TextStyle(
                          color: s.subtotal != null ? const Color(0xFF84CC16) : Colors.white38,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: s.subtotal != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      )),
                      Expanded(flex: 2, child: _paymentBadge(s.paymentType)),
                      Expanded(flex: 2, child: Text(s.ref, style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'))),
                    ],
                  ),
                )),
          ],

          // Payments table
          if (client.payments.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.payments, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  const Text('Payments', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Total: ${client.totalPayments.toStringAsFixed(2)} MAD',
                      style: const TextStyle(color: Color(0xFFEAB308), fontSize: 12)),
                ],
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('AMOUNT', style: TextStyle(color: Colors.white24, fontSize: 10))),
                  Expanded(flex: 3, child: Text('METHOD', style: TextStyle(color: Colors.white24, fontSize: 10))),
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
                            style: const TextStyle(color: Color(0xFFEAB308), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      ),
                      Expanded(flex: 3, child: _paymentBadge(p.method)),
                    ],
                  ),
                )),
          ],

          // Balance footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF111A2E),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Text('Balance Impact: ', style: TextStyle(color: Colors.white38, fontSize: 12)),
                Text(
                  '${client.balanceChange >= 0 ? '+' : ''}${client.balanceChange.toStringAsFixed(2)} MAD',
                  style: TextStyle(
                    color: client.balanceChange >= 0 ? const Color(0xFF84CC16) : const Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                const Text('New Balance: ', style: TextStyle(color: Colors.white38, fontSize: 12)),
                Text(
                  '${client.newBalance.toStringAsFixed(2)} MAD',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (client.isExisting) ...[
                  const SizedBox(width: 16),
                  Text('(was ${client.existingBalance.toStringAsFixed(2)} MAD)',
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(String label, String value, [int? existing, int? newCount]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        if (existing != null && newCount != null)
          Text('$existing existing, $newCount new',
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
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

  Widget _paymentBadge(String type) {
    final isDebt = type.toUpperCase() == 'DEBT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDebt ? const Color(0xFFEAB308).withAlpha(30) : const Color(0xFF84CC16).withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: isDebt ? const Color(0xFFEAB308) : const Color(0xFF84CC16),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
