import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/database_datasource.dart';
import '../../data/datasource/firestore_datasource.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../data/repositories/client_fleet_repository_impl.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/gas_type_repository_impl.dart';
import '../../data/repositories/log_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/payment_type_repository_impl.dart';
import '../../data/repositories/permission_repository_impl.dart';
import '../../data/repositories/pit_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/pump_repository_impl.dart';
import '../../data/repositories/refill_repository_impl.dart';
import '../../data/repositories/sale_item_repository_impl.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../data/repositories/shift_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/client_fleet_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/gas_type_repository.dart';
import '../../domain/repositories/log_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/payment_type_repository.dart';
import '../../domain/repositories/permission_repository.dart';
import '../../domain/repositories/pit_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/pump_repository.dart';
import '../../domain/repositories/refill_repository.dart';
import '../../domain/repositories/sale_item_repository.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/services/json_export_service.dart';
import '../../core/services/json_import_service.dart';
import '../../core/services/import_service.dart';

// ─── DataSource ──────────────────────────────────────────────

final databaseDataSourceProvider = Provider<DatabaseDataSource>((ref) {
  return FirestoreDataSourceImpl();
});

// ─── Repositories ────────────────────────────────────────────

final gasTypeRepositoryProvider = Provider<GasTypeRepository>((ref) {
  return GasTypeRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final pitRepositoryProvider = Provider<PitRepository>((ref) {
  return PitRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final pumpRepositoryProvider = Provider<PumpRepository>((ref) {
  return PumpRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final paymentTypeRepositoryProvider = Provider<PaymentTypeRepository>((ref) {
  return PaymentTypeRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final clientFleetRepositoryProvider = Provider<ClientFleetRepository>((ref) {
  return ClientFleetRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final saleItemRepositoryProvider = Provider<SaleItemRepository>((ref) {
  return SaleItemRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final refillRepositoryProvider = Provider<RefillRepository>((ref) {
  return RefillRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final permissionRepositoryProvider = Provider<PermissionRepository>((ref) {
  return PermissionRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(databaseDataSourceProvider));
});

// ─── Services ──────────────────────────────────────────────

final jsonExportServiceProvider = Provider((ref) {
  return JsonExportService(ref.watch(databaseDataSourceProvider));
});

final jsonImportServiceProvider = Provider((ref) {
  return JsonImportService(ref.watch(databaseDataSourceProvider));
});

final importServiceProvider = Provider((ref) {
  return ImportService(ref.watch(databaseDataSourceProvider));
});
