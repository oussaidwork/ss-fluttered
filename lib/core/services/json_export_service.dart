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

    final blob = html.Blob([payload], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'ss-ragrama_export_${DateTime.now().millisecondsSinceEpoch}.json',
      )
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
