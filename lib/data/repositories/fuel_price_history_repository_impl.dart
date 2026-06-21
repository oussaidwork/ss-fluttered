import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/fuel_price_history.dart';
import '../../domain/repositories/fuel_price_history_repository.dart';

class FuelPriceHistoryRepositoryImpl implements FuelPriceHistoryRepository {
  final DatabaseDataSource _ds;

  FuelPriceHistoryRepositoryImpl(this._ds);

  @override
  Stream<List<FuelPriceHistory>> watchPriceHistory() {
    return _ds.streamQuery(
      FirestorePaths.fuelPriceHistory,
      orderByField: 'changedAt',
      orderByDescending: true,
    ).map(
      (snap) => snap.docs
          .map((d) => FuelPriceHistory.fromMap(
              d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id)))
          .toList(),
    );
  }

  @override
  Stream<List<FuelPriceHistory>> watchPriceHistoryByGasType(
      String gasTypeId) {
    return _ds.streamQuery(
      FirestorePaths.fuelPriceHistory,
      filters: [QueryFilter(field: 'gasTypeId', value: gasTypeId)],
      orderByField: 'changedAt',
      orderByDescending: true,
    ).map(
      (snap) => snap.docs
          .map((d) => FuelPriceHistory.fromMap(
              d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id)))
          .toList(),
    );
  }

  @override
  Future<void> recordPriceChange(FuelPriceHistory entry) async {
    await _ds.setDoc(
        FirestorePaths.fuelPriceHistory, entry.id, entry.toMap());
  }
}
