import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/firestore/firestore_provider.dart';

/// Imports data from a JSON file into Firestore.
/// The JSON format matches the output of [JsonExportService].
///
/// Expected JSON structure:
/// ```json
/// {
///   "version": "1.0",
///   "collections": {
///     "gas_types": [...],
///     "pits": [...],
///     ...
///   }
/// }
/// ```
class JsonImportService {
  /// Parses a JSON string and imports all collections into Firestore.
  /// Returns a map of collection name → number of documents imported.
  Future<Map<String, int>> importJson(String jsonString) async {
    final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
    final collections = parsed['collections'] as Map<String, dynamic>?;

    if (collections == null) {
      throw FormatException('Invalid JSON format: missing "collections" key');
    }

    final results = <String, int>{};

    // Define import order: collections with dependencies go first
    const importOrder = [
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

    for (final name in importOrder) {
      final docs = collections[name] as List<dynamic>?;
      if (docs == null || docs.isEmpty) {
        results[name] = 0;
        continue;
      }

      final batch = firestore.batch();
      int count = 0;

      for (final docData in docs) {
        if (docData is! Map) continue;
        final map = Map<String, dynamic>.from(docData as Map);
        final docId = (map.remove('_docId') as String?) ?? firestore.collection(name).doc().id;

        // Remove undefined or null internal fields
        map.remove('_docId');

        final docRef = firestore.collection(name).doc(docId);
        batch.set(docRef, map, SetOptions(merge: true));
        count++;
      }

      await batch.commit();
      results[name] = count;
    }

    return results;
  }
}
