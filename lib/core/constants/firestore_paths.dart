/// Firestore collection and field path constants.
class FirestorePaths {
  FirestorePaths._();

  // Collection names
  static const String gasTypes = 'gasTypes';
  static const String pits = 'pits';
  static const String pumps = 'pumps';
  static const String products = 'products';
  static const String services = 'services';
  static const String workShifts = 'workShifts';
  static const String shiftPumps = 'shiftPumps';
  static const String clients = 'clients';
  static const String sales = 'sales';
  static const String debts = 'debts';
  static const String payments = 'payments';
  static const String paymentTypes = 'paymentTypes';
  static const String fuelSuppliers = 'fuelSuppliers';
  static const String pitRefills = 'pitRefills';
  static const String refillPayments = 'refillPayments';
  static const String fuelPriceHistory = 'fuelPriceHistory';
  static const String expenses = 'expenses';
  static const String salaryAdvances = 'salaryAdvances';
  static const String logs = 'logs';
  static const String appPermissions = 'appPermissions';
  static const String users = 'users';

  /// Returns a Firestore document reference path: collection/docId
  static String docPath(String collection, String docId) => '$collection/$docId';
}