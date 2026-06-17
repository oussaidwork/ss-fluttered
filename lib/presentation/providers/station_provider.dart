import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/gas_type.dart';
import '../../domain/entities/pit.dart';
import '../../domain/entities/pump.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/payment_type.dart';

final gasTypesProvider = StreamProvider<List<GasType>>((ref) {
  return firestore.collection('gasTypes').where('isDeleted', isEqualTo: false).snapshots().map(
    (snap) => snap.docs.map((d) => GasType.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

final pitsProvider = StreamProvider<List<Pit>>((ref) {
  return firestore.collection('pits').where('isDeleted', isEqualTo: false).snapshots().map(
    (snap) => snap.docs.map((d) => Pit.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

final pumpsProvider = StreamProvider<List<Pump>>((ref) {
  return firestore.collection('pumps').where('isDeleted', isEqualTo: false).snapshots().map(
    (snap) => snap.docs.map((d) => Pump.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  return firestore.collection('products').where('isDeleted', isEqualTo: false).snapshots().map(
    (snap) => snap.docs.map((d) => Product.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

final servicesProvider = StreamProvider<List<Service>>((ref) {
  return firestore.collection('services').where('isDeleted', isEqualTo: false).snapshots().map(
    (snap) => snap.docs.map((d) => Service.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

final paymentTypesProvider = StreamProvider<List<PaymentType>>((ref) {
  return firestore.collection('paymentTypes').snapshots().map(
    (snap) => snap.docs.map((d) => PaymentType.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});
