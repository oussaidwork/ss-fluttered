import 'dart:convert';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/firestore/firestore_provider.dart';

/// Exports all Firestore collections to a single downloadable JSON file.
class JsonExportService {
  /// All collection names to export, in dependency order (parents before children).
  static const List<String> collections = [
    'gas_types',
    'payment_types',
    'pits',
    'pumps',
    'products',
    'users',
    'clients',
    'client_fleet',
    'work_shifts',
    'shift_pumps',
    'sales',
    'sale_items',
    'payments',
    'expenses',
    'pit_refills',
    'refill_payments',
    'fuel_price_history',
    'debts',
    'salary_advances',
    'daily_summaries',
    'logs',
  ];

  /// Export all collections to a JSON map.
  Future<Map<String, List<Map<String, dynamic>>>> exportAll() async {
    final result = <String, List<Map<String, dynamic>>>{};

    for (final name in collections) {
      try {
        final snap = await firestore.collection(name).get();
        result[name] = snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['_docId'] = doc.id;
          return data;
        }).toList();
      } catch (_) {
        result[name] = [];
      }
    }

    return result;
  }

  /// Serialize export data to a JSON string.
  String toJsonString(Map<String, List<Map<String, dynamic>>> data) {
    return jsonEncode({
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'appName': 'SS-RAGRAGA Station OS',
      'collections': data,
    });
  }

  /// Download the export as a JSON file via the browser.
  Future<void> downloadJson() async {
    final data = await exportAll();
    final payload = toJsonString(data);

    _downloadString(payload, 'ss-ragrama_export_${DateTime.now().millisecondsSinceEpoch}.json');
  }

  /// Generate a blank template JSON with structure docs per collection.
  static String generateTemplate() {
    final template = <String, List<Map<String, dynamic>>>{
      'gas_types': [
        {
          'id': 'gas_gazole',
          'name': 'Gazole (Diesel)',
          'abbreviation': 'GZ',
          'price': 12.50,
          'unit': 'L',
          'isDeleted': false,
          'isActive': true,
        },
      ],
      'payment_types': [
        {
          'id': 'pmt_cash',
          'name': 'Cash',
          'code': 'CASH',
          'isDeleted': false,
          'isActive': true,
        },
      ],
      'pits': [
        {
          'id': 'pit_a',
          'name': 'Pit A',
          'capacity': 20000,
          'currentVolume': 18500,
          'gasTypeId': 'gas_gazole',
          'isDeleted': false,
          'isActive': true,
        },
      ],
      'pumps': [
        {
          'id': 'pump_1',
          'name': 'Pump 1',
          'pitId': 'pit_a',
          'analogCounter': 1584320,
          'isDeleted': false,
          'isActive': true,
        },
      ],
      'products': [
        {
          'id': 'prod_oil',
          'name': 'Engine Oil 10W40',
          'price': 65.00,
          'priceIn': 45.00,
          'priceOut': null,
          'stockQuantity': 48,
          'unit': 'pcs',
          'category': 'product',
          'isActive': true,
          'isDeleted': false,
        },
        {
          'id': 'serv_tire',
          'name': 'Tire Inflation',
          'price': 5.00,
          'priceIn': null,
          'priceOut': null,
          'stockQuantity': 0,
          'unit': 'service',
          'category': 'service',
          'isActive': true,
          'isDeleted': false,
        },
      ],
      'users': [
        {
          'id': 'user_admin',
          'fullName': 'Admin User',
          'email': 'admin@station.ma',
          'role': 'admin',
          'isDeleted': false,
          'isActive': true,
        },
      ],
      'clients': [
        {
          'id': 'client_001',
          'name': 'Client Name',
          'phone': '+212 6XX-XXXXXX',
          'email': 'client@example.ma',
          'address': 'Address here',
          'creditLimit': 50000,
          'balance': 0,
          'isDeleted': false,
          'isActive': true,
        },
      ],
      'client_fleet': [
        {
          'id': 'fleet_001',
          'clientId': 'client_001',
          'plateNumber': '12345-A-6',
          'driverName': 'Driver Name',
          'vehicleType': 'truck',
          'isActive': true,
          'isDeleted': false,
        },
      ],
      'work_shifts': [
        {
          'id': 'shift_001',
          'workerId': 'user_admin',
          'pitId': 'pit_a',
          'status': 'OPEN',
          'startTime': '2026-06-20T06:00:00.000',
          'endTime': '2026-06-20T14:00:00.000',
          'expectedCash': 5000.00,
          'actualCash': null,
          'isDeleted': false,
        },
      ],
      'shift_pumps': [
        {
          'id': 'sp_001',
          'shiftId': 'shift_001',
          'pumpId': 'pump_1',
          'startAnalogCounter': 1584320,
          'endAnalogCounter': null,
          'isDeleted': false,
        },
      ],
      'sales': [
        {
          'id': 'sale_001',
          'saleType': 'FUEL',
          'totalPrice': 150.00,
          'paymentTypeId': 'pmt_cash',
          'clientId': null,
          'shiftId': 'shift_001',
          'notes': null,
          'timestamp': '2026-06-20T08:30:00.000',
          'createdAt': '2026-06-20T08:30:00.000',
          'isDeleted': false,
        },
      ],
      'sale_items': [
        {
          'id': 'si_001',
          'saleId': 'sale_001',
          'saleType': 'FUEL',
          'gasTypeId': 'gas_gazole',
          'productId': null,
          'volume': 12.0,
          'unitPrice': 12.50,
          'lineTotal': 150.00,
          'quantity': null,
          'driverName': null,
          'vehiclePlate': null,
          'notes': null,
          'timestamp': '2026-06-20T08:30:00.000',
        },
      ],
      'payments': [
        {
          'id': 'pay_001',
          'saleId': 'sale_001',
          'clientId': null,
          'amount': 150.00,
          'paymentTypeId': 'pmt_cash',
          'status': 'COMPLETED',
          'timestamp': '2026-06-20T08:30:00.000',
          'isDeleted': false,
        },
      ],
      'expenses': [
        {
          'id': 'exp_001',
          'category': 'Utilities',
          'amount': 4500.00,
          'description': 'Monthly electricity bill',
          'timestamp': '2026-06-15T08:00:00.000',
          'paidBy': 'user_admin',
          'isDeleted': false,
        },
      ],
      'pit_refills': [
        {
          'id': 'pr_001',
          'pitId': 'pit_a',
          'gasTypeId': 'gas_gazole',
          'volume': 5000,
          'cost': 62500.00,
          'supplierName': 'Supplier SARL',
          'timestamp': '2026-06-18T10:00:00.000',
          'isDeleted': false,
        },
      ],
      'refill_payments': [
        {
          'id': 'rp_001',
          'refillId': 'pr_001',
          'amount': 62500.00,
          'paymentTypeId': 'pmt_cb',
          'timestamp': '2026-06-18T10:00:00.000',
          'isDeleted': false,
        },
      ],
      'fuel_price_history': [
        {
          'id': 'fph_001',
          'gasTypeId': 'gas_gazole',
          'oldPrice': 11.50,
          'newPrice': 12.50,
          'reason': 'Monthly adjustment',
          'timestamp': '2026-06-01T00:00:00.000',
        },
      ],
      'debts': [
        {
          'id': 'debt_001',
          'clientId': 'client_001',
          'saleId': 'sale_001',
          'amount': 150.00,
          'remaining': 150.00,
          'status': 'PENDING',
          'timestamp': '2026-06-20T08:30:00.000',
          'isDeleted': false,
        },
      ],
      'salary_advances': [
        {
          'id': 'sa_001',
          'workerId': 'user_admin',
          'amount': 500.00,
          'reason': 'Advance payment',
          'timestamp': '2026-06-10T09:00:00.000',
          'isDeleted': false,
        },
      ],
      'daily_summaries': [
        {
          'id': 'ds_001',
          'date': '2026-06-20T00:00:00.000',
          'totalRevenue': 12500.00,
          'totalSales': 85,
          'fuelVolume': 950.5,
          'productCount': 12,
          'averageSale': 147.06,
          'openShifts': 2,
          'pendingPayments': 3,
          'generatedAt': '2026-06-20T23:00:00.000',
        },
      ],
      'logs': [
        {
          'id': 'log_001',
          'collection': 'sales',
          'docId': 'sale_001',
          'eventType': 'CREATE',
          'userId': 'user_admin',
          'timestamp': '2026-06-20T08:30:00.000',
          'afterData': {},
        },
      ],
    };

    return jsonEncode({
      'version': '1.0',
      'appName': 'SS-RAGRAGA Station OS',
      'description': 'Replace the example records with your data. Keep the _docId field for idempotent re-imports.',
      'collections': template,
    });
  }

  /// Download a template JSON file with empty structure.
  static void downloadTemplate() {
    final payload = generateTemplate();
    _downloadString(payload, 'ss-ragrama_template.json');
  }

  /// Helper: trigger browser download of a string as a .json file.
  static void _downloadString(String content, String filename) {
    final blob = html.Blob([content], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
