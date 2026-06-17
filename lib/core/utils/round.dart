import 'dart:math';

/// Decimal rounding utilities.
///
/// All monetary and volume values use round2: Math.round(n × 100) / 100.
class Round {
  /// Rounds [value] to 2 decimal places.
  static double round2(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  /// Rounds [value] to 2 decimal places, or returns null if [value] is null.
  static double? round2OrNull(double? value) {
    if (value == null) return null;
    return round2(value);
  }

  /// Rounds [value] to [places] decimal places.
  static double roundToPlaces(double value, int places) {
    final factor = pow(10, places).toDouble();
    return (value * factor).roundToDouble() / factor;
  }

  /// Checks if [a] and [b] are equal to 2 decimal places.
  static bool equalsRounded(double a, double b) {
    return round2(a) == round2(b);
  }
}