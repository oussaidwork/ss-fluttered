import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/firestore/firestore_provider.dart';

/// Generates professional A4 PDF reports from Firestore data.
class PdfReportService {
  PdfReportService._();

  static const _primaryColor = 0xFF0066CC;
  static const _accentColor = 0xFF84CC16;
  static const _dangerColor = 0xFFEF4444;

  static PdfColor c(int hex) => PdfColor.fromInt(hex);
  static PdfColor cA(int hex, double alpha) =>
      PdfColor.fromInt(((alpha * 255).round() << 24) | (hex & 0x00FFFFFF));

  // ──────────── Sales Report ────────────

  static Future<Uint8List> generateSalesReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final doc = pw.Document();
    final sales = await firestore
        .collection('sales')
        .where('isDeleted', isEqualTo: false)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('timestamp', descending: true)
        .get();

    double totalAmount = 0;
    final List<List<dynamic>> data = [];

    for (final snap in sales.docs) {
      final d = snap.data();
      final amount = (d['totalAmount'] as num?)?.toDouble() ?? 0;
      totalAmount += amount;
      data.add([
        _formatDate((d['timestamp'] as Timestamp?)?.toDate()),
        amount,
        d['paymentTypeId'] as String? ?? '--',
        (d['notes'] as String? ?? ''),
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(ctx, 'Sales Report'),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _buildDateRange(from, to),
          pw.SizedBox(height: 20),
          _buildSummaryRow('Total Sales', '${sales.docs.length} transactions',
              '${totalAmount.toStringAsFixed(2)} DA'),
          pw.SizedBox(height: 20),
          if (data.isEmpty)
            _buildEmptyState()
          else
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: data,
              headerCount: 0,
              headers: ['Date', 'Amount (DA)', 'Method', 'Notes'],
              headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: c(_primaryColor)),
              headerAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignments: {
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
              'Grand Total: ${totalAmount.toStringAsFixed(2)} DA',
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: c(_accentColor)),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ──────────── Shift Report ────────────

  static Future<Uint8List> generateShiftReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final doc = pw.Document();
    final shifts = await firestore
        .collection('work_shifts')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('startTime', descending: true)
        .get();

    double totalCash = 0;
    double totalCard = 0;
    int shiftCount = 0;
    final List<List<dynamic>> data = [];

    for (final snap in shifts.docs) {
      final d = snap.data();
      final expected = (d['expectedCash'] as num?)?.toDouble() ?? 0;
      final declared = (d['declaredCash'] as num?)?.toDouble() ?? 0;
      totalCash += declared;
      totalCard += (d['cardSales'] as num?)?.toDouble() ?? 0;
      shiftCount++;
      data.add([
        _formatDate((d['startTime'] as Timestamp?)?.toDate()),
        d['workerId'] as String? ?? '--',
        expected,
        declared,
        (declared - expected),
        d['status'] as String? ?? '--',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(ctx, 'Shift Summary Report'),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _buildDateRange(from, to),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _summaryBox('Shifts', '$shiftCount'),
              _summaryBox('Declared Cash', '${totalCash.toStringAsFixed(2)} DA'),
              _summaryBox('Card Sales', '${totalCard.toStringAsFixed(2)} DA'),
            ],
          ),
          pw.SizedBox(height: 20),
          if (data.isEmpty)
            _buildEmptyState()
          else
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: data,
              headers: ['Date', 'Worker', 'Expected', 'Declared', 'Diff', 'Status'],
              headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: c(_primaryColor)),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
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

  // ──────────── Debts Report ────────────

  static Future<Uint8List> generateDebtsReport() async {
    final doc = pw.Document();
    final debts = await firestore
        .collection('debts')
        .where('isDeleted', isEqualTo: false)
        .orderBy('created', descending: true)
        .get();

    final clientsSnap = await firestore.collection('clients').get();
    final clientNames = {
      for (final d in clientsSnap.docs)
        d.id: d.data()['name'] as String? ?? d.id
    };

    double totalDebts = 0;
    final List<List<dynamic>> data = [];
    for (final snap in debts.docs) {
      final d = snap.data();
      final amount = (d['amount'] as num?)?.toDouble() ?? 0;
      totalDebts += amount;
      data.add([
        clientNames[d['clientId'] as String?] ?? '--',
        d['driverName'] as String? ?? '--',
        d['vehiclePlate'] as String? ?? '--',
        amount,
        d['dueDate'] != null
            ? _formatDate((d['dueDate'] as Timestamp).toDate())
            : 'N/A',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(ctx, 'Outstanding Debts Report'),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.Text(
            'All outstanding debts as of ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 20),
          _buildSummaryRow('Total Outstanding', '${debts.docs.length} debts',
              '${totalDebts.toStringAsFixed(2)} DA'),
          pw.SizedBox(height: 20),
          if (data.isEmpty)
            _buildEmptyState()
          else
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: data,
              headers: ['Client', 'Driver', 'Plate', 'Amount (DA)', 'Due Date'],
              headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: c(_dangerColor)),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
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
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: c(_dangerColor)),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ──────────── Payments Report ────────────

  static Future<Uint8List> generatePaymentsReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final doc = pw.Document();
    final payments = await firestore
        .collection('payments')
        .where('isDeleted', isEqualTo: false)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('createdAt', descending: true)
        .get();

    final clientsSnap = await firestore.collection('clients').get();
    final clientNames = {
      for (final d in clientsSnap.docs)
        d.id: d.data()['name'] as String? ?? d.id
    };

    double totalCompleted = 0;
    double totalPending = 0;
    final List<List<dynamic>> data = [];
    for (final snap in payments.docs) {
      final d = snap.data();
      final amount = (d['amount'] as num?)?.toDouble() ?? 0;
      final status = d['status'] as String? ?? 'PENDING';
      if (status == 'COMPLETED') {
        totalCompleted += amount;
      } else {
        totalPending += amount;
      }
      data.add([
        _formatDate((d['createdAt'] as Timestamp?)?.toDate()),
        clientNames[d['clientId'] as String?] ?? '--',
        amount,
        status,
        d['paymentTypeId'] as String? ?? '--',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(ctx, 'Payments Settlement Report'),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _buildDateRange(from, to),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _summaryBox('Completed',
                  '${totalCompleted.toStringAsFixed(2)} DA'),
              _summaryBox(
                  'Pending', '${totalPending.toStringAsFixed(2)} DA'),
              _summaryBox(
                  'Total',
                  '${(totalCompleted + totalPending).toStringAsFixed(2)} DA'),
            ],
          ),
          pw.SizedBox(height: 20),
          if (data.isEmpty)
            _buildEmptyState()
          else
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: data,
              headers: ['Date', 'Client', 'Amount (DA)', 'Status', 'Method'],
              headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: c(_primaryColor)),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
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

  // ──────────── Pump Index Report ────────────

  static Future<Uint8List> generatePumpIndexReport() async {
    final doc = pw.Document();

    final pumpsSnap =
        await firestore.collection('pumps').where('isDeleted', isEqualTo: false).get();
    final pumps = pumpsSnap.docs;

    final List<List<dynamic>> data = [];
    for (final pumpDoc in pumps) {
      final pumpData = pumpDoc.data();
      final pumpName = pumpData['name'] as String? ?? pumpDoc.id;

      final spSnap = await firestore
          .collection('shift_pumps')
          .where('pumpId', isEqualTo: pumpDoc.id)
          .orderBy('shiftId', descending: true)
          .limit(1)
          .get();

      double lastCounter = 0;
      if (spSnap.docs.isNotEmpty) {
        lastCounter =
            (spSnap.docs.first.data()['endAnalogCounter'] as num?)?.toDouble() ?? 0;
      }

      data.add([
        pumpName,
        pumpData['pumpNumber']?.toString() ?? '--',
        lastCounter,
        (pumpData['isActive'] as bool? ?? false) ? 'Active' : 'Inactive',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(ctx, 'Pump Index Report'),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.Text(
            'Current pump readings as of ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 20),
          if (data.isEmpty)
            _buildEmptyState()
          else
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: data,
              headers: ['Pump Name', 'Number', 'Last Counter', 'Status'],
              headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: c(_primaryColor)),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
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

  // ──────────── Pit Refill Report ────────────

  static Future<Uint8List> generatePitRefillReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final doc = pw.Document();
    final refills = await firestore
        .collection('pit_refills')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('timestamp', descending: true)
        .get();

    double totalVolume = 0;
    double totalCost = 0;
    final List<List<dynamic>> data = [];

    for (final snap in refills.docs) {
      final d = snap.data();
      final volume = (d['volume'] as num?)?.toDouble() ?? 0;
      final cost = (d['totalCost'] as num?)?.toDouble() ?? 0;
      totalVolume += volume;
      totalCost += cost;
      data.add([
        _formatDate((d['timestamp'] as Timestamp?)?.toDate()),
        d['pitId'] as String? ?? '--',
        volume,
        cost,
        d['supplierName'] as String? ?? '--',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(ctx, 'Pit Refill Report'),
        footer: (ctx) => _buildFooter(ctx),
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
          if (data.isEmpty)
            _buildEmptyState()
          else
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: data,
              headers: ['Date', 'Pit', 'Volume', 'Cost (DA)', 'Supplier'],
              headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: c(_primaryColor)),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
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

  // ──────────── Fuel Price Report ────────────

  static Future<Uint8List> generateFuelPriceReport() async {
    final doc = pw.Document();
    final priceHistory = await firestore
        .collection('fuel_price_history')
        .orderBy('changedAt', descending: true)
        .limit(100)
        .get();

    final fuelSnap = await firestore.collection('gas_types').get();
    final fuelNames = {
      for (final d in fuelSnap.docs)
        d.id: d.data()['name'] as String? ?? d.id
    };

    final List<List<dynamic>> data = [];
    for (final snap in priceHistory.docs) {
      final d = snap.data();
      data.add([
        _formatDate((d['changedAt'] as Timestamp?)?.toDate()),
        fuelNames[d['gasTypeId'] as String?] ?? '--',
        (d['oldPrice'] as num?)?.toStringAsFixed(2) ?? '--',
        (d['newPrice'] as num?)?.toStringAsFixed(2) ?? '--',
        d['reason'] as String? ?? '--',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(ctx, 'Fuel Price History Report'),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.Text('Recent price changes (last 100 records)',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 20),
          if (data.isEmpty)
            _buildEmptyState()
          else
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: data,
              headers: ['Date', 'Fuel Type', 'Old Price', 'New Price', 'Reason'],
              headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: c(_primaryColor)),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
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

  // ──────────── Audit Log Report ────────────

  static Future<Uint8List> generateAuditLogReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final doc = pw.Document();
    final logs = await firestore
        .collection('logs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('timestamp', descending: true)
        .limit(200)
        .get();

    final List<List<dynamic>> data = [];
    for (final snap in logs.docs) {
      final d = snap.data();
      final details = d['details'] as String? ?? '';
      data.add([
        _formatDateTime((d['timestamp'] as Timestamp?)?.toDate()),
        d['userId'] as String? ?? '--',
        d['action'] as String? ?? '--',
        details.length > 40 ? '${details.substring(0, 40)}...' : details,
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(ctx, 'Audit Log Report'),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _buildDateRange(from, to),
          pw.SizedBox(height: 16),
          pw.Text('${logs.docs.length} entries found',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 16),
          if (data.isEmpty)
            _buildEmptyState()
          else
            pw.TableHelper.fromTextArray(
              context: ctx,
              data: data,
              headers: ['Timestamp', 'User', 'Action', 'Details'],
              headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: c(_primaryColor)),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
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

  // ──────────── Statistics Report ────────────

  static Future<Uint8List> generateStatisticsReport() async {
    final doc = pw.Document();

    final salesSnap =
        await firestore.collection('sales').where('isDeleted', isEqualTo: false).get();
    final clientsCount =
        (await firestore.collection('clients').where('isDeleted', isEqualTo: false).get())
            .docs.length;
    final shiftsSnap = await firestore.collection('work_shifts').get();
    final pumpsCount =
        (await firestore.collection('pumps').where('isDeleted', isEqualTo: false).get())
            .docs.length;
    final productsCount =
        (await firestore.collection('products').where('isDeleted', isEqualTo: false).get())
            .docs.length;

    double totalRevenue = 0;
    int totalSales = salesSnap.docs.length;
    for (final d in salesSnap.docs) {
      final data = d.data();
      totalRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0;
    }
    final avgSale = totalSales > 0 ? totalRevenue / totalSales : 0.0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => _buildHeader(ctx, 'Station Statistics Overview'),
        footer: (ctx) => _buildFooter(ctx),
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
          pw.Text('Revenue Breakdown',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: ctx,
            data: [
              ['Total Sales Count', '$totalSales'],
              ['Total Revenue', '${totalRevenue.toStringAsFixed(2)} DA'],
              ['Average Sale Amount', '${avgSale.toStringAsFixed(2)} DA'],
              ['Registered Clients', '$clientsCount'],
              ['Active Pumps', '$pumpsCount'],
              ['Products/Services', '$productsCount'],
              ['Shifts Completed', '${shiftsSnap.docs.length}'],
            ],
            headers: ['Metric', 'Value'],
            headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: c(_primaryColor)),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ──────────── Helper Widgets ────────────

  static pw.Widget _buildHeader(pw.Context ctx, String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF0066CC), width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            width: 36,
            height: 36,
            decoration: pw.BoxDecoration(
              color: c(_accentColor),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Center(
              child: pw.Text('SR',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColors.white)),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SS-RAGRAGA',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Station OS',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          ),
          pw.Spacer(),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: c(_primaryColor))),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
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
        color: cA(_primaryColor, 0.08),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Text('📅 ', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            'Period: ${_formatDate(from)} — ${_formatDate(to)}',
            style: pw.TextStyle(fontSize: 9, color: c(_primaryColor)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
      String label, String subtitle, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: cA(_accentColor, 0.08),
        border: pw.Border(
            left: pw.BorderSide(color: c(_accentColor), width: 4)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text(subtitle,
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ],
          ),
          pw.Spacer(),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: c(_accentColor))),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(String label, String value,
      {PdfColor? color}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        margin: const pw.EdgeInsets.only(right: 8),
        decoration: pw.BoxDecoration(
          color: cA(color?.toInt() ?? _primaryColor, 0.08),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 9, color: color ?? PdfColors.grey)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: color ?? PdfColors.black)),
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
          color: cA(_primaryColor, 0.08),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: cA(_primaryColor, 0.2)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            pw.SizedBox(height: 6),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: c(_primaryColor))),
          ],
        ),
      ),
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

  // ──────────── Helpers ────────────

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  static String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
