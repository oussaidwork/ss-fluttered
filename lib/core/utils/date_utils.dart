import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Date and time formatting utilities.
class DateUtilsApp {
  DateUtilsApp._();

  /// Parses a Firestore [Timestamp], an ISO-8601 [String], or falls back
  /// to [fallback].
  static DateTime parseFirestoreDateTime(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    return fallback ?? DateTime.now();
  }

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _shortDateFormatter = DateFormat('MMM dd');
  static final DateFormat _fullDateFormatter = DateFormat('EEEE, MMMM dd, yyyy');

  /// Formats a [date] as 'yyyy-MM-dd'.
  static String formatDate(DateTime date) => _dateFormatter.format(date);

  /// Formats a [date] as 'HH:mm'.
  static String formatTime(DateTime date) => _timeFormatter.format(date);

  /// Formats a [date] as 'yyyy-MM-dd HH:mm'.
  static String formatDateTime(DateTime date) => _dateTimeFormatter.format(date);

  /// Formats a [date] as 'MMM dd' (e.g., "Jan 15").
  static String formatShortDate(DateTime date) => _shortDateFormatter.format(date);

  /// Formats a [date] as a full readable string.
  static String formatFullDate(DateTime date) => _fullDateFormatter.format(date);

  /// Returns a human-friendly relative time string (e.g., "2h ago", "3d ago").
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Returns true if [date] is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Returns the start of the day (midnight) for [date].
  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  /// Returns the end of the day (23:59:59.999) for [date].
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}