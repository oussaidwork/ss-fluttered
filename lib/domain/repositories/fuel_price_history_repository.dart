import '../entities/fuel_price_history.dart';

/// Repository for fuel price change history records.
abstract class FuelPriceHistoryRepository {
  /// Stream all price history entries, ordered by change date descending.
  Stream<List<FuelPriceHistory>> watchPriceHistory();

  /// Stream price history for a specific gas type.
  Stream<List<FuelPriceHistory>> watchPriceHistoryByGasType(String gasTypeId);

  /// Record a new fuel price change.
  Future<void> recordPriceChange(FuelPriceHistory entry);
}
