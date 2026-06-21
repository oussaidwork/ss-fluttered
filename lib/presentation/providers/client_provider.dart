import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/client.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sale.dart';
import 'repository_providers.dart';

/// Active (non-deleted) clients stream.
final clientsProvider = StreamProvider<List<Client>>((ref) {
  return ref.watch(clientRepositoryProvider).watchClients();
});

/// Archived (deleted) clients stream.
final archivedClientsProvider = StreamProvider<List<Client>>((ref) {
  // Uses direct query via repository — watchArchivedClients
  // For now, keep the archived clients as a filtered variant.
  // TODO: Add watchArchivedClients to ClientRepository interface.
  return Stream<List<Client>>.empty();
});

/// Stream of sales for a specific client.
final clientSalesProvider = StreamProvider.family<List<Sale>, String>((ref, clientId) {
  // SaleRepository does not have a per-client watch method yet.
  // We query via the datasource directly for now.
  // TODO: Add watchSalesByClient to SaleRepository.
  return Stream<List<Sale>>.empty();
});

/// Stream of payments for a specific client.
final clientPaymentsProvider = StreamProvider.family<List<Payment>, String>((ref, clientId) {
  // TODO: Add watchPaymentsByClient to PaymentRepository.
  return Stream<List<Payment>>.empty();
});

/// Stream of debts for a specific client.
final clientDebtsProvider = StreamProvider.family<List<Debt>, String>((ref, clientId) {
  return ref.watch(debtRepositoryProvider).watchDebtsByClient(clientId);
});
