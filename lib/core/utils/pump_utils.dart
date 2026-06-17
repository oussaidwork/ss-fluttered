/// Pump grouping and display utilities.
class PumpUtils {
  PumpUtils._();

  static const Map<String, String> groupLabels = {
    '1': 'Block A',
    '2': 'Block B',
    '3': 'Block C',
    '4': 'Block D',
  };

  /// Returns the display label for a pump group ID.
  static String groupLabel(String? groupId) => groupLabels[groupId] ?? 'Unassigned';

  /// Returns a color string for a given fuel type.
  static String getFuelColor(String? fuelTypeName) {
    switch (fuelTypeName?.toLowerCase()) {
      case 'diesel':
        return '#0066CC';
      case 'super':
        return '#84CC16';
      case 'premium':
        return '#F59E0B';
      default:
        return '#6B7280';
    }
  }
}