import '../entities/gas_type.dart';

abstract class GasTypeRepository {
  Stream<List<GasType>> watchGasTypes();
  Future<GasType?> getGasType(String id);
  Future<void> createGasType(GasType gasType);
  Future<void> updateGasType(GasType gasType);
  Future<void> archiveGasType(String id);
  Future<void> restoreGasType(String id);
}
