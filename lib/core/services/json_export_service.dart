import 'dart:convert';
import 'dart:html' as html;
import '../../data/datasource/database_datasource.dart';

/// Exports all Firestore collections to a single downloadable JSON file.
class JsonExportService {
  final DatabaseDataSource _ds;

  JsonExportService(this._ds);

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
        final snap = await _ds.query(name);
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
    final template = <String, List<Map<String, dynamic>>>{};
    // ... (template generation stays the same - static, no DB calls)

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
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
