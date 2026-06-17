import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles Firestore-specific error formatting and recovery.
class FirestoreExceptionHandler {
  /// Converts a FirestoreException to a user-friendly message.
  static String formatError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'not-found':
          return 'The requested document was not found.';
        case 'already-exists':
          return 'A record with this identifier already exists.';
        case 'aborted':
          return 'The operation was aborted. Please try again.';
        case 'unavailable':
          return 'The service is temporarily unavailable. Please check your connection.';
        case 'deadline-exceeded':
          return 'The operation timed out. Please try again.';
        default:
          return 'A database error occurred: ${error.message}';
      }
    }
    return 'An unexpected error occurred: $error';
  }

  /// Retries a [future] operation up to [maxRetries] times with [delay] between attempts.
  static Future<T> retry<T>(
    Future<T> Function() future, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await future();
      } on FirebaseException catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
          await Future.delayed(delay * (attempt + 1));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Max retries exceeded');
  }
}