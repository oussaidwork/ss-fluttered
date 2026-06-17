import 'package:go_router/go_router.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/admin_dashboard_page.dart';
import '../presentation/pages/pits_page.dart';
import '../presentation/pages/pumps_page.dart';
import '../presentation/pages/fuel_page.dart';
import '../presentation/pages/products_page.dart';
import '../presentation/pages/services_page.dart';
import '../presentation/pages/shifts_page.dart';
import '../presentation/pages/clients_page.dart';
import '../presentation/pages/ledger_page.dart';
import '../presentation/pages/workers_page.dart';
import '../presentation/pages/expenses_page.dart';
import '../presentation/pages/reports_page.dart';
import '../presentation/pages/system_logs_page.dart';
import '../presentation/pages/settings_page.dart';

abstract class AppRoutes {
  static const login = '/login';
  static const dashboard = '/';
  static const pits = '/pits';
  static const pumps = '/pumps';
  static const fuel = '/fuel';
  static const products = '/products';
  static const services = '/services';
  static const shifts = '/shifts';
  static const clients = '/clients';
  static const ledger = '/ledger';
  static const workers = '/workers';
  static const expenses = '/expenses';
  static const reports = '/reports';
  static const systemLogs = '/system-logs';
  static const settings = '/settings';
}

GoRouter createRouter({required bool isAuthenticated}) {
  return GoRouter(
    initialLocation: isAuthenticated ? AppRoutes.dashboard : AppRoutes.login,
    redirect: (context, state) {
      final onLogin = state.matchedLocation == AppRoutes.login;
      if (!isAuthenticated && !onLogin) return AppRoutes.login;
      if (isAuthenticated && onLogin) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => DashboardPage(child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, builder: (_, _) => const AdminDashboardPage()),
          GoRoute(path: AppRoutes.pits, builder: (_, _) => const PitsPage()),
          GoRoute(path: AppRoutes.pumps, builder: (_, _) => const PumpsPage()),
          GoRoute(path: AppRoutes.fuel, builder: (_, _) => const FuelPage()),
          GoRoute(path: AppRoutes.products, builder: (_, _) => const ProductsPage()),
          GoRoute(path: AppRoutes.services, builder: (_, _) => const ServicesPage()),
          GoRoute(path: AppRoutes.shifts, builder: (_, _) => const ShiftsPage()),
          GoRoute(path: AppRoutes.clients, builder: (_, _) => const ClientsPage()),
          GoRoute(path: AppRoutes.ledger, builder: (_, _) => const LedgerPage()),
          GoRoute(path: AppRoutes.workers, builder: (_, _) => const WorkersPage()),
          GoRoute(path: AppRoutes.expenses, builder: (_, _) => const ExpensesPage()),
          GoRoute(path: AppRoutes.reports, builder: (_, _) => const ReportsPage()),
          GoRoute(path: AppRoutes.systemLogs, builder: (_, _) => const SystemLogsPage()),
          GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage()),
        ],
      ),
    ],
  );
}
