import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payment.dart';
import 'repository_providers.dart';

final pendingPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(paymentRepositoryProvider).watchPendingPayments();
});
