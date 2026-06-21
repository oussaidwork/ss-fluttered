import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  final DatabaseDataSource _ds;

  LogRepositoryImpl(this._ds);

  @override
  Future<void> logAction({
    required String action,
    String? details,
    String? userId,
  }) async {
    final docId = _ds.docRef(FirestorePaths.logs, '').id;
    final entry = LogEntry(
      id: docId,
      action: action,
      details: details,
      timestamp: DateTime.now(),
      userId: userId,
    );
    await _ds.setDoc(FirestorePaths.logs, docId, entry.toMap());
  }

  @override
  Stream<List<LogEntry>> watchLogs() {
    return _ds.streamQuery(
      FirestorePaths.logs,
      orderByField: 'timestamp',
      orderByDescending: true,
      limit: 100,
    ).map(
      (snap) => snap.docs
          .map((d) => LogEntry.fromMap(d.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<void> cleanupOldLogs({required DateTime before}) async {
    final snap = await _ds.queryMulti(
      FirestorePaths.logs,
      filters: [
        QueryFilter(
          field: 'timestamp',
          value: Timestamp.fromDate(before),
          operator: FilterOperator.isLessThan,
        ),
      ],
      limit: 500,
    );

    final batch = _ds.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }

    if (snap.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}
