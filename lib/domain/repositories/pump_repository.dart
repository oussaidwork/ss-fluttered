import '../entities/pump.dart';

abstract class PumpRepository {
  Stream<List<Pump>> watchPumps();
  Future<Pump?> getPump(String id);
  Future<void> createPump(Pump pump);
  Future<void> updatePump(Pump pump);
  Future<void> archivePump(String id);
  Future<void> restorePump(String id);
}
