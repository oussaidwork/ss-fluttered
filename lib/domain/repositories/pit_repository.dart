import '../entities/pit.dart';

abstract class PitRepository {
  Stream<List<Pit>> watchPits();
  Future<Pit?> getPit(String id);
  Future<void> createPit(Pit pit);
  Future<void> updatePit(Pit pit);
  Future<void> archivePit(String id);
  Future<void> restorePit(String id);
}
