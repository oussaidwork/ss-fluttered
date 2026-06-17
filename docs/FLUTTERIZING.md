# Flutter + Firebase Replication Guide

## 1. Firebase Service Mapping

| Current (PocketBase + SQLite) | Firebase Equivalent |
|-------------------------------|-------------------|
| PocketBase Auth (email/password) | Firebase Auth (email/password) |
| SQLite (relational) | Cloud Firestore (NoSQL collections) |
| PocketBase real-time subscriptions | Firestore `.snapshot()` listeners |
| PocketBase listRule/viewRule/createRule/updateRule/deleteRule | Firestore Security Rules |
| PocketBase role field on users | Firebase Custom Claims (`role`) |
| PocketBase file storage | Firebase Storage |
| PocketBase migrations (JS files) | Firestore indexes + manual schema |
| PocketBase hooks (audit log, validation) | Firebase Functions (onCreate, onUpdate) |
| PocketBase Admin UI | Firebase Console + custom admin panel |
| PocketBase cron (log cleanup) | Firebase Functions (scheduled) |

---

## 2. Architecture & Folder Structure

```
lib/
├── main.dart                          # App entry, Firebase init, GoRouter setup
├── app.dart                           # MaterialApp with theme, i18n, router
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # App name, version, default values
│   │   ├── firestore_paths.dart       # Collection & field name constants
│   │   └── report_types.dart          # Report type definitions
│   ├── errors/
│   │   ├── app_exception.dart         # Custom exception types
│   │   └── firestore_exceptions.dart  # Firestore-specific error handling
│   ├── utils/
│   │   ├── round.dart                 # round2(n), round2OrNull(n)
│   │   ├── date_utils.dart            # Format date/datetime
│   │   ├── pump_utils.dart            # groupPumps(), getFuelColor(), group labels
│   │   ├── revenue_utils.dart         # sumField(), fuelSales(), productSales(), etc.
│   │   └── permission_utils.dart      # canPerformActions(), filterNavByPermission()
│   └── theme/
│       ├── app_theme.dart             # ThemeData: light + dark mode
│       ├── app_colors.dart            # PNA brand colors
│       └── app_typography.dart        # Serif, mono, arabic font families
│
├── domain/
│   ├── entities/
│   │   ├── user.dart                  # User, UserRole enum, permission helpers
│   │   ├── shift.dart                 # Shift, ShiftPump with computed volume/revenue
│   │   ├── sale.dart                  # Sale, SaleType enum
│   │   ├── payment.dart               # Payment, PaymentStatus enum
│   │   ├── debt.dart                  # Debt
│   │   ├── client.dart                # Client
│   │   ├── pit.dart                   # Pit
│   │   ├── pump.dart                  # Pump
│   │   ├── gas_type.dart              # GasType
│   │   ├── product.dart               # Product
│   │   ├── service.dart               # Service
│   │   ├── expense.dart               # Expense, ExpenseCategory enum
│   │   ├── pit_refill.dart            # PitRefill
│   │   ├── fuel_supplier.dart         # FuelSupplier
│   │   ├── salary_advance.dart        # SalaryAdvance, AdvanceStatus enum
│   │   ├── payment_type.dart          # PaymentType
│   │   ├── fuel_price_history.dart    # FuelPriceHistory
│   │   ├── log_entry.dart             # LogEntry
│   │   └── app_permission.dart        # AppPermission
│   ├── enums/
│   │   ├── shift_status.dart          # OPEN, CLOSED
│   │   ├── sale_type.dart             # FUEL, PRODUCT, SERVICE
│   │   ├── payment_status.dart        # PENDING, COMPLETED, REJECTED, CANCELLED
│   │   ├── expense_category.dart      # SUPPLIES, MAINTENANCE, SALARY, etc.
│   │   ├── advance_status.dart        # PENDING, APPROVED, REJECTED
│   │   └── user_role.dart             # Worker, Admin, SuperUser, Audit
│   └── repositories/
│       ├── auth_repository.dart       # Interface: login, logout, refresh, getProfile
│       ├── shift_repository.dart      # Interface: shift lifecycle, chain, CRUD
│       ├── sale_repository.dart       # Interface: sales, atomic transactions
│       ├── client_repository.dart     # Interface: clients, payments, debts, balance
│       ├── station_repository.dart    # Interface: pits, pumps, gas types, products, services
│       ├── expense_repository.dart    # Interface: expenses CRUD
│       ├── payment_repository.dart    # Interface: payments, check clearing
│       ├── log_repository.dart        # Interface: audit logs
│       ├── permission_repository.dart # Interface: app permissions
│       ├── user_repository.dart       # Interface: user profiles, salary advances
│       ├── refill_repository.dart     # Interface: pit refills, refill payments
│       └── supplier_repository.dart   # Interface: fuel suppliers
│
├── data/
│   ├── firestore/
│   │   ├── firestore_provider.dart    # FirebaseFirestore singleton
│   │   └── converters/                # Firestore <-> Entity serializers
│   │       ├── user_converter.dart
│   │       ├── shift_converter.dart
│   │       ├── sale_converter.dart
│   │       ├── client_converter.dart
│   │       ├── pit_converter.dart
│   │       ├── pump_converter.dart
│   │       ├── payment_converter.dart
│   │       ├── debt_converter.dart
│   │       ├── expense_converter.dart
│   │       ├── product_converter.dart
│   │       ├── service_converter.dart
│   │       ├── gas_type_converter.dart
│   │       ├── pit_refill_converter.dart
│   │       ├── fuel_supplier_converter.dart
│   │       ├── fuel_price_history_converter.dart
│   │       ├── salary_advance_converter.dart
│   │       ├── log_entry_converter.dart
│   │       ├── payment_type_converter.dart
│   │       └── app_permission_converter.dart
│   ├── repositories/                  # Firestore implementations
│   │   ├── shift_repository_impl.dart
│   │   ├── sale_repository_impl.dart
│   │   ├── client_repository_impl.dart
│   │   ├── station_repository_impl.dart
│   │   ├── expense_repository_impl.dart
│   │   ├── payment_repository_impl.dart
│   │   ├── log_repository_impl.dart
│   │   ├── permission_repository_impl.dart
│   │   ├── user_repository_impl.dart
│   │   ├── refill_repository_impl.dart
│   │   └── supplier_repository_impl.dart
│   └── auth/
│       └── firebase_auth_provider.dart # Firebase Auth wrapper
│
├── presentation/
│   ├── providers/                     # Riverpod providers
│   │   ├── auth_provider.dart         # authStateProvider, profileProvider
│   │   ├── station_provider.dart      # pumps, pits, gasTypes, products, services
│   │   ├── shift_provider.dart        # activeShift, allShifts, shiftChain
│   │   ├── sale_provider.dart         # todaySales, allSales
│   │   ├── client_provider.dart       # clients, selectedClient, ledger
│   │   ├── payment_provider.dart      # payments, pending checks
│   │   ├── expense_provider.dart      # expenses, totals
│   │   ├── report_provider.dart       # computed metrics for reports
│   │   ├── dashboard_provider.dart    # KPI computations (totalFuelSales, etc.)
│   │   └── ui_provider.dart           # activeView, modals, navigation state
│   ├── pages/
│   │   ├── login_page.dart            # Email/password login
│   │   ├── loading_splash_page.dart   # Splash with animated fuel icon
│   │   ├── dashboard_page.dart        # Main layout shell (sidebar/bottomnav + content)
│   │   ├── admin_dashboard_page.dart  # KPI cards, charts, alerts
│   │   ├── worker_dashboard_page.dart # Worker terminal (shift + POS)
│   │   ├── pits_page.dart             # Pit CRUD, refill history
│   │   ├── pumps_page.dart            # Pump CRUD, group config
│   │   ├── fuel_page.dart             # Gas types, price history
│   │   ├── products_page.dart         # Product CRUD
│   │   ├── services_page.dart         # Service CRUD
│   │   ├── shifts_page.dart           # Shift list, filter, export
│   │   ├── clients_page.dart          # Client list, CRUD
│   │   ├── ledger_page.dart           # Transaction timeline (sales+payments+debts)
│   │   ├── workers_page.dart          # HR profiles, salary advances
│   │   ├── expenses_page.dart         # Expense CRUD
│   │   ├── imports_page.dart          # Tabbed import view (shifts/refills/clients)
│   │   ├── reports_page.dart          # Report type selection + print
│   │   ├── role_management_page.dart  # Per-section permission editor
│   │   ├── system_logs_page.dart      # Audit log viewer
│   │   └── settings_page.dart         # Language, theme, vault
│   └── widgets/
│       ├── common/
│       │   ├── editorial_ticker_bar.dart   # Top bar: theme, lang, user, date, signout
│       │   ├── sidebar.dart                # 220px full / 60px mini + overlay
│       │   ├── bottom_nav_bar.dart         # Phone bottom navigation
│       │   ├── fab_speed_dial.dart         # Floating action button + 7 actions
│       │   ├── kpi_card.dart               # Metric display card
│       │   ├── confirm_action_dialog.dart  # Danger confirmation wrapper
│       │   ├── mutation_locked.dart        # Permission-denied placeholder
│       │   └── loading_indicator.dart      # Spinner / skeleton
│       ├── forms/
│       │   ├── record_sale_form.dart       # Inline FUEL/PRODUCT/SERVICE sale entry
│       │   ├── transaction_form.dart       # Slide-over SALE/PAYMENT/DEBT form
│       │   ├── client_form.dart            # Client CRUD form
│       │   ├── expense_form.dart           # Expense entry form
│       │   ├── pit_form.dart               # Pit CRUD form
│       │   ├── pump_form.dart              # Pump CRUD form
│       │   ├── product_form.dart           # Product CRUD form
│       │   ├── service_form.dart           # Service CRUD form
│       │   ├── refill_form.dart            # Pit refill recording form
│       │   ├── salary_advance_form.dart    # Advance request form
│       │   └── quick_price_edit_modal.dart # Fuel price quick edit
│       ├── shift/
│       │   ├── worker_shift_workflow.dart  # Two-phase: SETUP matrix → TERMINAL_ENTRY
│       │   ├── worker_shift_termination.dart # Two-phase: END_READINGS → MASTER_AUDIT
│       │   ├── terminal_keypad.dart        # Custom digit keypad for counter entry
│       │   ├── counter_picker.dart         # Digit wheel spinner dialog
│       │   ├── mechanical_counter_reader.dart # Camera OCR for 7-segment counters
│       │   ├── last_shift_widget.dart      # Collapsible last shift summary
│       │   └── shift_pump_matrix.dart      # Pump selection grid grouped by block
│       ├── client/
│       │   ├── transaction_timeline.dart   # Virtualized ledger with expandable rows
│       │   ├── client_search.dart          # Autocomplete search + create on blur
│       │   └── autocomplete_input.dart     # Generic search-as-you-type dropdown
│       ├── reports/
│       │   ├── pump_indexes_report.dart    # A4 printable pump report
│       │   ├── sales_report.dart           # A4 printable sales report
│       │   ├── debts_report.dart           # A4 printable debts report
│       │   ├── payments_report.dart        # A4 printable payments report
│       │   ├── refills_report.dart         # A4 printable refill report
│       │   ├── price_history_report.dart   # A4 printable price history
│       │   ├── audit_log_report.dart       # A4 printable audit log
│       │   └── shift_summary_report.dart   # A4 printable shift summary
│       └── charts/
│           ├── shift_performance_chart.dart # Bar chart: week/month, revenue/volume toggle
│           └── fuel_sales_chart.dart        # Per-type fuel sales breakdown
│
├── services/
│   ├── auth_service.dart              # Firebase Auth wrapper
│   ├── i18n_service.dart              # i18n configuration + locale switching
│   ├── export_service.dart            # Excel generation (excel package)
│   ├── print_service.dart             # A4 PDF generation (pdf + printing packages)
│   ├── ocr_service.dart               # ML Kit text recognition wrapper
│   └── error_service.dart             # Global error handling + toast notifications
│
└── l10n/                              # Localization files
    ├── app_en.arb                     # 1434 English keys
    ├── app_fr.arb                     # 1434 French keys
    └── app_ar.arb                     # 1440 Arabic keys (RTL)
```

---

## 3. Data Model Migration — PocketBase to Firestore

### General Design Decisions

1. **DocumentReferences for relations:** Each relation field becomes a `DocumentReference` pointing to the target document.
2. **Timestamps:** Use `Timestamp` (Firestore native) instead of ISO strings.
3. **Soft deletes:** Use `isDeleted` boolean field on all major collections.
4. **Subcollections vs. top-level:** `shift_pumps` stays as a top-level collection (needs cross-shift queries for chain).
5. **Batch writes:** Atomic operations (sale + payment + pit decrement) use `WriteBatch`.
6. **Transactions:** For operations requiring read-then-write (pit deduction, balance update), use Firestore `runTransaction`.

### Collection-by-Collection Migration

Each PocketBase collection maps to a Firestore collection. Field names convert from `snake_case` to `camelCase`.

#### gas_types → `gasTypes`
```
Document: /gasTypes/{gasTypeId}
Fields:
  name: String (required, unique enforced in code)
  priceIn: num (required)
  priceOut: num (required)
  color: String?
  isDeleted: bool (default: false)
  createdAt: Timestamp
  updatedAt: Timestamp
Indexes: name ASC
```

#### pits → `pits`
```
Document: /pits/{pitId}
Fields:
  name: String (required)
  capacity: num (required)
  currentVolume: num?
  gasTypeId: DocumentReference → /gasTypes/{id}
  isDeleted: bool (default: false)
Indexes: gasTypeId ASC, name ASC
```

#### pumps → `pumps`
```
Document: /pumps/{pumpId}
Fields:
  name: String (required)
  isActive: bool?
  initialAnalogCounter: num?
  groupId: String? (1=Block A, 2=Block B, 3=Block C, 4=Block D)
  subgroup: String?
  color: String?
  pitId: DocumentReference → /pits/{id} (required)
  isDeleted: bool (default: false)
Indexes: pitId ASC, groupId ASC
```

#### products → `products`
```
Document: /products/{productId}
Fields:
  name: String (required)
  price: num (required)
  priceIn: num?
  priceOut: num?
  unit: String?
  stockQuantity: num?
  category: String?
  isActive: bool?
  isDeleted: bool (default: false)
```

#### services → `services`
```
Document: /services/{serviceId}
Fields:
  name: String (required)
  priceIn: num?
  priceOut: num (required)
  unit: String?
  isDeleted: bool (default: false)
Indexes: name ASC
```

#### work_shifts → `workShifts`
```
Document: /workShifts/{shiftId}
Fields:
  startTime: Timestamp (required)
  endTime: Timestamp (required — set on close, but initially can be future placeholder)
  status: String (enum: "OPEN", "CLOSED")
  actualCash: num?
  workerId: DocumentReference → /users/{id} (required)
Indexes:
  - workerId ASC, status ASC
  - status ASC, startTime DESC
  - startTime ASC
```

#### shift_pumps → `shiftPumps`
```
Document: /shiftPumps/{shiftPumpId}
Fields:
  endAnalogCounter: num?
  priceAtShift: num?
  shiftId: DocumentReference → /workShifts/{id} (required)
  pumpId: DocumentReference → /pumps/{id} (required)
Indexes:
  - shiftId ASC
  - pumpId ASC, created ASC
  - pumpId ASC, created DESC
```

**CRITICAL INDEX:** Composite index on `pumpId ASC, created ASC` — required for the shift counter chain algorithm (fetching all shiftPumps for a pump in chronological order).

#### clients → `clients`
```
Document: /clients/{clientId}
Fields:
  name: String (required)
  phone: String?
  plateNumber: String?
  creditLimit: num?
  currentBalance: num?
  address: String?
  email: String?
  isDeleted: bool (default: false)
Indexes: name ASC, phone ASC
```

#### sales → `sales`
```
Document: /sales/{saleId}
Fields:
  saleType: String (enum: "FUEL", "PRODUCT", "SERVICE")
  volume: num?
  unitPrice: num?
  totalPrice: num (required)
  driverName: String?
  vehiclePlate: String?
  driverPhone: String?
  notes: String?
  timestamp: Timestamp?
  shiftId: DocumentReference → /workShifts/{id}?
  clientId: DocumentReference → /clients/{id}?
  gasTypeId: DocumentReference → /gasTypes/{id}?
  productId: DocumentReference → /products/{id}?
  serviceId: DocumentReference → /services/{id}?
  paymentTypeId: DocumentReference → /paymentTypes/{id}?
  workerId: DocumentReference → /users/{id}?
  isDeleted: bool (default: false)
Indexes:
  - timestamp DESC
  - shiftId ASC
  - clientId ASC, timestamp DESC
  - workerId ASC, timestamp DESC
  - gasTypeId ASC, timestamp DESC
```

#### debts → `debts`
```
Document: /debts/{debtId}
Fields:
  amount: num (required)
  dueDate: Timestamp?
  clientId: DocumentReference → /clients/{id} (required)
  driverName: String?
  vehiclePlate: String?
  isDeleted: bool (default: false)
Indexes: clientId ASC
```

#### payments → `payments`
```
Document: /payments/{paymentId}
Fields:
  amount: num (required)
  status: String (enum: "PENDING", "COMPLETED", "REJECTED", "CANCELLED")
  checkBankName: String?
  checkNumber: String?
  dueDate: Timestamp?
  clearedAt: Timestamp?
  notes: String?
  clientId: DocumentReference → /clients/{id}?
  saleId: DocumentReference → /sales/{id}?
  paymentTypeId: DocumentReference → /paymentTypes/{id}?
  recordedBy: DocumentReference → /users/{id}?
  isDeleted: bool (default: false)
  createdAt: Timestamp
Indexes:
  - clientId ASC, createdAt DESC
  - saleId ASC
  - status ASC, createdAt DESC
  - createdAt DESC
```

#### payment_types → `paymentTypes`
```
Document: /paymentTypes/{paymentTypeId}
Fields:
  name: String (required)
  code: String (required, unique enforced in code: CASH, CHECK, TRANSFER)
  icon: String?
```

#### fuel_suppliers → `fuelSuppliers`
```
Document: /fuelSuppliers/{supplierId}
Fields:
  name: String (required)
  isActive: bool?
```

#### pit_refills → `pitRefills`
```
Document: /pitRefills/{refillId}
Fields:
  volume: num (required)
  costPerLiter: num?
  totalCost: num?
  profitMargin: num?
  timestamp: Timestamp (required)
  pitId: DocumentReference → /pits/{id} (required)
  recordedBy: DocumentReference → /users/{id}?
  supplierId: DocumentReference → /fuelSuppliers/{id}?
  fleetTruckId: String?
  fleetDriverName: String?
  fleetVehiclePlate: String?
  truckDriver: String?
  depotNum: String?
  bchNum: String?
  vehPlate: String?
  tankId: String?
Indexes:
  - pitId ASC, timestamp DESC
  - timestamp DESC
```

#### refill_payments → `refillPayments`
```
Document: /refillPayments/{refillPaymentId}
Fields:
  amount: num (required)
  transferReference: String?
  bankName: String?
  accountNumber: String?
  paymentDate: Timestamp?
  refillId: DocumentReference → /pitRefills/{id} (required)
  paymentTypeId: DocumentReference → /paymentTypes/{id}?
Indexes: refillId ASC
```

#### fuel_price_history → `fuelPriceHistory`
```
Document: /fuelPriceHistory/{historyId}
Fields:
  oldPriceIn: num?
  newPriceIn: num?
  oldPriceOut: num?
  newPriceOut: num?
  changedAt: Timestamp (required)
  gasTypeId: DocumentReference → /gasTypes/{id} (required)
  changedBy: DocumentReference → /users/{id}?
  isDeleted: bool (default: false)
Indexes:
  - gasTypeId ASC, changedAt DESC
  - changedAt DESC
```

#### expenses → `expenses`
```
Document: /expenses/{expenseId}
Fields:
  description: String (required)
  amount: num (required)
  quantity: num?
  category: String? (enum: "SUPPLIES", "MAINTENANCE", "SALARY", "UTILITIES", "RENT", "TRANSPORT", "OTHER")
  timestamp: Timestamp (required)
  recordedBy: DocumentReference → /users/{id}?
Indexes:
  - timestamp DESC
  - recordedBy ASC, timestamp DESC
```

#### salary_advances → `salaryAdvances`
```
Document: /salaryAdvances/{advanceId}
Fields:
  amount: num (required)
  status: String (enum: "PENDING", "APPROVED", "REJECTED")
  requestDate: Timestamp (required)
  resolutionDate: Timestamp?
  workerId: DocumentReference → /users/{id} (required)
  resolvedBy: DocumentReference → /users/{id}?
Indexes:
  - workerId ASC, requestDate DESC
  - status ASC
```

#### logs → `logs`
```
Document: /logs/{logId}
Fields:
  action: String (required)
  details: String? (max 2000)
  timestamp: Timestamp (required)
  userId: DocumentReference → /users/{id}?
  ttlExpiry: Timestamp (for 90-day cleanup)
Indexes:
  - timestamp DESC
  - userId ASC, timestamp DESC
  - action ASC, timestamp DESC
```

#### app_permissions → `appPermissions`
```
Document: /appPermissions/{section}
Fields:
  section: String (required, used as document ID)
  permittedRoles: List<String>? (e.g. ["Admin", "SuperUser", "Worker"])
  roles: List<String>?
```

#### users → `users` (Firebase Auth + Firestore profile)
```
Firebase Auth record:
  uid: String (PK)
  email: String
  emailVerified: bool

Firestore Document: /users/{uid}
Fields:
  fullName: String?
  role: String (required: "Worker", "Admin", "SuperUser", "Audit")
  isActive: bool?
  monthlySalary: num?

Firebase Custom Claims:
  { role: "Worker" | "Admin" | "SuperUser" | "Audit" }
```

---

## 4. Firestore Indexes

Create these composite indexes in Firebase Console or via `firestore.indexes.json`:

```json
{
  "indexes": [
    // Work Shifts
    { "collectionGroup": "workShifts", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "workerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" } ] },
    { "collectionGroup": "workShifts", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "DESCENDING" } ] },

    // Shift Pumps (CRITICAL for chain)
    { "collectionGroup": "shiftPumps", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "pumpId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "ASCENDING" } ] },
    { "collectionGroup": "shiftPumps", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "shiftId", "order": "ASCENDING" },
        { "fieldPath": "pumpId", "order": "ASCENDING" } ] },

    // Sales
    { "collectionGroup": "sales", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clientId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" } ] },
    { "collectionGroup": "sales", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "workerId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" } ] },
    { "collectionGroup": "sales", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "gasTypeId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" } ] },

    // Payments
    { "collectionGroup": "payments", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clientId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" } ] },
    { "collectionGroup": "payments", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" } ] },

    // Pit Refills
    { "collectionGroup": "pitRefills", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "pitId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" } ] },

    // Fuel Price History
    { "collectionGroup": "fuelPriceHistory", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "gasTypeId", "order": "ASCENDING" },
        { "fieldPath": "changedAt", "order": "DESCENDING" } ] },

    // Logs
    { "collectionGroup": "logs", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" } ] },
    { "collectionGroup": "logs", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "action", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" } ] },

    // Expenses
    { "collectionGroup": "expenses", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "recordedBy", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" } ] },

    // Salary Advances
    { "collectionGroup": "salaryAdvances", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "workerId", "order": "ASCENDING" },
        { "fieldPath": "requestDate", "order": "DESCENDING" } ] }
  ]
}
```

---

## 5. Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    function getUserRole() {
      return request.auth.token.role;
    }
    function isAdmin() {
      return getUserRole() in ['Admin', 'SuperUser'];
    }
    function isSuperUser() {
      return getUserRole() == 'SuperUser';
    }
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // gasTypes — authenticated can read, Admin+ can write
    match /gasTypes/{doc} {
      allow read: if isAuthenticated();
      allow create, update: if isAdmin();
      allow delete: if isSuperUser();
    }

    // pits — same as gasTypes
    match /pits/{doc} {
      allow read: if isAuthenticated();
      allow create, update: if isAdmin();
      allow delete: if isSuperUser();
    }

    // pumps — same
    match /pumps/{doc} {
      allow read: if isAuthenticated();
      allow create, update: if isAdmin();
      allow delete: if isSuperUser();
    }

    // products, services, paymentTypes, fuelSuppliers — same
    match /products/{doc} {
      allow read: if isAuthenticated();
      allow create, update: if isAdmin();
      allow delete: if isSuperUser();
    }
    match /services/{doc} {
      allow read: if isAuthenticated();
      allow create, update: if isAdmin();
      allow delete: if isSuperUser();
    }
    match /paymentTypes/{doc} {
      allow read: if isAuthenticated();
      allow create, update: if isAdmin();
      allow delete: if isSuperUser();
    }
    match /fuelSuppliers/{doc} {
      allow read: if isAuthenticated();
      allow create, update: if isAdmin();
      allow delete: if isSuperUser();
    }

    // workShifts — worker can create; worker can update own open shift; Admin can all
    match /workShifts/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if (isOwner(resource.data.workerId) && resource.data.status == 'OPEN')
                      || isAdmin();
      allow delete: if isAdmin();
    }

    // shiftPumps — authenticated can CRUD (tied to shift permissions via app logic)
    match /shiftPumps/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAdmin();
    }

    // clients — authenticated can read/create/update; Admin+ can delete
    match /clients/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAdmin();
    }

    // sales — authenticated can CRUD
    match /sales/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAdmin();
    }

    // debts — same as sales
    match /debts/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAdmin();
    }

    // payments — same
    match /payments/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAdmin();
    }

    // pitRefills, refillPayments — same
    match /pitRefills/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAdmin();
    }
    match /refillPayments/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAdmin();
    }

    // fuelPriceHistory — authenticated can read; authenticated can create (auto by system); Admin+ delete
    match /fuelPriceHistory/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // expenses — authenticated can read/create/update; Admin+ delete
    match /expenses/{doc} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAdmin();
    }

    // salaryAdvances — worker can read own, create; Admin can all
    match /salaryAdvances/{doc} {
      allow read: if isOwner(resource.data.workerId) || isAdmin();
      allow create: if isAuthenticated();
      allow update: if isAdmin();  // Only Admin can approve/reject
      allow delete: if isAdmin();
    }

    // logs — Admin+Audit can read; authenticated can create; no update/delete
    match /logs/{doc} {
      allow read: if isAdmin() || getUserRole() == 'Audit';
      allow create: if isAuthenticated();
      allow update: if false;
      allow delete: if false;
    }

    // appPermissions — Admin+ can read/write
    match /appPermissions/{doc} {
      allow read: if isAuthenticated();
      allow create, update: if isAdmin();
      allow delete: if isSuperUser();
    }

    // user profiles — user can read own; Admin+ can read all; user can update own non-role fields
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAdmin();
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isSuperUser();
    }
  }
}
```

---

## 6. Feature Implementation Roadmap

### Sprint 1-2: Foundation

| Task | Details |
|------|---------|
| Firebase project setup | Firebase CLI, `firebase init`, enable Auth + Firestore + Storage + Functions |
| Flutter project scaffold | `flutter create`, add packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `riverpod`, `go_router`, `flutter_localizations` |
| Auth service | `FirebaseAuth` wrapper: login, logout, auth state stream, custom claims listener |
| User profile CRUD | Firestore `users/{uid}` on auth create (Firebase Function), profile provider |
| Theme system | Material 3 with light/dark mode, PNA brand colors, serif/mono font families |
| Navigation shell | `GoRouter` with auth redirects, responsive layout (sidebar/bottomnav), `uiProvider` for active view |
| Core utilities | `round2()`, `date_utils.dart`, `pump_utils.dart`, `revenue_utils.dart`, `cn()` equivalent |

### Sprint 3: Shift Start Workflow

| Task | Details |
|------|---------|
| Pump matrix UI | Grouped pump selection grid (Block A/B/C/D), checkCircle toggles, shift parameter bar |
| TerminalKeypad widget | Custom digit keypad: 0-9, Enter, Backspace, Escape. Integer-only mode. |
| Analog counter input | Per-pump counter entry with validation (≥ reference, max +5000) |
| Shift creation | Firestore batch write: create `workShifts` (OPEN), create `shiftPumps` records, fetch gas prices, log `SHIFT_STARTED` |
| Draft persistence | Local state save/restore for shift-in-progress |
| Chain verification | Cloud Function or client-side: verify latest closed shift's endTime matches new startTime |

### Sprint 4: POS + Payment Recording

| Task | Details |
|------|---------|
| Sale type toggle | FUEL / PRODUCT / SERVICE segmented button with live counts |
| Asset selector | Dynamic dropdown: gasTypes / products / services filtered by sale type |
| Auto-calc fields | Volume × unitPrice = totalPrice, bi-directional calculation |
| Payment protocol card | CASH / CHECK toggle, conditional check fields (bank, serial#, maturity date) |
| Client selector | Dropdown with PASS_BY (cash walk-in) + named clients |
| Fleet field autocomplete | Historical driver names, vehicle plates, notes presets |
| Atomic sale transaction | Firestore `WriteBatch`: create sale → create payment → decrement pit volume |
| Rollback on failure | Delete created records in reverse order on any error |
| Validation | Product/asset required, worker required, PASS_BY + CHECK not allowed |

### Sprint 5: Shift End + Chain Computation

| Task | Details |
|------|---------|
| End readings phase | Per-pump end_analog_counter entry via TerminalKeypad |
| Camera OCR integration | MechanicalCounterReader: 7-segment digit recognition via ML Kit |
| Master Audit phase | Pump delta summary table, grouped by block, with volume + revenue |
| Counter chain computation | Fetch all shiftPumps for each pump, sort by createdAt ASC, compute volume = max(0, end - prevEnd) |
| Pit deduction | Group pump volumes by pitId, `runTransaction` to decrement each pit's `currentVolume` |
| Liquidity audit sidebar | Pump sales total vs ledger payments total, variance display |
| Shift close | Batch write: update shiftPumps endAnalogCounter + priceAtShift, update shift status to CLOSED + endTime, update pit volumes |
| Price change detection | Detect if priceAtShift differs from previous shift's price → create fuelPriceHistory entry |

### Sprint 6: Inventory (Pits + Refills)

| Task | Details |
|------|---------|
| Pit CRUD | Create/read/update/delete pits with gas type assignment |
| Pump CRUD | Create/read/update/delete pumps with pit assignment, group configuration |
| Refill recording | Form: pit, volume, costPerLiter, totalCost (auto-calc), profitMargin, supplier, fleet details |
| Refill atomic transaction | Batch: increment pit currentVolume, create pitRefill, create refillPayment if applicable |
| Gas type CRUD | Create/read/update/delete fuel types |
| Product CRUD | Create/read/update/delete shop products with stock tracking |
| Service CRUD | Create/read/update/delete service fees |
| Fuel price edit | Modal: update priceIn/priceOut, auto-create fuelPriceHistory record |

### Sprint 7: Client Ledger + Check Clearing

| Task | Details |
|------|---------|
| Client CRUD | Full form with name, phone, plate, credit limit, address, email |
| Transaction timeline | Virtualized list of sales + payments + debts for a client, grouped by date |
| Filter bar | Date presets (All/Today/Week/Month/Custom), type filter (All/Sales/Payments/Debts), search |
| Expandable rows | Sale: Void. Payment PENDING: Clear/Reject. Payment COMPLETED: Reopen. Debt: Mark Paid/Delete |
| Check clearing | `clearCheck()`: PENDING→COMPLETED, set clearedAt. `rejectCheck()`: PENDING→REJECTED |
| Client balance | Computed: `sum(debts) - sum(completedPayments)`, updated on every create/update/delete |
| Client archive/restore | Soft-delete cascade: debts + payments + sales + client, with restore |
| TransactionForm slide-over | Unified SALE/PAYMENT/DEBT panel with client search, fields per type, validation |

### Sprint 8: Reports + Printing

| Task | Details |
|------|---------|
| PDF generation | `pdf` or `printing` package for A4-formatted documents |
| Report component pattern | Base report widget: header (logo + title), info boxes, data table, summary row, footer |
| Pump Indexes Report | Per-pump: name, fuel, price, volume, revenue. Summary: total volume |
| Sales Report | Per-sale: time, client, product, volume, price, total, method. Summary: total revenue |
| Debts Report | Per-debt: client, date, due date, amount. Summary: total exposure |
| Payments Report | Per-payment: client, amount, method, status. Summary: total collected |
| Pit Refill Report | Per-refill: pit, volume, cost, margin, date. Summary: total volume |
| Price History Report | Per-change: fuel type, old/new price, date, who |
| Audit Log Report | Chronological action log with filter by action type, date range, user |
| Shift Summary Report | Per-shift: worker, date, pumps, volume, revenue, cash |

### Sprint 9: HR, Expenses, Imports, Admin Features

| Task | Details |
|------|---------|
| Worker HR profiles | User list with role, is_active, monthly_salary. Admin can update. |
| Salary advance management | Worker: request form. Admin: approve/reject, optional expense recording |
| Advance status workflow | PENDING → APPROVED/REJECTED, with resolution_date and resolved_by |
| Expense CRUD | Description, amount, quantity, category selector, timestamp, recorded_by |
| Role management | Per-section permission editor: CRUD on appPermissions collection |
| System logs viewer | Paginated log list with filter by action type, date range, user |
| Settings page | Language switcher, theme toggle, vault export/import (JSON) |
| Shift Excel import | Parse Excel → create manual shifts via Cloud Function |
| Pit Refill Excel import | Parse Excel → create refills + payments via Cloud Function |
| Client data import | Parse Excel/JSON → create sales + payments + debts via Cloud Function |
| Bulk edit template | Generate Excel with pump matrix for offline editing, re-upload |

### Sprint 10: Polish, i18n, Offline, OCR, Deployment

| Task | Details |
|------|---------|
| i18n (1434 keys × 3 languages) | Generate ARB files for EN/FR/AR, implement locale switching with `flutter_localizations` |
| RTL support | Arabic layout with `Directionality`, mirrored sidebar/nav, right-aligned forms |
| FAB Speed Dial | Floating action button with 7 quick actions, draggable, permission-filtered |
| Admin dashboard charts | `fl_chart` or `syncfusion`: bar chart (shift performance week/month), KPI cards |
| OCR with ML Kit | `google_mlkit_text_recognition`: camera viewfinder with alignment overlay, digit recognition |
| Offline support | Firestore `enablePersistence()`, connectivity monitoring with `connectivity_plus` |
| Error handling | Global error handler with toast notifications, retry logic for Firestore operations |
| Dark/light theme | Toggle persisted, industrial dark mode vs editorial light mode |
| Loading/splash screen | Animated fuel icon + "Synchronizing Operational Data..." |
| CI/CD | Codemagic or GitHub Actions: build → test → deploy to Firebase Hosting |
| Performance | Shrinkwrap, deferred loading for heavy screens (reports, imports), list virtualization |

---

## 7. State Management Architecture

### Riverpod Provider Structure

```
// Auth
final authStateProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());
final userProfileProvider = FutureProvider.family<UserProfile, String>((ref, uid) => ...);
final userRoleProvider = Provider<UserRole>((ref) => ...);
final canPerformActionsProvider = Provider.family<bool, String?>((ref, section) => ...);

// Station data (fetched once, then listen to snapshot)
final gasTypesProvider = StreamProvider<List<GasType>>((ref) => ...);
final pitsProvider = StreamProvider<List<Pit>>((ref) => ...);
final pumpsProvider = StreamProvider<List<Pump>>((ref) => ...);
final productsProvider = StreamProvider<List<Product>>((ref) => ...);
final servicesProvider = StreamProvider<List<Service>>((ref) => ...);
final paymentTypesProvider = StreamProvider<List<PaymentType>>((ref) => ...);

// Shifts
final activeShiftsProvider = StreamProvider<List<WorkShift>>((ref) => ...);
final myActiveShiftProvider = Provider<WorkShift?>((ref) => ...);
final allShiftsProvider = StreamProvider<List<WorkShift>>((ref) => ...);
final shiftDetailProvider = FutureProvider.family<ShiftDetail, String>((ref, shiftId) => ...);
final shiftChainProvider = FutureProvider<List<ShiftPump>>((ref) => ...);

// Sales
final todaySalesProvider = StreamProvider<List<Sale>>((ref) => ...);
final allSalesProvider = StreamProvider<List<Sale>>((ref) => ...);
final salesTotalsProvider = Provider<SalesTotals>((ref) => ...);

// Clients
final clientsProvider = StreamProvider<List<Client>>((ref) => ...);
final clientDetailProvider = FutureProvider.family<ClientDetail, String>((ref, clientId) => ...);
final clientTransactionsProvider = FutureProvider.family<List<Transaction>, String>((ref, clientId) => ...);

// Payments
final pendingPaymentsProvider = Provider<List<Payment>>((ref) => ...);
final checkClearingProvider = StateNotifierProvider<CheckClearingNotifier, AsyncValue<void>>((ref) => ...);

// Dashboard metrics (computed)
final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) => {
  final allShifts = ref.watch(allShiftsProvider).valueOrNull ?? [];
  final allSales = ref.watch(allSalesProvider).valueOrNull ?? [];
  final clients = ref.watch(clientsProvider).valueOrNull ?? [];
  final allPayments = ref.watch(paymentsProvider).valueOrNull ?? [];
  // Compute: totalFuelSales, totalProductSales, totalUnpaidDebts, fuelSalesByType, etc.
});

// UI state
final uiProvider = StateNotifierProvider<UINotifier, UIState>((ref) => UINotifier());
  // Properties: activeView, activeSubView, showSidebarOverlay, isNavHidden, sidebarCollapsed
```

### Key Data Flow Patterns

**1. Real-time sync:** Use Firestore `.snapshot()` for collections that change frequently (sales, shifts, payments). Auto-dispose providers when no screen is watching.

**2. Atomic writes:** For operations that must succeed or fail together (sale + payment + pit deduction), use `WriteBatch` in the repository implementation. The provider calls the repository method and invalidates relevant data on success.

**3. Computed metrics:** Use Riverpod `Provider` (not StreamProvider) for derived data. The dashboard metrics provider watches multiple source providers and recomputes when any source changes.

**4. Optimistic updates:** For fast UX, update local state immediately, write to Firestore, and roll back on error.

---

## 8. Key Algorithm Implementations

### 8.1 Shift Counter Chain

```dart
List<ShiftPump> deriveChainData(
  List<ShiftPump> allShiftPumps,
  Map<String, Pump> pumpMap,
) {
  // 1. Sort by pumpId then by shift endTime ASC
  allShiftPumps.sort((a, b) {
    final cmp = a.pumpId.compareTo(b.pumpId);
    if (cmp != 0) return cmp;
    return a.shiftEndTime.compareTo(b.shiftEndTime);
  });

  // 2. Track last end counter per pump
  final Map<String, double> lastEndPerPump = {};

  // 3. Compute volume for each
  for (final sp in allShiftPumps) {
    final prevEnd = lastEndPerPump[sp.pumpId]
        ?? pumpMap[sp.pumpId]?.initialAnalogCounter
        ?? 0.0;
    sp.previousEndAnalogCounter = prevEnd;
    sp.volume = max(0.0, (sp.endAnalogCounter ?? 0.0) - prevEnd);
    sp.revenue = round2(sp.volume * (sp.priceAtShift ?? 0.0));
    lastEndPerPump[sp.pumpId] = sp.endAnalogCounter ?? prevEnd;
  }

  return allShiftPumps;
}
```

### 8.2 Pit Deduction on Shift Close

```dart
Future<void> deductPitVolumes(String shiftId) async {
  final shiftPumps = await getShiftPumpsForShift(shiftId);
  final chainData = deriveChainData(shiftPumps, await getAllPumpsAsMap());

  // Group volume by pit
  final Map<String, double> pitVolumes = {};
  for (final sp in chainData) {
    if (sp.volume > 0) {
      pitVolumes.update(sp.pitId, (v) => v + sp.volume, ifAbsent: () => sp.volume);
    }
  }

  // Deduct in a transaction
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    for (final entry in pitVolumes.entries) {
      final pitRef = FirebaseFirestore.instance.collection('pits').doc(entry.key);
      final pitSnap = await transaction.get(pitRef);
      if (!pitSnap.exists) continue;
      final currentVol = (pitSnap.data()!['currentVolume'] as num?)?.toDouble() ?? 0.0;
      final newVol = round2(max(0.0, currentVol - entry.value));
      transaction.update(pitRef, {'currentVolume': newVol});
    }
  });
}
```

### 8.3 Atomic Sale Creation

```dart
Future<Sale> recordSale(SaleData data) async {
  final batch = FirebaseFirestore.instance.batch();
  final saleRef = FirebaseFirestore.instance.collection('sales').doc();
  final paymentRef = FirebaseFirestore.instance.collection('payments').doc();
  final now = Timestamp.now();

  // 1. Create sale
  batch.set(saleRef, {
    'saleType': data.saleType.name,
    'volume': data.volume,
    'unitPrice': data.unitPrice,
    'totalPrice': round2(data.totalPrice),
    'clientId': data.clientId != null ? docRef('clients', data.clientId!) : null,
    'gasTypeId': data.gasTypeId != null ? docRef('gasTypes', data.gasTypeId!) : null,
    'productId': data.productId != null ? docRef('products', data.productId!) : null,
    'serviceId': data.serviceId != null ? docRef('services', data.serviceId!) : null,
    'workerId': docRef('users', data.workerId),
    'shiftId': docRef('workShifts', data.shiftId),
    'paymentTypeId': data.paymentTypeId != null ? docRef('paymentTypes', data.paymentTypeId!) : null,
    'driverName': data.driverName,
    'vehiclePlate': data.vehiclePlate,
    'notes': data.notes,
    'timestamp': data.timestamp ?? now,
    'isDeleted': false,
    'createdAt': now,
    'updatedAt': now,
  });

  // 2. Create payment if amount > 0
  if (data.paidAmount > 0) {
    final isCash = data.paymentTypeCode == 'CASH';
    batch.set(paymentRef, {
      'amount': round2(data.paidAmount),
      'status': isCash ? 'COMPLETED' : 'PENDING',
      'clearedAt': isCash ? now : null,
      'checkBankName': data.checkBankName,
      'checkNumber': data.checkNumber,
      'dueDate': data.checkDueDate,
      'clientId': data.clientId != null ? docRef('clients', data.clientId!) : null,
      'saleId': saleRef,
      'paymentTypeId': data.paymentTypeId != null ? docRef('paymentTypes', data.paymentTypeId!) : null,
      'recordedBy': docRef('users', data.workerId),
      'isDeleted': false,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  // 3. Decrement pit volume for FUEL sales
  if (data.saleType == SaleType.FUEL && data.gasTypeId != null && (data.volume ?? 0) > 0) {
    // Find the pit for this gas type (first active pit)
    final pitSnapshot = await FirebaseFirestore.instance
        .collection('pits')
        .where('gasTypeId', isEqualTo: docRef('gasTypes', data.gasTypeId!))
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    if (pitSnapshot.docs.isNotEmpty) {
      final pitRef = pitSnapshot.docs.first.reference;
      final pitData = pitSnapshot.docs.first.data();
      final currentVol = (pitData['currentVolume'] as num?)?.toDouble() ?? 0.0;
      final newVol = round2(max(0.0, currentVol - (data.volume ?? 0)));
      batch.update(pitRef, {'currentVolume': newVol});
    }
  }

  try {
    await batch.commit();
  } catch (e) {
    // Rollback: delete sale and payment if they were created
    // In Firestore, if batch fails, nothing is written (atomic by nature)
    rethrow;
  }

  // Log
  await logService.logAction('SALE_RECORDED', 'Sale: ${data.totalPrice} MAD recorded');
  return Sale(id: saleRef.id, ...);
}
```

### 8.4 Client Balance Computation

```dart
Future<double> getClientBalance(String clientId) async {
  final clientRef = FirebaseFirestore.instance.doc('clients/$clientId');

  // Sum all non-deleted debts
  final debtsSnap = await FirebaseFirestore.instance
      .collection('debts')
      .where('clientId', isEqualTo: clientRef)
      .where('isDeleted', isEqualTo: false)
      .get();
  final debtTotal = debtsSnap.docs.fold<double>(
    0.0, (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0));

  // Sum all COMPLETED non-deleted payments
  final paymentsSnap = await FirebaseFirestore.instance
      .collection('payments')
      .where('clientId', isEqualTo: clientRef)
      .where('status', isEqualTo: 'COMPLETED')
      .where('isDeleted', isEqualTo: false)
      .get();
  final paymentTotal = paymentsSnap.docs.fold<double>(
    0.0, (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0));

  return round2(debtTotal - paymentTotal);
}
```

### 8.5 Check Lifecycle State Machine

```dart
class CheckLifecycle {
  static Future<void> clearCheck(String paymentId) async {
    final ref = FirebaseFirestore.instance.collection('payments').doc(paymentId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Payment not found');
      if (snap.data()!['status'] == 'COMPLETED') return; // No-op
      tx.update(ref, {
        'status': 'COMPLETED',
        'clearedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    });
    await logService.logAction('CHECK_CLEARED', 'Check $paymentId cleared');
  }

  static Future<void> rejectCheck(String paymentId) async {
    final ref = FirebaseFirestore.instance.collection('payments').doc(paymentId);
    await ref.update({
      'status': 'REJECTED',
      'updatedAt': Timestamp.now(),
    });
    await logService.logAction('CHECK_REJECTED', 'Check $paymentId rejected');
  }
}
```

---

## 9. UI Widget Tree

### Main Layout (DashboardPage)

```
DashboardPage (Scaffold with responsive layout)
├── EditorialTickerBar
│   ├── ThemeToggle icon button
│   ├── LanguageCycle button (EN/FR/AR)
│   ├── QuickPriceDisplay (fuels + prices)
│   ├── UserBadge (name·role)
│   ├── VersionDisplay
│   ├── LiveClock (updating)
│   └── SignOutButton
├── Body (Row: Sidebar + MainContent)
│   ├── Sidebar (min-width: 1024px → 220px; 768-1023 → 60px mini + overlay)
│   │   ├── Logo "PNA Service"
│   │   ├── NavSection (permission-filtered)
│   │   │   ├── NavItem (icon + label + active indicator)
│   │   │   └── ExpandableSubItems (animate)
│   │   └── Version footer
│   ├── MainContent (Expanded, scrollable)
│   │   ├── AnimatedSwitcher → PageView
│   │   │   ├── AdminDashboardPage | WorkerDashboardPage
│   │   │   ├── PitsPage, PumpsPage, FuelPage, ProductsPage
│   │   │   ├── ShiftsPage, ClientsPage, LedgerPage
│   │   │   ├── WorkersPage, ExpensesPage
│   │   │   ├── ReportsPage
│   │   │   ├── ImportsPage (tabbed)
│   │   │   ├── RoleManagementPage, SystemLogsPage, SettingsPage
│   │   │   └── ...
│   │   └── FabSpeedDial (floating, draggable)
│   │       ├── QuickPrice
│   │       ├── RecordSale
│   │       ├── RecordPayment
│   │       ├── RecordDebt
│   │       ├── AddClient
│   │       ├── AddExpense
│   │       └── StartShift
│   └── BottomNavBar (max-width: 767px)
│       ├── PrimaryTab (8 items, scrollable)
│       └── MoreMenu (popup with 7 secondary items)
└── QuickFuelPriceModal (overlay)
```

### AdminDashboardPage Widget Breakdown

```
AdminDashboardPage
├── Validation: isAdmin check → MutationLocked if not
├── ThreePillarKpiGrid
│   ├── KpiCard("Total Fuel Sales", volume↓ + "L", revenue↓ + "MAD", primary color)
│   ├── KpiCard("Total Product Sales", count↓ + "items", revenue↓ + "MAD", success color)
│   └── KpiCard("Total Unpaid Debts", count↓, value↓ + "MAD", warning color)
├── FuelPricesPanel
│   ├── Title + QuickEdit button (Pencil icon, admin only)
│   └── FuelTypeCards (colored dot + name + price/L)
├── FuelSalesByTypePanel
│   └── FuelTypeCards (name + volume + value)
├── LastShiftWidget (collapsible)
├── TwoColumnGrid
│   ├── ShiftPerformanceChart (BarChart, Week/Month toggle, Revenue/Volume/Both)
│   └── RevenueTrendPanel (total revenue + pending advances count)
├── TwoColumnGrid
│   ├── DebtStatus (due count+value, critical 60d+ count+value)
│   └── PaymentStatus (rejected count+value, due count+value)
├── TwoColumnGrid
│   ├── CriticalAlerts (pending advances, exceeded credit limits, or "SYSTEM OPERATIONAL")
│   └── RecentActivity (last 5 sales: client, product, volume, amount, time, method)
└── Footer ("Dashboard Overview · 01 / 04")
```

### WorkerDashboardPage Widget Breakdown

```
WorkerDashboardPage
├── if no active shift:
│   ├── WorkerShiftWorkflow
│   │   ├── Phase: SETUP
│   │   │   ├── ShiftPumpMatrix (grouped blocks, check toggles, reference counters)
│   │   │   └── "Initialize Terminals" button
│   │   └── Phase: TERMINAL_ENTRY
│   │       ├── ProgressBar (steps per pump)
│   │       ├── PumpCard (name, fuel, block, reference value)
│   │       ├── TerminalKeypad (large readout, blinking cursor, validation)
│   │       └── Next/Submit buttons
│   └── LastShiftWidget (previous shift summary)
│
├── elif ending shift:
│   └── WorkerShiftTermination
│       ├── Phase: END_READINGS
│       │   ├── ProgressBar (color-coded per pump type)
│       │   ├── PumpLabel (block + color badge + position)
│       │   ├── TerminalKeypad / MechanicalCounterReader (OCR toggle)
│       │   └── CONFIRM button
│       └── Phase: MASTER_AUDIT
│           ├── LeftColumn (2/3)
│           │   ├── PumpDeltaSummary (grouped blocks, volume + revenue, expandable)
│           │   └── SystemProtocols (Pit Deduction toggle)
│           └── RightColumn (1/3)
│               └── LiquidityAuditSidebar (pump sales total, ledger payments,
│                                         expected net cash, audit variance)
│           └── "ARCHIVE SHIFT" button
│
├── else (active shift):
│   ├── "Operations Terminal" header + shift session info
│   ├── RecordSaleForm (inline form, spans full width)
│   │   ├── SaleTypeToggle (FUEL/PRODUCT/SERVICE)
│   │   ├── AssetSelect (gas types / products / services with prices)
│   │   ├── Volume + Price auto-calc fields
│   │   ├── PaymentProtocolCard (CASH/CHECK toggle + check fields)
│   │   └── ClientIDSidebar (client select + fleet fields + notes)
│   ├── ShiftControls
│   │   ├── "End Shift" button (primary, StopCircle icon)
│   │   └── "Cancel Shift" button (secondary, wrapped in ConfirmAction)
│   └── SalaryAdvanceSection
│       ├── RequestForm (amount input + Request button)
│       └── RecentRequestsList (max 5, with status badges)
```

### LedgerPage (Transaction Timeline) Widget Breakdown

```
LedgerPage
├── SummaryKpiBar
│   ├── KpiCard("Revenue", blue)
│   ├── KpiCard("Collected", emerald)
│   ├── KpiCard("Outstanding", amber)
│   └── KpiCard("Net", teal/rose)
├── FilterBar
│   ├── DatePresets: ALL/TODAY/WEEK/MONTH/CUSTOM (pill buttons)
│   ├── TypeFilter: ALL/SALES/PAYMENTS/DEBTS
│   └── SearchInput (client name + keyword)
├── RecordTransactionButton (full-width teal, Ctrl+K)
└── VirtualizedTransactionList
    └── TransactionRow (expandable)
        ├── Collapsed: # / Date / Type badge / Client / Amount / Status badge / Payment icon
        └── Expanded:
            ├── Sale: product, volume, unit price, driver, plate, payment, notes, notes → "Void" button
            ├── Payment PENDING: "Clear"(emerald) / "Reject"(rose) buttons
            ├── Payment COMPLETED: "Reopen"(amber) button
            ├── Payment: "Delete"(confirm) button
            └── Debt: "Mark Paid"(amount input + button) / "Delete"(confirm) button
```

---

## 10. Deployment

### Firebase Project Setup

```bash
firebase init
# Select: Firestore, Authentication, Storage, Functions, Hosting
firebase deploy
```

### Firebase Functions

Three Cloud Functions needed:

1. **onCreateUser** — Sets custom claims (`role: "Worker"` default), creates Firestore profile doc
2. **shiftChainValidator** — Callable function: validates shift chain before creation
3. **cleanupOldLogs** — Scheduled function (daily): deletes logs where `ttlExpiry < now`

### CI/CD (GitHub Actions)

```yaml
name: Flutter Web CI/CD
on:
  push:
    branches: [main]
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
```

### Required Flutter Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  firebase_core: ^3.x
  firebase_auth: ^5.x
  cloud_firestore: ^5.x
  firebase_storage: ^12.x
  firebase_functions: ^5.x
  google_mlkit_text_recognition: ^0.x
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  go_router: ^14.x
  intl: ^0.19.x
  excel: ^4.x
  pdf: ^3.x
  printing: ^5.x
  fl_chart: ^0.x
  connectivity_plus: ^6.x
  flutter_local_notifications: ^18.x
  share_plus: ^10.x
  path_provider: ^2.x
  camera: ^0.x
  image: ^4.x
  shimmer: ^3.x
  cached_network_image: ^3.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.x
  riverpod_generator: ^2.x
  build_runner: ^2.x
  mockito: ^5.x
  firebase_auth_mocks: ^0.x
  cloud_firestore_mocks: ^0.x
```

---

## Summary

This Flutter + Firebase replication preserves all 20+ entities, 15+ business formulas, 9 report types, 1434 translation keys across 3 languages, 20 UI views, 4 user roles, and the complete worker/admin/client workflows of the original SS-RAGRAGA Station OS. The key architectural decisions are:

1. **Firestore over SQL:** Accept NoSQL query limitations by designing proper composite indexes and using client-side joins where needed
2. **Riverpod for state:** Real-time streams for live data, computed providers for dashboard metrics
3. **Batch writes for atomicity:** Sale + payment + pit deduction all succeed or fail together
4. **Shift chain as client-side logic:** Sort → group → compute volume/revenue, driven by fetched shiftPump data
5. **ML Kit for OCR:** Replace Gemini AI with on-device text recognition for mechanical counter reading
6. **A4 PDF reports** via `pdf`/`printing` packages instead of HTML `window.print()`
7. **Responsive shell:** One codebase adapts to phone/tablet/desktop with GoRouter and screen-dependent layouts
