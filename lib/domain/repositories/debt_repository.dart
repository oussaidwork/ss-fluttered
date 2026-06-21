import '../entities/debt.dart';

abstract class DebtRepository {
  Stream<List<Debt>> watchDebtsByClient(String clientId);
  Future<List<Debt>> getDebtsByClient(String clientId);
  Future<void> createDebt(Debt debt);
  Future<void> updateDebt(Debt debt);
  Future<void> archiveDebt(String id);
}
