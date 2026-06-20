import '../entities/log_entry.dart';

abstract class LogRepository {
  Future<void> logAction({
    required String action,
    String? details,
    String? userId,
  });

  Stream<List<LogEntry>> watchLogs();

  Future<void> cleanupOldLogs({required DateTime before});
}
