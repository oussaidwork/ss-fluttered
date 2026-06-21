import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DatabaseDataSource _ds;

  DebtRepositoryImpl(this._ds);

  @override
  Stream<List<Debt>> watchDebtsByClient(String clientId) {
    return _ds.streamQuery(
      FirestorePaths.debts,
      filters: [
        QueryFilter(field: 'clientId', value: clientId),
        QueryFilter(field: 'isDeleted', value: false),
      ],
      orderByField: 'created',
      orderByDescending: true,
    ).map((snap) => snap.docs.map((d) => Debt.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Future<List<Debt>> getDebtsByClient(String clientId) async {
    final snap = await _ds.query(
      FirestorePaths.debts,
      filters: [
        QueryFilter(field: 'clientId', value: clientId),
        QueryFilter(field: 'isDeleted', value: false),
      ],
    );
    return snap.docs.map((d) => Debt.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList();
  }

  @override
  Future<void> createDebt(Debt debt) async {
    await _ds.setDoc(FirestorePaths.debts, debt.id, debt.toMap());
  }

  @override
  Future<void> updateDebt(Debt debt) async {
    await _ds.updateDoc(FirestorePaths.debts, debt.id, debt.toMap());
  }

  @override
  Future<void> archiveDebt(String id) async {
    await _ds.updateDoc(FirestorePaths.debts, id, {'isDeleted': true});
  }
}
