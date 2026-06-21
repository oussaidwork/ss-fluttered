import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasource/database_datasource.dart';
import '../../core/constants/firestore_paths.dart';

/// Generates professional A4 PDF reports from Firestore data.
class PdfReportService {
  PdfReportService._();

  static const _primaryColor = PdfColor(0.0, 0.4, 0.8);
  static const _accentColor = PdfColor(0.52, 0.8, 0.09);
  static const _dangerColor = PdfColor(0.94, 0.27, 0.27);
  static const _pageFormat = PdfPageFormat.a4;

  static Future<Uint8List> generateSalesReport({
    required DateTime from,
    required DateTime to,
    required DatabaseDataSource ds,
  }) async {
    final doc = pw.Document();
    final sales = await ds.query(
      FirestorePaths.sales,
      filters: [
        QueryFilter(field: 'isDeleted', value: false),
        QueryFilter(
          field: 'timestamp',
          value: Timestamp.fromDate(from),
          operator: FilterOperator.isGreaterThanOrEqualTo,
        ),
        QueryFilter(
          field: 'timestamp',
          value: Timestamp.fromDate(to),
          operator: FilterOperator.isLessThanOrEqualTo,
        ),
      ],
      orderByField: 'timestamp',
      orderByDescending: true,
    );

    double totalPrice = 0;
    int totalCount = 0;
    final List<Map<String, dynamic>> rows = [];

    for (final snap in sales.docs) {
      final data = snap.data() as Map<String, dynamic>;
      final amount = (data['totalPrice'] as num?)?.toDouble() ?? 0;
      totalPrice += amount;
      totalCount++;
      rows.add(data);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Sales Report'),
        footer: (ctx) => _buildFooter(),
        build: (ctx) => [
          _buildDateRange(from, to),
          pw.SizedBox(height: 20),
          _buildSummaryRow('Total Sales', '$totalCount transactions', '${totalPrice.toStringAsFixed(2)} DA'),
          pw.SizedBox(height: 20),
          if (rows.isEmpty)
            _buildEmptyState()
          else
            _buildTable(
              headers: ['Date', 'Amount (DA)', 'Method', 'Notes'],
              rows: rows.map((r) => [
                _formatDate((r['timestamp'] as Timestamp?)?.toDate()),
                (r['totalPrice'] as num?)?.toStringAsFixed(2) ?? '0.00',
                r['paymentTypeId'] as String? ?? '--',
                (r['notes'] as String? ?? '').length > 30
                    ? '${(r['notes'] as String).substring(0, 30)}...'
                    : (r['notes'] as String? ?? ''),
              ]).toList(),
              alignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
              },
            ),
          pw.SizedBox(height: 20),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Grand Total: ${totalPrice.toStringAsFixed(2)} DA',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _accentColor),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateShiftReport({
    required DateTime from,
    required DateTime to,
    required DatabaseDataSource ds,
  }) async {
    final doc = pw.Document();
    final shifts = await ds.query(
      FirestorePaths.workShifts,
      filters: [
        QueryFilter(
          field: 'startTime',
          value: Timestamp.fromDate(from),
          operator: FilterOperator.isGreaterThanOrEqualTo,
        ),
        QueryFilter(
          field: 'startTime',
          value: Timestamp.fromDate(to),
          operator: FilterOperator.isLessThanOrEqualTo,
        ),
      ],
      orderByField: 'startTime',
      orderByDescending: true,
    );

    double totalCash = 0;
    int shiftCount = 0;
    final rows = <List<String>>[];

    for (final snap in shifts.docs) {
      final data = snap.data() as Map<String, dynamic>;
      final expected = (data['expectedCash'] as num?)?.toDouble() ?? 0;
      final declared = (data['actualCash'] as num?)?.toDouble() ?? 0;
      totalCash += declared;
      shiftCount++;
      rows.add([
        _formatDate((data['startTime'] as Timestamp?)?.toDate()),
        data['workerId'] as String? ?? '--',
        expected.toStringAsFixed(2),
        declared.toStringAsFixed(2),
        (declared - expected).toStringAsFixed(2),
        data['status'] as String? ?? '--',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Shift Summary Report'),
        footer: (ctx) => _buildFooter(),
        build: (ctx) => [
          _buildDateRange(from, to),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _summaryBox('Shifts', '$shiftCount'),
              _summaryBox('Declared Cash', '${totalCash.toStringAsFixed(2)} DA'),
            ],
          ),
          pw.SizedBox(height: 20),
          if (rows.isEmpty)
            _buildEmptyState()
          else
            _buildTable(
              headers: ['Date', 'Worker', 'Expected', 'Declared', 'Diff', 'Status'],
              rows: rows,
              alignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerLeft,
              },
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateDebtsReport({required DatabaseDataSource ds}) async {
    final doc = pw.Document();
    final debts = await ds.query(
      FirestorePaths.debts,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
      orderByField: 'created',
      orderByDescending: true,
    );

    final clientsSnap = await ds.query(FirestorePaths.clients);
    final clientNames = {for (final d in clientsSnap.docs) d.id: (d.data() as Map<String, dynamic>)['name'] as String? ?? d.id};

    double totalDebts = 0;
    final rows = <List<String>>[];
    for (final snap in debts.docs) {
      final data = snap.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      totalDebts += amount;
      rows.add([
        clientNames[data['clientId'] as String?] ?? '--',
        data['driverName'] as String? ?? '--',
        data['vehiclePlate'] as String? ?? '--',
        amount.toStringAsFixed(2),
        data['dueDate'] != null
            ? _formatDate((data['dueDate'] as Timestamp).toDate())
            : 'N/A',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Outstanding Debts Report'),
        footer: (ctx) => _buildFooter(),
        build: (ctx) => [
          pw.Text('All outstanding debts as of ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 20),
          _buildSummaryRow('Total Outstanding', '${debts.docs.length} debts', '${totalDebts.toStringAsFixed(2)} DA'),
          pw.SizedBox(height: 20),
          if (rows.isEmpty)
            _buildEmptyState()
          else
            _buildTable(
              headers: ['Client', 'Driver', 'Plate', 'Amount (DA)', 'Due Date'],
              rows: rows,
              alignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
              },
            ),
          pw.SizedBox(height: 20),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total Outstanding: ${totalDebts.toStringAsFixed(2)} DA',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _dangerColor),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generatePaymentsReport({
    required DateTime from,
    required DateTime to,
    required DatabaseDataSource ds,
  }) async {
    final doc = pw.Document();
    final payments = await ds.query(
      FirestorePaths.payments,
      filters: [
        QueryFilter(field: 'isDeleted', value: false),
        QueryFilter(
          field: 'createdAt',
          value: Timestamp.fromDate(from),
          operator: FilterOperator.isGreaterThanOrEqualTo,
        ),
        QueryFilter(
          field: 'createdAt',
          value: Timestamp.fromDate(to),
          operator: FilterOperator.isLessThanOrEqualTo,
        ),
      ],
      orderByField: 'createdAt',
      orderByDescending: true,
    );

    final clientsSnap = await ds.query(FirestorePaths.clients);
    final clientNames = {for (final d in clientsSnap.docs) d.id: (d.data() as Map<String, dynamic>)['name'] as String? ?? d.id};

    double totalCompleted = 0;
    double totalPending = 0;
    final rows = <List<String>>[];
    for (final snap in payments.docs) {
      final data = snap.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final status = data['status'] as String? ?? 'PENDING';
      if (status == 'COMPLETED') {
        totalCompleted += amount;
      } else {
        totalPending += amount;
      }
      rows.add([
        _formatDate((data['createdAt'] as Timestamp?)?.toDate()),
        clientNames[data['clientId'] as String?] ?? '--',
        amount.toStringAsFixed(2),
        status,
        data['paymentTypeId'] as String? ?? '--',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Payments Settlement Report'),
        footer: (ctx) => _buildFooter(),
        build: (ctx) => [
          _buildDateRange(from, to),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _summaryBox('Completed', '${totalCompleted.toStringAsFixed(2)} DA', color: _accentColor),
              _summaryBox('Pending', '${totalPending.toStringAsFixed(2)} DA', color: _dangerColor),
              _summaryBox('Total', '${(totalCompleted + totalPending).toStringAsFixed(2)} DA'),
            ],
          ),
          pw.SizedBox(height: 20),
          if (rows.isEmpty)
            _buildEmptyState()
          else
            _buildTable(
              headers: ['Date', 'Client', 'Amount (DA)', 'Status', 'Method'],
              rows: rows,
              alignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
              },
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generatePumpIndexReport({required DatabaseDataSource ds}) async {
    final doc = pw.Document();
    final pumpsSnap = await ds.query(
      FirestorePaths.pumps,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    );

    final rows = <List<String>>[];
    for (final pumpDoc in pumpsSnap.docs) {
      final pumpData = pumpDoc.data() as Map<String, dynamic>;
      final pumpName = pumpData['name'] as String? ?? pumpDoc.id;

      final spSnap = await ds.query(
        FirestorePaths.shiftPumps,
        filters: [QueryFilter(field: 'pumpId', value: pumpDoc.id)],
        orderByField: 'shiftId',
        orderByDescending: true,
        limit: 1,
      );

      double lastCounter = 0;
      if (spSnap.docs.isNotEmpty) {
        lastCounter = ((spSnap.docs.first.data() as Map<String, dynamic>?)?['endAnalogCounter'] as num?)?.toDouble() ?? 0;
      }

      rows.add([
        pumpName,
        pumpData['groupId']?.toString() ?? '--',
        lastCounter.toStringAsFixed(1),
        (pumpData['isActive'] as bool? ?? false) ? 'Active' : 'Inactive',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Pump Index Report'),
        footer: (ctx) => _buildFooter(),
        build: (ctx) => [
          pw.Text('Current pump readings as of ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 20),
          if (rows.isEmpty)
            _buildEmptyState()
          else
            _buildTable(
              headers: ['Pump Name', 'Group', 'Last Counter', 'Status'],
              rows: rows,
              alignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
              },
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generatePitRefillReport({
    required DateTime from,
    required DateTime to,
    required DatabaseDataSource ds,
  }) async {
    final doc = pw.Document();
    final refills = await ds.query(
      FirestorePaths.pitRefills,
      filters: [
        QueryFilter(
          field: 'timestamp',
          value: Timestamp.fromDate(from),
          operator: FilterOperator.isGreaterThanOrEqualTo,
        ),
        QueryFilter(
          field: 'timestamp',
          value: Timestamp.fromDate(to),
          operator: FilterOperator.isLessThanOrEqualTo,
        ),
      ],
      orderByField: 'timestamp',
      orderByDescending: true,
    );

    double totalVolume = 0;
    double totalCost = 0;
    final rows = <List<String>>[];

    for (final snap in refills.docs) {
      final data = snap.data() as Map<String, dynamic>;
      final volume = (data['volume'] as num?)?.toDouble() ?? 0;
      final cost = (data['totalCost'] as num?)?.toDouble() ?? 0;
      totalVolume += volume;
      totalCost += cost;
      rows.add([
        _formatDate((data['timestamp'] as Timestamp?)?.toDate()),
        data['pitId'] as String? ?? '--',
        '${volume.toStringAsFixed(1)} L',
        cost.toStringAsFixed(2),
        data['supplierName'] as String? ?? '--',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Pit Refill Report'),
        footer: (ctx) => _buildFooter(),
        build: (ctx) => [
          _buildDateRange(from, to),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _summaryBox('Refills', '${refills.docs.length}'),
              _summaryBox('Total Volume', '${totalVolume.toStringAsFixed(1)} L'),
              _summaryBox('Total Cost', '${totalCost.toStringAsFixed(2)} DA'),
            ],
          ),
          pw.SizedBox(height: 20),
          if (rows.isEmpty)
            _buildEmptyState()
          else
            _buildTable(
              headers: ['Date', 'Pit', 'Volume', 'Cost (DA)', 'Supplier'],
              rows: rows,
              alignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
              },
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateFuelPriceReport({required DatabaseDataSource ds}) async {
    final doc = pw.Document();
    final priceHistory = await ds.query(
      FirestorePaths.fuelPriceHistory,
      orderByField: 'changedAt',
      orderByDescending: true,
      limit: 100,
    );

    final fuelSnap = await ds.query(FirestorePaths.gasTypes);
    final fuelNames = {for (final d in fuelSnap.docs) d.id: (d.data() as Map<String, dynamic>)['name'] as String? ?? d.id};

    final rows = <List<String>>[];
    for (final snap in priceHistory.docs) {
      final data = snap.data() as Map<String, dynamic>;
      rows.add([
        _formatDate((data['changedAt'] as Timestamp?)?.toDate()),
        fuelNames[data['gasTypeId'] as String?] ?? '--',
        (data['oldPriceIn'] as num?)?.toStringAsFixed(2) ?? '--',
        (data['newPriceIn'] as num?)?.toStringAsFixed(2) ?? '--',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Fuel Price History Report'),
        footer: (ctx) => _buildFooter(),
        build: (ctx) => [
          pw.Text('Recent price changes (last 100 records)',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 20),
          if (rows.isEmpty)
            _buildEmptyState()
          else
            _buildTable(
              headers: ['Date', 'Fuel Type', 'Old Price In', 'New Price In'],
              rows: rows,
              alignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateAuditLogReport({
    required DateTime from,
    required DateTime to,
    required DatabaseDataSource ds,
  }) async {
    final doc = pw.Document();
    final logs = await ds.query(
      FirestorePaths.logs,
      filters: [
        QueryFilter(
          field: 'timestamp',
          value: Timestamp.fromDate(from),
          operator: FilterOperator.isGreaterThanOrEqualTo,
        ),
        QueryFilter(
          field: 'timestamp',
          value: Timestamp.fromDate(to),
          operator: FilterOperator.isLessThanOrEqualTo,
        ),
      ],
      orderByField: 'timestamp',
      orderByDescending: true,
      limit: 200,
    );

    final rows = <List<String>>[];
    for (final snap in logs.docs) {
      final data = snap.data() as Map<String, dynamic>;
      rows.add([
        _formatDateTime((data['timestamp'] as Timestamp?)?.toDate()),
        data['userId'] as String? ?? '--',
        data['action'] as String? ?? '--',
        (data['details'] as String? ?? '').length > 40
            ? '${(data['details'] as String).substring(0, 40)}...'
            : (data['details'] as String? ?? ''),
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Audit Log Report'),
        footer: (ctx) => _buildFooter(),
        build: (ctx) => [
          _buildDateRange(from, to),
          pw.SizedBox(height: 16),
          pw.Text('${logs.docs.length} entries found',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 16),
          if (rows.isEmpty)
            _buildEmptyState()
          else
            _buildTable(
              headers: ['Timestamp', 'User', 'Action', 'Details'],
              rows: rows,
              alignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
              },
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateStatisticsReport({required DatabaseDataSource ds}) async {
    final doc = pw.Document();
    final salesSnap = await ds.query(
      FirestorePaths.sales,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    );
    final clientsCount = (await ds.query(
      FirestorePaths.clients,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    )).docs.length;
    final shiftsSnap = await ds.query(FirestorePaths.workShifts);
    final pumpsCount = (await ds.query(
      FirestorePaths.pumps,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    )).docs.length;
    final productsCount = (await ds.query(
      FirestorePaths.products,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
    )).docs.length;

    double totalRevenue = 0;
    int totalSales = salesSnap.docs.length;
    double avgSale = 0;
    for (final d in salesSnap.docs) {
      final data = d.data() as Map<String, dynamic>;
      totalRevenue += (data['totalPrice'] as num?)?.toDouble() ?? 0;
    }
    if (totalSales > 0) avgSale = totalRevenue / totalSales;

    doc.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader('Station Statistics Overview'),
        footer: (ctx) => _buildFooter(),
        build: (ctx) => [
          pw.Text('Aggregate metrics as of ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              _statBox('Total Sales', '$totalSales'),
              _statBox('Total Revenue', '${totalRevenue.toStringAsFixed(2)} DA'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _statBox('Avg Sale', '${avgSale.toStringAsFixed(2)} DA'),
              _statBox('Clients', '$clientsCount'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _statBox('Shifts', '${shiftsSnap.docs.length}'),
              _statBox('Pumps', '$pumpsCount'),
              _statBox('Products', '$productsCount'),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text('Revenue Breakdown', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildTable(
            headers: ['Metric', 'Value'],
            rows: [
              ['Total Sales Count', '$totalSales'],
              ['Total Revenue', '${totalRevenue.toStringAsFixed(2)} DA'],
              ['Average Sale Amount', '${avgSale.toStringAsFixed(2)} DA'],
              ['Registered Clients', '$clientsCount'],
              ['Active Pumps', '$pumpsCount'],
              ['Products/Services', '$productsCount'],
              ['Shifts Completed', '${shiftsSnap.docs.length}'],
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ──────────── Helper widgets ────────────

  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primaryColor, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            width: 36,
            height: 36,
            decoration: pw.BoxDecoration(
              color: _accentColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Center(
              child: pw.Text('SR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.white)),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SS-RAGRAGA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Station OS', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          ),
          pw.Spacer(),
          pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        children: [
          pw.Text(
            'Generated: ${_formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
          ),
          pw.Spacer(),
          pw.Text(
            'SS-RAGRAGA Station OS',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDateRange(DateTime from, DateTime to) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor(0.94, 0.96, 1.0),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'Period: ${_formatDate(from)} — ${_formatDate(to)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String subtitle, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor(0.97, 1.0, 0.94),
        border: pw.Border(left: pw.BorderSide(color: _accentColor, width: 4)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ],
          ),
          pw.Spacer(),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _accentColor)),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(String label, String value, {PdfColor? color}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        margin: const pw.EdgeInsets.only(right: 8),
        decoration: pw.BoxDecoration(
          color: color ?? _primaryColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        margin: const pw.EdgeInsets.only(right: 8),
        decoration: pw.BoxDecoration(
          color: PdfColor(0.95, 0.97, 1.0),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColor(0.8, 0.85, 0.95)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            pw.SizedBox(height: 6),
            pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTable({
    required List<String> headers,
    required List<List<String>> rows,
    Map<int, pw.Alignment>? alignments,
  }) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: _primaryColor),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: alignments ?? {},
      headers: headers,
      data: rows,
    );
  }

  static pw.Widget _buildEmptyState() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Center(
        child: pw.Text('No data available for the selected period.',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
      ),
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
