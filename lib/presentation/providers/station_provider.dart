import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/gas_type.dart';
import '../../domain/entities/pit.dart';
import '../../domain/entities/pump.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/payment_type.dart';
import 'repository_providers.dart';

final gasTypesProvider = StreamProvider<List<GasType>>((ref) {
  return ref.watch(gasTypeRepositoryProvider).watchGasTypes();
});

final pitsProvider = StreamProvider<List<Pit>>((ref) {
  return ref.watch(pitRepositoryProvider).watchPits();
});

final pumpsProvider = StreamProvider<List<Pump>>((ref) {
  return ref.watch(pumpRepositoryProvider).watchPumps();
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchProducts();
});

final paymentTypesProvider = StreamProvider<List<PaymentType>>((ref) {
  return ref.watch(paymentTypeRepositoryProvider).watchPaymentTypes();
});
