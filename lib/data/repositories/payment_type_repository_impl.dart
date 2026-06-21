import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/payment_type.dart';
import '../../domain/repositories/payment_type_repository.dart';

class PaymentTypeRepositoryImpl implements PaymentTypeRepository {
  final DatabaseDataSource _ds;

  PaymentTypeRepositoryImpl(this._ds);

  @override
  Stream<List<PaymentType>> watchPaymentTypes() {
    return _ds.streamQuery(
      FirestorePaths.paymentTypes,
    ).map((snap) => snap.docs.map((d) => PaymentType.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id))).toList());
  }

  @override
  Future<PaymentType?> getPaymentType(String id) async {
    final doc = await _ds.getDoc(FirestorePaths.paymentTypes, id);
    if (doc == null) return null;
    return PaymentType.fromMap(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> createPaymentType(PaymentType paymentType) async {
    await _ds.setDoc(FirestorePaths.paymentTypes, paymentType.id, paymentType.toMap());
  }

  @override
  Future<void> updatePaymentType(PaymentType paymentType) async {
    await _ds.updateDoc(FirestorePaths.paymentTypes, paymentType.id, paymentType.toMap());
  }
}
