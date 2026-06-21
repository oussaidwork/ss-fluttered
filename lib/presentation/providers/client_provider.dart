import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sale.dart';
import '../../data/di/repository_providers.dart';

/// Active (non-deleted) clients stream.
final clientsProvider = StreamProvider<List<Client>>((ref) {
  return ref.watch(clientRepositoryProvider).watchClients();
});

/// Archived (deleted) clients stream.
final archivedClientsProvider = StreamProvider<List<Client>>((ref) {
  return ref
      .watch(databaseDataSourceProvider)
      .streamQuery(
        FirestorePaths.clients,
        filters: [QueryFilter(field: 'isDeleted', value: true)],
        orderByField: 'name',
      )
      .map(
        (snap) => snap.docs
            .map(
              (d) => Client.fromMap(
                d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id),
              ),
            )
            .toList(),
      );
});

/// Stream of sales for a specific client.
final clientSalesProvider = StreamProvider.family<List<Sale>, String>((
  ref,
  clientId,
) {
  return ref
      .watch(databaseDataSourceProvider)
      .streamQuery(
        FirestorePaths.sales,
        filters: [
          QueryFilter(field: 'clientId', value: clientId),
          QueryFilter(field: 'isDeleted', value: false),
        ],
        orderByField: 'timestamp',
        orderByDescending: true,
      )
      .map(
        (snap) => snap.docs
            .map(
              (d) => Sale.fromMap(
                d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id),
              ),
            )
            .toList(),
      );
});

/// Stream of payments for a specific client.
final clientPaymentsProvider = StreamProvider.family<List<Payment>, String>((
  ref,
  clientId,
) {
  return ref
      .watch(databaseDataSourceProvider)
      .streamQuery(
        FirestorePaths.payments,
        filters: [
          QueryFilter(field: 'clientId', value: clientId),
          QueryFilter(field: 'isDeleted', value: false),
        ],
        orderByField: 'createdAt',
        orderByDescending: true,
      )
      .map(
        (snap) => snap.docs
            .map(
              (d) => Payment.fromMap(
                d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id),
              ),
            )
            .toList(),
      );
});

/// Stream of debts for a specific client.
final clientDebtsProvider = StreamProvider.family<List<Debt>, String>((
  ref,
  clientId,
) {
  return ref.watch(debtRepositoryProvider).watchDebtsByClient(clientId);
});
