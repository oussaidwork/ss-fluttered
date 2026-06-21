import 'package:go_router/go_router.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/signup_page.dart';
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
import '../presentation/pages/import_page.dart';
import '../presentation/pages/workers_page.dart';
import '../presentation/pages/expenses_page.dart';
import '../presentation/pages/reports_page.dart';
import '../presentation/pages/system_logs_page.dart';
import '../presentation/pages/settings_page.dart';
import '../presentation/pages/pos_page.dart';
import '../presentation/pages/admin_setup_page.dart';
import '../presentation/pages/shift_import_page.dart';
import '../presentation/pages/client_import_page.dart';
import '../presentation/pages/my_shift_page.dart';
import '../presentation/pages/role_management_page.dart';

abstract class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/';
  static const myShift = '/my-shift';
  static const pos = '/pos';
  static const pits = '/pits';
  static const pumps = '/pumps';
  static const fuel = '/fuel';
  static const products = '/products';
  static const services = '/services';
  static const shifts = '/shifts';
  static const clients = '/clients';
  static const ledger = '/ledger';
  static const workers = '/workers';
  static const roleManagement = '/role-management';
  static const importData = '/import';
  static const importClients = '/import/clients';
  static const importWorkers = '/import/workers';
  static const importShifts = '/import/shifts';
  static const importStation = '/import/station';
  static const importFinancial = '/import/financial';
  static const expenses = '/expenses';
  static const reports = '/reports';
  static const systemLogs = '/system-logs';
  static const settings = '/settings';
  static const adminSetup = '/admin/setup';
  static const shiftImport = '/import/shift-readings';
  static const clientImport = '/import/client-data';
}

GoRouter createRouter({required bool isAuthenticated}) {
  return GoRouter(
    initialLocation: isAuthenticated ? AppRoutes.dashboard : AppRoutes.login,
    redirect: (context, state) {
      final onLogin = state.matchedLocation == AppRoutes.login;
      final onSignup = state.matchedLocation == AppRoutes.signup;
      if (!isAuthenticated && !onLogin && !onSignup) return AppRoutes.login;
      if (isAuthenticated && (onLogin || onSignup)) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupPage()),
      ShellRoute(
        builder: (context, state, child) => DashboardPage(child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, builder: (_, _) => const AdminDashboardPage()),
          GoRoute(path: AppRoutes.myShift, builder: (_, _) => const MyShiftPage()),
          GoRoute(path: AppRoutes.pos, builder: (_, _) => const PosPage()),
          GoRoute(path: AppRoutes.pits, builder: (_, _) => const PitsPage()),
          GoRoute(path: AppRoutes.pumps, builder: (_, _) => const PumpsPage()),
          GoRoute(path: AppRoutes.fuel, builder: (_, _) => const FuelPage()),
          GoRoute(path: AppRoutes.products, builder: (_, _) => const ProductsPage()),
          GoRoute(path: AppRoutes.services, builder: (_, _) => const ServicesPage()),
          GoRoute(path: AppRoutes.shifts, builder: (_, _) => const ShiftsPage()),
          GoRoute(path: AppRoutes.clients, builder: (_, _) => const ClientsPage()),
          GoRoute(path: AppRoutes.ledger, builder: (_, _) => const LedgerPage()),
          GoRoute(path: AppRoutes.workers, builder: (_, _) => const WorkersPage()),
          GoRoute(path: AppRoutes.roleManagement, builder: (_, _) => const RoleManagementPage()),
          GoRoute(
            path: AppRoutes.importData,
            builder: (_, _) => const ImportPage(),
            routes: [
              GoRoute(
                path: 'clients',
                builder: (_, _) => const ImportPage(importType: 'clients'),
              ),
              GoRoute(
                path: 'workers',
                builder: (_, _) => const ImportPage(importType: 'workers'),
              ),
              GoRoute(
                path: 'shifts',
                builder: (_, _) => const ImportPage(importType: 'shifts'),
              ),
              GoRoute(
                path: 'station',
                builder: (_, _) => const ImportPage(importType: 'station'),
              ),
              GoRoute(
                path: 'financial',
                builder: (_, _) => const ImportPage(importType: 'financial'),
              ),
            ],
          ),
          GoRoute(path: AppRoutes.expenses, builder: (_, _) => const ExpensesPage()),
          GoRoute(path: AppRoutes.reports, builder: (_, _) => const ReportsPage()),
          GoRoute(path: AppRoutes.systemLogs, builder: (_, _) => const SystemLogsPage()),
          GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage()),
          GoRoute(path: AppRoutes.adminSetup, builder: (_, _) => const AdminSetupPage()),
          GoRoute(path: AppRoutes.shiftImport, builder: (_, _) => const ShiftImportPage()),
          GoRoute(path: AppRoutes.clientImport, builder: (_, _) => const ClientImportPage()),
        ],
      ),
    ],
  );
}
