# SS-RAGRAGA Station OS — Flutterization Execution Plan

> Based on: `APP_DESCRIPTION.md` (business requirements) → `FLUTTERIZING.md` (technical migration guide)
> **Target:** Flutter Web + Firebase (Firestore, Auth, Functions, Storage) deployment

---

## Phase 0: Project Scaffold & Foundation (Week 1)

### 0.1 Environment Setup
- [ ] Install Flutter 3.x SDK, create project `ss_ragraga_station_os`
- [ ] Run `firebase init` — enable Auth, Firestore, Storage, Functions, Hosting
- [ ] Add all dependencies from FLUTTERIZING §10 to `pubspec.yaml`
- [ ] Run `flutter pub get` + `build_runner` setup

### 0.2 Firebase Project Configuration
- [ ] Create Firebase project (e.g. `ss-ragraga-station-os`)
- [ ] Enable **Firebase Auth** with email/password sign-in
- [ ] Create **Firestore database** (production mode)
- [ ] Create **Firebase Storage bucket**
- [ ] Deploy **Firestore indexes** from `firestore.indexes.json` (see FLUTTERIZING §4)
- [ ] Deploy **Firestore Security Rules** from FLUTTERIZING §5
- [ ] Set up **Firebase Functions** (Node.js 20+)

### 0.3 Flutter Core Scaffold
- [ ] Create folder structure matching `lib/` tree from FLUTTERIZING §2
- [ ] Implement `core/constants/` — app constants, Firestore paths, report types
- [ ] Implement `core/utils/` — `round2()`, date utils, pump utils, revenue utils, permission utils
- [ ] Implement `core/theme/` — `app_theme.dart` (Material 3 light/dark), `app_colors.dart` (PNA brand: `#0066CC`, `#84CC16`, `#0B1220`), `app_typography.dart` (Inter, JetBrains Mono, Noto Naskh Arabic)
- [ ] Implement `core/errors/` — custom exception types, Firestore error handling

### 0.4 Navigation Shell & Router
- [ ] Set up **GoRouter** with auth redirects
- [ ] Build responsive layout: `DashboardPage` with `Sidebar` (≥1024px: 220px, 768-1023: 60px mini + overlay) and `BottomNavBar` (<768px)
- [ ] Implement `EditorialTickerBar` — theme toggle, language cycle (EN/FR/AR), user badge, live clock, sign-out
- [ ] Implement permission-filtered nav items (4 roles: Worker, Admin, SuperUser, Audit)

**Checkpoint:** App launches → shows login screen → auth redirects → responsive shell works

---

## Phase 1: Auth & User Management (Week 2)

### 1.1 Firebase Auth Integration
- [ ] Implement `firebase_auth_provider.dart` — login, logout, auth state stream
- [ ] Implement `auth_service.dart` — wrapper with email/password, session persistence
- [ ] Implement `auth_repository.dart` (domain interface) + Provider
- [ ] Build **Login Screen** (`login_page.dart`):
  - Split design on desktop (brand editorial left + form right)
  - Stacked layout on mobile
  - Dark form inputs with mono font
  - Loading splash: animated fuel icon + "Synchronizing Operational Data..."

### 1.2 User Profile Management
- [ ] Firebase Function: `onCreateUser` — set custom claims (`role: "Worker"` default), create `/users/{uid}` doc
- [ ] Implement `user_repository_impl.dart` — CRUD for user profiles
- [ ] Implement `user.dart` (entity), `user_converter.dart`
- [ ] Build `workers_page.dart` — HR profiles list with role badges, salary fields

### 1.3 Custom Claims & Permissions
- [ ] Implement Firebase custom claims listener (`role` claim)
- [ ] Implement `permission_utils.dart` — `canPerformActions()` by role + section
- [ ] Implement `app_permissions` collection CRUD
- [ ] Build `role_management_page.dart` — per-section permission editor

**Checkpoint:** Users can sign up, log in, get assigned roles, and see role-appropriate nav

---

## Phase 2: Core Data Entities & Converters (Week 3)

### 2.1 Domain Entities & Enums
Implement all entities from `domain/entities/` and `domain/enums/`:

| Entity | Enum(s) | Key Fields |
|--------|---------|------------|
| `GasType` | — | name, priceIn, priceOut, color |
| `Pit` | — | name, capacity, currentVolume, gasTypeId |
| `Pump` | — | name, isActive, initialAnalogCounter, groupId, subgroup, color, pitId |
| `Product` | — | name, price, priceIn, priceOut, unit, stockQuantity, category |
| `Service` | — | name, priceIn, priceOut, unit |
| `WorkShift` | `ShiftStatus.OPEN, CLOSED` | startTime, endTime, actualCash, workerId |
| `ShiftPump` | — | endAnalogCounter, priceAtShift, shiftId, pumpId |
| `Sale` | `SaleType.FUEL, PRODUCT, SERVICE` | volume, unitPrice, totalPrice, paymentTypeId, etc. |
| `Payment` | `PaymentStatus.PENDING, COMPLETED, REJECTED, CANCELLED` | amount, check fields, status |
| `Debt` | — | amount, dueDate, clientId |
| `Client` | — | name, phone, plateNumber, creditLimit, currentBalance |
| `Expense` | `ExpenseCategory.*` | description, amount, quantity, category |
| `PitRefill` | — | volume, costPerLiter, totalCost, profitMargin |
| `RefillPayment` | — | amount, transferReference, bankName |
| `FuelSupplier` | — | name, isActive |
| `FuelPriceHistory` | — | old/new priceIn, old/new priceOut |
| `SalaryAdvance` | `AdvanceStatus.PENDING, APPROVED, REJECTED` | amount, requestDate, resolutionDate |
| `LogEntry` | — | action, details, timestamp, userId |
| `AppPermission` | — | section, permittedRoles |
| `UserProfile` | `UserRole.*` | fullName, role, isActive, monthlySalary |
| `PaymentType` | — | name, code (CASH/CHECK/TRANSFER), icon |

### 2.2 Firestore Converters
- [ ] Implement all 18 converters in `data/firestore/converters/`
- [ ] Each converter: `toFirestore(Entity)` → `Map<String, dynamic>`, `fromFirestore(DocumentSnapshot)` → `Entity`
- [ ] Snake_case (PocketBase) → camelCase (Firestore) field mapping

### 2.3 Firestore Provider
- [ ] Implement `firestore_provider.dart` — `FirebaseFirestore` singleton instance
- [ ] Document reference helper: `docRef(collection, id)`

**Checkpoint:** All entities serializable to/from Firestore; unit tests pass for converters

---

## Phase 3: Repository Layer — Data Access (Week 4)

### 3.1 Repository Interfaces & Implementations
Implement all repositories in `domain/repositories/` (interfaces) and `data/repositories/` (Firestore impl):

| Repository | Key Methods | Write Pattern |
|------------|-------------|---------------|
| `AuthRepository` | login, logout, signUp, refreshToken, getProfile | Firebase Auth |
| `StationRepository` | getPits, getPumps, getGasTypes, getProducts, getServices + CRUD | StreamProvider (snapshot) |
| `ShiftRepository` | createShift, closeShift, getActiveShift, getAllShifts, getShiftPumps | Batch write |
| `SaleRepository` | recordSale (atomic), getSales, getTodaySales | WriteBatch |
| `ClientRepository` | getClients, getClientDetail, getLedger, computeBalance | Stream + computed |
| `PaymentRepository` | clearCheck, rejectCheck, getPendingPayments | Transaction |
| `ExpenseRepository` | CRUD | Direct writes |
| `RefillRepository` | recordRefill (atomic), getRefills | WriteBatch |
| `SupplierRepository` | CRUD | Direct writes |
| `LogRepository` | logAction, getLogs, cleanupOldLogs | Write + scheduled function |
| `PermissionRepository` | getPermissions, updatePermission | Direct writes |
| `UserRepository` | getProfiles, updateProfile, manageAdvances | Direct writes |

### 3.2 Key Atomic Operations
- [ ] **Atomic Sale Creation** (FLUTTERIZING §8.3): Batch create sale + payment + decrement pit volume
- [ ] **Shift Close with Pit Deduction** (FLUTTERIZING §8.2): Transaction to deduct pit volumes
- [ ] **Refill Recording**: Batch increment pit volume + create refill + optional refillPayment

### 3.3 Shift Counter Chain Algorithm
- [ ] Implement `deriveChainData()` (FLUTTERIZING §8.1):
  - Sort shiftPumps by pumpId ASC, then createdAt ASC
  - Track previous end counter per pump
  - Compute `volume = max(0, end - prevEnd)`, `revenue = round2(volume × priceAtShift)`
- [ ] Chain verification on shift creation: latest closed shift's `endTime` must match new `startTime`

### 3.4 Client Balance Computation
- [ ] Implement `getClientBalance(clientId)` (FLUTTERIZING §8.4):
  - Sum non-deleted debts minus sum of COMPLETED non-deleted payments
  - Update on every create/update/delete in client ledger

### 3.5 Check Lifecycle State Machine
- [ ] Implement `CheckLifecycle` (FLUTTERIZING §8.5):
  - `clearCheck()`: PENDING → COMPLETED + set clearedAt (transaction)
  - `rejectCheck()`: PENDING → REJECTED

**Checkpoint:** All repositories tested with Firestore emulator; atomic operations roll back on failure

---

## Phase 4: State Management — Riverpod Providers (Week 5)

### 4.1 Auth Providers
- [ ] `authStateProvider` — `StreamProvider<User?>`
- [ ] `userProfileProvider` — `FutureProvider.family<UserProfile, String>`
- [ ] `userRoleProvider` — `Provider<UserRole>`
- [ ] `canPerformActionsProvider` — `Provider.family<bool, String?>` (by section)

### 4.2 Station Data Providers (Stream — real-time)
- [ ] `gasTypesProvider`, `pitsProvider`, `pumpsProvider`, `productsProvider`, `servicesProvider`, `paymentTypesProvider`
- [ ] All use Firestore `.snapshot()` with proper error handling

### 4.3 Shift & Sale Providers
- [ ] `activeShiftsProvider` — stream of OPEN shifts
- [ ] `myActiveShiftProvider` — current user's active shift
- [ ] `allShiftsProvider` — stream of all shifts
- [ ] `shiftDetailProvider` — `FutureProvider.family` for shift summary with chain data
- [ ] `todaySalesProvider`, `allSalesProvider` — streams
- [ ] `salesTotalsProvider` — computed provider

### 4.4 Client & Payment Providers
- [ ] `clientsProvider` — stream
- [ ] `clientDetailProvider` — future (client + balance + recent transactions)
- [ ] `clientTransactionsProvider` — future (full ledger)
- [ ] `pendingPaymentsProvider` — computed from payments stream
- [ ] `checkClearingProvider` — `StateNotifierProvider`

### 4.5 Dashboard Metrics (Computed Provider)
- [ ] `dashboardMetricsProvider` — watches all source providers, computes:
  - Total Fuel Sales (L + MAD)
  - Total Product Sales (count + MAD)
  - Total Unpaid Debts (count + MAD)
  - Fuel Sales by Type
  - Shift Performance (week/month)
  - Debt Status (due, critical 60d+)
  - Payment Status (rejected, due)
  - Critical Alerts (pending advances, exceeded credit limits)

### 4.6 UI State Provider
- [ ] `uiProvider` — `StateNotifierProvider<UINotifier, UIState>`:
  - `activeView`, `activeSubView`, `showSidebarOverlay`, `isNavHidden`, `sidebarCollapsed`

**Checkpoint:** All providers constructed; dashboard metrics recompute reactively when data changes

---

## Phase 5: Shift Management Workflows (Weeks 6-7)

### 5.1 Shift Start Workflow
- [ ] **ShiftPumpMatrix** — grouped pump selection grid (Block A/B/C/D with colored check circles)
- [ ] **TerminalKeypad** — custom full-screen digit keypad: digits 0-9, Enter (NEXT), Backspace (DEL), Escape (CLR). Integer-only mode for analog counters
- [ ] **Counter input per pump** — validation: counter ≥ reference counter, max +5000
- [ ] **Shift creation** — WriteBatch: create `workShifts` (OPEN) + `shiftPumps` records + fetch gas prices + log `SHIFT_STARTED`
- [ ] **Draft persistence** — local state save/restore for shift-in-progress
- [ ] **Chain verification** — client-side check: latest closed shift's endTime matches new startTime

### 5.2 Shift End Workflow
- [ ] **End readings phase** — per-pump end_analog_counter entry via TerminalKeypad
- [ ] **MechanicalCounterReader** — camera OCR:
  - 7 states: idle → camera → preview → processing → success → error → manual
  - 7-segment pattern matching via ML Kit
  - Torch/flashlight toggle, front/back camera toggle, file upload fallback
- [ ] **Master Audit phase**:
  - PumpDeltaSummary table (grouped by block: volume + revenue per pump)
  - PitDeduction toggle
  - LiquidityAuditSidebar (pump sales total vs ledger payments recorded, expected net cash, variance)
- [ ] **Shift close** — Batch: update shiftPumps + update shift status to CLOSED + endTime
- [ ] **Pit deduction** — `runTransaction` to decrement each pit's `currentVolume`
- [ ] **Price change detection** — if price differs from previous shift → create `fuelPriceHistory` entry

### 5.3 Worker Dashboard (Terminal)
- [ ] Build complete `WorkerDashboardPage` (FLUTTERIZING §9 widget tree)
- [ ] Integrate RecordSaleForm inline + shift controls + salary advance section
- [ ] Build `LastShiftWidget` — collapsible summary of previous shift

**Checkpoint:** Full worker flow works — start shift → record sales → end shift → pit deducted → chain verified

---

## Phase 6: Point of Sale & Payment Recording (Week 8)

### 6.1 Sale Entry Components
- [ ] **RecordSaleForm** — inline full-width form:
  - `SaleTypeToggle` (FUEL / PRODUCT / SERVICE with segment button)
  - `AssetSelect` — dynamic dropdown: gasTypes / products / services
  - Volume + unitPrice → totalPrice auto-calculation (bi-directional)
- [ ] **PaymentProtocolCard** — CASH / CHECK toggle:
  - CASH → immediate COMPLETED
  - CHECK → PENDING, show bank name, check number, due date fields
- [ ] **ClientIDSidebar** — client selector dropdown:
  - PASS_BY option for cash walk-ins
  - Named clients with autocomplete
  - Driver name, vehicle plate, notes fields with historical autocomplete
- [ ] **Validation rules**: Asset+price+worker required; PASS_BY not allowed for CHECK

### 6.2 Atomic Sale Transaction
- [ ] Implement `recordSale()` (FLUTTERIZING §8.3):
  1. Create sale doc (batch)
  2. Create payment doc if `paidAmount > 0` (CASH→COMPLETED, CHECK→PENDING)
  3. Decrement pit volume for FUEL sales (find pit by gasType)
  4. Log `SALE_RECORDED`
  5. On failure → nothing written (Firestore batch atomicity)

### 6.3 Client Ledger Interaction
- [ ] Record Transaction slide-over panel (Ctrl+K):
  - SALE / PAYMENT / DEBT tabs
  - Client autocomplete search
  - Type-specific fields + validation
  - Commit to ledger

**Checkpoint:** All 3 sale types recordable; payment methods work; atomicity verified

---

## Phase 7: Client Ledger & Debt Management (Week 9)

### 7.1 Client CRUD
- [ ] Build `client_form.dart` — name, phone, plate, credit limit, address, email
- [ ] Build `clients_page.dart` — list with search, archive/restore

### 7.2 Transaction Timeline (LedgerPage)
- [ ] Build complete `LedgerPage` (FLUTTERIZING §9 widget tree):
  - SummaryKpiBar: Revenue, Collected, Outstanding, Net
  - FilterBar: date presets (All/Today/Week/Month/Custom), type filter, search
  - RecordTransactionButton
- [ ] **VirtualizedTransactionList** — expandable rows:
  - Collapsed: # / Date / Type badge / Client / Amount / Status badge / Payment icon
  - Expanded:
    - SALE: product, volume, unit price, driver, plate, payment, notes → "Void" button
    - PAYMENT PENDING: "Clear"(emerald) / "Reject"(rose)
    - PAYMENT COMPLETED: "Reopen"(amber)
    - DEBT: "Mark Paid"(amount input) / "Delete"(confirm)

### 7.3 Payment Lifecycle
- [ ] CASH → COMPLETED (immediate)
- [ ] CHECK → PENDING → `clearCheck()` or `rejectCheck()` via transaction
- [ ] TRANSFER → PENDING → `clearCheck()` or `rejectCheck()`
- [ ] Update client balance on every payment state change

### 7.4 Client Archive/Restore
- [ ] Soft-delete cascade: client + debts + payments + sales (set `isDeleted`)
- [ ] Restore: revert `isDeleted` on all cascade items

**Checkpoint:** Full client lifecycle — create, search, ledger view, payments, debt tracking, archive

---

## Phase 8: Inventory Management (Week 10)

### 8.1 Pits & Pumps CRUD
- [ ] `pits_page.dart` — pit list, create/edit, view refill history
- [ ] `pumps_page.dart` — pump list with group (Block A-D) + subgroup configuration, assign to pits
- [ ] `fuel_page.dart` — gas types CRUD, price history viewer, quick price edit modal

### 8.2 Products & Services CRUD
- [ ] `products_page.dart` — product CRUD with stock tracking, categories, active/inactive
- [ ] `services_page.dart` — service fee CRUD

### 8.3 Pit Refill Recording
- [ ] `refill_form.dart` — pit selector, volume, costPerLiter, totalCost (auto-calc), profitMargin, supplier, fleet details
- [ ] Atomic transaction: increment pit `currentVolume`, create pitRefill, create refillPayment
- [ ] `refill_payments` CRUD

### 8.4 Fuel Price Management
- [ ] Quick price edit modal — update priceIn/priceOut, auto-create fuelPriceHistory record
- [ ] Price history viewer with date range filter

**Checkpoint:** Full station inventory management operational

---

## Phase 9: Expenses, HR & Salary Advances (Week 11)

### 9.1 Expense Tracking
- [ ] `expenses_page.dart` — CRUD with category selector (SUPPLIES, MAINTENANCE, SALARY, UTILITIES, RENT, TRANSPORT, OTHER)
- [ ] Expense list with date range filter, category breakdown

### 9.2 Salary Advance Management
- [ ] Worker: request form (amount → PENDING status)
- [ ] Admin: approve/reject with resolution date and resolved_by
- [ ] Optional: record approved advances as expenses
- [ ] Status workflow: PENDING → APPROVED/REJECTED

### 9.3 Data Import System
- [ ] Tabbed imports page:
  - **Shift Import** (Excel with pump readings) → Cloud Function
  - **Pit Refill Import** (Excel with supplier + payment) → Cloud Function
  - **Client Data Import** (Excel/JSON: sales + payments + debts) → Cloud Function
- [ ] All imports: resolve foreign keys by name (case-insensitive), rollback on failure

**Checkpoint:** Financial operations complete — expenses, advances, imports

---

## Phase 10: Reporting & Printing (Week 12)

### 10.1 Report Component Architecture
- [ ] Base report widget pattern: header (logo + title) → info boxes → data table → summary row → footer
- [ ] Use `pdf` + `printing` packages for A4 formatted documents

### 10.2 Report Implementations
| Report | Data Source | Summary |
|--------|-------------|---------|
| Pump Indexes Report | ShiftPump chain data | Total volume per pump, fuel, price |
| Sales Report | Sales (filtered by date) | Total revenue |
| Debts Report | Non-deleted debts | Total exposure |
| Payments Settlement Report | Payments (filtered by status) | Total collected |
| Pit Refill Report | PitRefills (by date) | Total volume refilled |
| Fuel Price History Report | FuelPriceHistory (by date) | Price change timeline |
| Audit Log Report | Logs (filtered) | Timestamped action list |
| Shift Summary Report | WorkShifts + ShiftPumps | Per-shift: worker, pumps, volume, revenue |

### 10.3 Statistics & Charts (Admin Dashboard)
- [ ] **ShiftPerformanceChart** — Bar chart: Week/Month toggle, Revenue/Volume/Both
- [ ] **FuelSalesChart** — Per-type fuel sales breakdown
- [ ] **KPI Cards** — animated metric displays

**Checkpoint:** All 8 report types print to A4; charts render correctly

---

## Phase 11: i18n, RTL, Polish & Edge Cases (Week 13)

### 11.1 Internationalization
- [ ] Generate 3 ARB files: `app_en.arb` (1434 keys), `app_fr.arb` (1434 keys), `app_ar.arb` (1440 keys + RTL)
- [ ] Implement `i18n_service.dart` — locale switching persisted in localStorage
- [ ] Language cycle button (EN → FR → AR → EN) in EditorialTickerBar

### 11.2 RTL Support
- [ ] Arabic: auto-set `Directionality` to RTL, mirrored sidebar/nav, right-aligned forms
- [ ] Noto Naskh Arabic font family for Arabic text

### 11.3 UI Polish
- [ ] FAB Speed Dial — 7 quick actions, draggable position (persisted), rotation animation, permission-filtered
- [ ] Loading/splash screen — animated fuel icon + "Synchronizing Operational Data..."
- [ ] Error handling — global error handler with toast notifications, retry logic
- [ ] Offline support — Firestore `enablePersistence()`, connectivity monitoring

### 11.4 Edge Cases & Validation
| Scenario | Handling |
|----------|----------|
| Pit volume approaches 0 | Math.max(0, ...) guard + server-side Function hook |
| Shift chain gap | Block shift creation if `startTime != latestClosedShift.endTime` |
| Sale during inactive shift | Prevent: require OPEN shift |
| Concurrent check clearing | Firestore transaction prevents race |
| Negative analog readings | max(0, end - prevEnd) |
| Empty client ledger | Show "No transactions" state |
| Report with no data | Empty state template |

**Checkpoint:** 3 languages tested, RTL verified, offline mode works, edge cases handled

---

## Phase 12: Firebase Cloud Functions (Week 14)

### 12.1 Cloud Functions Deployment
| Function | Trigger | Purpose |
|----------|---------|---------|
| `onCreateUser` | Auth `onCreate` | Set custom claims (`role: "Worker"`), create `/users/{uid}` profile doc |
| `shiftChainValidator` | Callable | Validate shift chain before creation (server-side guard) |
| `cleanupOldLogs` | Scheduled (daily) | Delete logs where `ttlExpiry < now` (90-day TTL) |
| `pitVolumeGuard` | Firestore `onUpdate` (pits) | Reject negative pit volumes at server level |

### 12.2 Deployment Infrastructure
- [ ] Dockerize Flutter build for web
- [ ] GitHub Actions CI/CD (FLUTTERIZING §10):
  - Test → Build web → Deploy to Firebase Hosting
- [ ] Firebase Hosting configuration with redirects for SPA

**Checkpoint:** Functions deployed, CI/CD pipeline running

---

## Phase 13: Testing & QA (Week 15)

### 13.1 Unit Tests
- [ ] All converter serialization/deserialization
- [ ] Shift chain algorithm (`deriveChainData`)
- [ ] Rounding (`round2`)
- [ ] Client balance computation
- [ ] Check lifecycle state machine
- [ ] Permission filtering logic

### 13.2 Widget Tests
- [ ] Login screen flow
- [ ] TerminalKeypad input validation
- [ ] RecordSaleForm field dependencies
- [ ] LedgerPage filter bar behavior

### 13.3 Integration Tests
- [ ] Full worker flow: login → start shift → record sale → end shift → verify pit deduction
- [ ] Admin flow: login → create pit/pump → view dashboard → clear check → print report
- [ ] Atomic sale with Firestore emulator (verify batch rollback)

### 13.4 Performance
- [ ] List virtualization for client ledger (1000+ transactions)
- [ ] Deferred loading for heavy pages (reports, imports)
- [ ] Shrinkwrap to prevent overflow

**Checkpoint:** Test coverage ≥80% on core business logic

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
│  Pages (20+) │ Widgets (40+) │ Charts │ Reports     │
├─────────────────────────────────────────────────────┤
│              Riverpod State Management               │
│  StreamProviders (real-time) │ FutureProviders       │
│  Computed Providers (dashboard metrics)               │
├─────────────────────────────────────────────────────┤
│              Domain Layer (Pure Dart)                │
│  Entities (20) │ Enums (6) │ Repository Interfaces   │
│  Business Logic (round2, chain, balance)             │
├─────────────────────────────────────────────────────┤
│            Data Layer (Firebase-specific)            │
│  Converters (18) │ Repository Impls (11)             │
│  Auth Provider │ Firebase Singleton                  │
├─────────────────────────────────────────────────────┤
│         Firebase Backend (PaaS)                      │
│  Firestore │ Auth │ Functions │ Storage │ Hosting    │
└─────────────────────────────────────────────────────┘
```

## Dependency Graph (Build Order)

```
Phase 0 (Scaffold)
  └─→ Phase 1 (Auth)
       └─→ Phase 2 (Entities + Converters)
            └─→ Phase 3 (Repositories)
                 └─→ Phase 4 (Providers)
                      ├─→ Phase 5 (Shifts) ──→ Phase 6 (POS) ──→ Phase 7 (Clients)
                      ├─→ Phase 8 (Inventory)
                      ├─→ Phase 9 (HR/Expenses/Imports)
                      └─→ Phase 10 (Reports) ──→ Phase 11 (i18n/Polish)
                                                    └─→ Phase 12 (Cloud Functions)
                                                         └─→ Phase 13 (Testing)
```

## Key Metrics

| Metric | Target |
|--------|--------|
| Collections migrated | 20 (PocketBase) → 20 (Firestore) |
| Entity classes | 20 entities + 6 enums |
| Repository interfaces | 11 interfaces, 11 implementations |
| Riverpod providers | ~30 providers |
| Page views | 20+ pages |
| Translation keys | 1434 × 3 languages |
| Composite indexes | 13 required |
| Security rules | 18 resource patterns |
| Cloud Functions | 4 (3 triggers + 1 callable) |
| Sprint duration | 15 weeks (13 dev + 2 buffer) |