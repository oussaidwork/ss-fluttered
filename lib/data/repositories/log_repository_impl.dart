import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  LogRepositoryImpl._();
  static final _instance = LogRepositoryImpl._();
  factory LogRepositoryImpl() => _instance;

  @override
  Future<void> logAction({
    required String action,
    String? details,
    String? userId,
  }) async {
    final doc = firestore.collection(FirestorePaths.logs).doc();
    final entry = LogEntry(
      id: doc.id,
      action: action,
      details: details,
      timestamp: DateTime.now(),
      userId: userId,
    );
    await doc.set(entry.toMap());
  }

  @override
  Stream<List<LogEntry>> watchLogs() {
    return firestore
        .collection(FirestorePaths.logs)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => LogEntry.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<void> cleanupOldLogs({required DateTime before}) async {
    final snap = await firestore
        .collection(FirestorePaths.logs)
        .where('timestamp', isLessThan: Timestamp.fromDate(before))
        .limit(500)
        .get();

    final batch = firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }

    if (snap.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}

final logRepository = LogRepositoryImpl();
