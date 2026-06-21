import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasource/database_datasource.dart';
import '../datasource/firestore_datasource.dart';
import '../repositories/auth_repository_impl.dart';
import '../repositories/client_repository_impl.dart';
import '../repositories/client_fleet_repository_impl.dart';
import '../repositories/dashboard_repository_impl.dart';
import '../repositories/debt_repository_impl.dart';
import '../repositories/expense_repository_impl.dart';
import '../repositories/fuel_price_history_repository_impl.dart';
import '../repositories/gas_type_repository_impl.dart';
import '../repositories/log_repository_impl.dart';
import '../repositories/payment_repository_impl.dart';
import '../repositories/payment_type_repository_impl.dart';
import '../repositories/permission_repository_impl.dart';
import '../repositories/pit_repository_impl.dart';
import '../repositories/product_repository_impl.dart';
import '../repositories/pump_repository_impl.dart';
import '../repositories/refill_repository_impl.dart';
import '../repositories/sale_item_repository_impl.dart';
import '../repositories/sale_repository_impl.dart';
import '../repositories/shift_repository_impl.dart';
import '../repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/client_fleet_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/fuel_price_history_repository.dart';
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

final authRepositoryImplProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
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

final fuelPriceHistoryRepositoryProvider =
    Provider<FuelPriceHistoryRepository>((ref) {
  return FuelPriceHistoryRepositoryImpl(ref.watch(databaseDataSourceProvider));
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
