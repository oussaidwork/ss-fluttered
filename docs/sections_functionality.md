# Sections Functionality Reference

All 16 sidebar menu entries — their view components, sub-views, element trees, data sources, and CRUD capabilities.

---

## 1. Dashboard

| Property | Value |
|---|---|
| **View Component** | `Dashboard.tsx` renders `AdminDashboard.tsx` (admin) or `MissionDashboard.tsx` (worker) |
| **Icon** | `LayoutDashboard` |
| **Permission Section** | `Dashboard` |
| **Sidebar Order** | 1 |

### Element Tree

- **Admin Dashboard** (`AdminDashboard.tsx`):
  - Fuel Sales by Type (pie chart, colored by fuel type)
  - Debt Status (cards: due count, critical count, total unpaid)
  - Payment Status (cards: rejected count, due count)
  - Last Shift widget (summary of most recent closed shift)
  - Sales vs. Pump Reconciliation (pump-derived totals vs. cash/sales)
  - Bar charts (revenue / volume / both) — week / month period toggle
  - Quick Fuel Price modal (open from FAB or inline)

- **Worker Dashboard** (`MissionDashboard.tsx`):
  - Active shift status
  - Quick actions

| Data Source | Description |
|---|---|
| `useDashboardMetrics()` | totalFuelSales, totalProductSales, totalUnpaidDebts, fuelSalesByType, paymentsRejected, paymentsDue, clientsExceededLimit |
| `useStationStore.allSales` | All sales records |
| `useStationStore.allShifts` | All shifts (lazy-fetched) |
| `services.sales.getAllDebts()` | Debt list |
| `services.station.getGasTypes()` | Fuel type definitions |

### CRUD
- **Create/Update**: Quick Fuel Price update (via modal → creates price history record)
- **Read**: All metrics, charts, widgets
- **Delete**: None

---

## 2. Clients

| Property | Value |
|---|---|
| **View Component** | `ClientsView.tsx` |
| **Icon** | `Users` |
| **Permission Section** | `Clients` |
| **Sidebar Order** | 2 |

### Element Tree

- **Tab bar**: `active` / `archived` client lists
- **Search bar**: free-text search across client names
- **Alphabetical filter**: A–Z letter buttons
- **Client cards** (list):
  - Name, phone, credit limit, outstanding balance, total sales, total paid
  - Status indicator (good/limit exceeded/archived)
  - Inline edit (name, phone, credit limit)
  - Archive / Restore / Delete actions
- **Client detail** (`ClientTransactionTable.tsx`):
  - Tabs: `sales` / `payments` / `debts`
  - Filtered transaction list per client
- **Modals**:
  - `AddClientDialog` — create new client (name, phone, creditLimit)
  - `UniversalSaleModal` — record fuel/product sale for a client
  - Record Payment dialog — amount, method, details
  - Record Debt dialog — driver name, amount, due date

| Data Source | Description |
|---|---|
| `useAllClients()` | All clients with computed totals |
| `useSalesList()` | All sales |
| `useDebtsList()` | All debts |
| `usePaymentsList()` | All payments |

### CRUD
- **Create**: Client, Sale, Payment, Debt (via dialogs)
- **Read**: Client list, transactions per client, aggregated totals
- **Update**: Client name/phone/creditLimit (inline), archive/restore toggle
- **Delete**: Client (with confirmation), requires management permission

---

## 3. Ledger

| Property | Value |
|---|---|
| **View Component** | `LedgerView.tsx` |
| **Icon** | `BookOpen` |
| **Permission Section** | `Sales` |
| **Sidebar Order** | 3 |

### Element Tree

- **Summary stats bar**:
  - Total Sales revenue
  - Total Payments received
  - Net Balance (sales − payments)
  - Outstanding Debt
- **Filter tabs**: `all` / `sale` / `payment`
- **Unified transaction feed** (sorted by date descending):
  - Each row: date, client name, type (Fuel / Payment / Debt), details (fuel type or notes), quantity (L), unit price, amount (MAD), payment method
  - Color-coded: sales = outgoing arrow, payments = incoming arrow

| Data Source | Description |
|---|---|
| `useSalesList()` | All sales (filtered: `!is_deleted`) |
| `useDebtsList()` | All debts (filtered: `!is_deleted`) |
| `usePaymentsList()` | All payments (filtered: `!is_deleted && status === COMPLETED`) |

### CRUD
- **Read**: Unified financial audit trail
- **Create/Update/Delete**: None (view-only aggregation)

---

## 4. My Shift

| Property | Value |
|---|---|
| **View Component** | `MyShiftWorkflow.tsx` (phase-based orchestrator) |
| **Icon** | `PlayCircle` |
| **Permission Section** | `My Shift` |
| **Sidebar Order** | 4 |

### Phase Flow

| Phase | Component | Description |
|---|---|---|
| `OPEN` | `LaunchBay` | One-click shift start: worker name, optional note |
| `ACTIVE` | `TransactionPod` | Record fuel/product sales during active shift |
| `PUMP_SELECT` | `PumpSelection` | Select which pumps were active in this shift |
| `END_READINGS` | `FinalApproach` | Enter end analog counter readings (previous readings auto-loaded per pump) |
| `AUDIT_PRINT` | `AuditPrintSubmit` | Review pump totals vs. recorded sales, print Z-report, submit close |
| `DONE` | `ShiftSummary` | Post-termination confirmation summary |

### State Machine

- Phase is derived: `activeShift ? 'ACTIVE' : 'OPEN'`
- Close sub-flow overrides phase: `OPEN → PUMP_SELECT → END_READINGS → AUDIT_PRINT → DONE`
- Cancel close returns to `ACTIVE`

### Key Sub-State

| State | Type | Description |
|---|---|---|
| `selectedPumpIds` | `string[]` | Pumps selected for this shift |
| `endCounters` | `Record<string, { analog: string }>` | End counter readings per pump |

| Data Source | Description |
|---|---|
| `useStationStore.activeShifts` | Currently open shifts for this worker |
| `services.shifts` | Shift CRUD, termination, pump reading chain derivation |

### CRUD
- **Create**: Shift (on start), Sales (during ACTIVE phase), ShiftPump records (on close)
- **Read**: Active shift, pump chain data (last readings per pump)
- **Update**: Shift status (OPEN → CLOSED), end counters
- **Delete**: None (shift close is irreversible)

---

## 5. Pits

| Property | Value |
|---|---|
| **View Component** | `PitsView.tsx` |
| **Icon** | `Fuel` |
| **Permission Section** | `Station Management` |
| **Sidebar Order** | 5 |

### Element Tree (3 accordion sections)

#### Pits List
- Expandable cards: name, linked fuel type (gas_type_id), capacity (L), current volume (L), fill % bar
- Add pit: name, gas_type_id, capacity, current_volume
- Edit pit (inline dialog)
- Delete pit (with confirmation)

#### Refill History
- Table: date, pit name, volume added, cost/liter, total cost, supplier, fleet truck / driver / plate, notes
- Search bar + range filters (min/max volume, min/max price)
- Add refill: pit_id, volume_added, cost_per_liter, supplier_id, fleet_truck_id, fleet_driver_name, fleet_vehicle_plate, notes
- Edit / delete refill
- Print refills report

#### Fuel Suppliers
- List: name, contact phone, email, address
- Add / edit / delete supplier

| Data Source | Description |
|---|---|
| `services.station.getPits()` | All pits |
| `services.station.getGasTypes()` | Fuel type definitions |
| `services.station.getRefills()` | All refill records |
| `services.station.getFuelSuppliers()` | Fuel supplier list |

### CRUD
- **Create**: Pit, refill, supplier
- **Read**: Pits with current volume, refill history, supplier list
- **Update**: Pit capacity/volume/links, refill details, supplier info
- **Delete**: Pit, refill, supplier (with confirmation)

---

## 6. Pumps

| Property | Value |
|---|---|
| **View Component** | `PumpsView.tsx` |
| **Icon** | `Gauge` |
| **Permission Section** | `Station Management` |
| **Sidebar Sub-label** | Dispensing Pumps |
| **Sidebar Order** | 6 |

### Element Tree

- **View mode toggle**: group by group_id / flat list
- **Group filter dropdown**: filter by pump group (`all` or specific group number)
- **Search bar**: by pump name, pit name, group number
- **Pump cards**:
  - Name, linked pit → fuel type (color swatch), group, subgroup
  - Initial analog counter value
  - Active/inactive badge
  - Slide-reveal actions (edit, delete)
- **Add pump dialog**: name, pit_id, is_active, initial_analog_counter, color, group_id, subgroup
- **Edit pump dialog**: same fields as add, pre-filled
- **Delete pump** (with confirmation)

| Data Source | Description |
|---|---|
| `services.station.getPumps()` | All dispensing pumps |
| `services.station.getPitStatus()` | All pits (for pit→fuel type mapping) |

### CRUD
- **Create**: Pump
- **Read**: Pumps with group/subgroup structure, linked fuel type
- **Update**: Pump details, group assignment, active status
- **Delete**: Pump (with confirmation)

---

## 7. Fuel

| Property | Value |
|---|---|
| **View Component** | `FuelView.tsx` |
| **Icon** | `Droplets` |
| **Permission Section** | `Station Management` |
| **Sidebar Order** | 7 |

### Element Tree

#### Fuel Types (Gas Types)
- List cards: name, `price_in` (cost), `price_out` (selling price), color swatch
- Add fuel type: name, price_in, price_out, color
- Edit / delete fuel type

#### Price History
- `FuelPriceChart` component: line chart of price evolution over time
- Filters:
  - Date range: ALL / TODAY / WEEK / MONTH / CUSTOM (start/end)
  - Fuel type multi-select (checkboxes)
  - Recorded by (user filter)
  - Price range (min/max)
- Paginated table: 12 entries per page
- Print price history report

#### Quick Price Modal
- `QuickFuelPriceModal`: fast batch-update of all current fuel prices
- Accessible from FAB or header button

| Data Source | Description |
|---|---|
| `services.station.getGasTypes()` | All fuel type definitions |
| `services.station.getFuelPriceHistory(limit)` | Historical price entries |

### CRUD
- **Create**: Fuel type, price history record
- **Read**: Fuel types, price history with filters + pagination + chart
- **Update**: Fuel type name/prices/color, batch price update
- **Delete**: Fuel type

---

## 8. Products

| Property | Value |
|---|---|
| **View Component** | `ProductsView.tsx` |
| **Icon** | `Package` |
| **Permission Section** | `Station Management` |
| **Sidebar Sub-label** | Retail Stock |
| **Sidebar Order** | 8 |

### Element Tree

- **View mode toggle**: grid / list / category group
- **Search bar**: by product name
- **Category filter**: FUEL_RELATED / LUBRICANTS / CONVENIENCE / SERVICES / OTHER
- **Product cards**:
  - Name, category (color-coded icon + badge), quantity, unit, selling price
  - Stock health indicator (circular ring):
    - `≤ 0` → Out of Stock (red, pulsing)
    - `< 5` → Critical (red, pulsing)
    - `< 15` → Low (amber)
    - `< 50` → Adequate (blue)
    - `≥ 50` → Healthy (green)
  - Add product: name, category, quantity, unit, price, barcode
  - Edit / delete product
- **Print stock report**

| Data Source | Description |
|---|---|
| `services.station.getProducts()` | All retail products |

### CRUD
- **Create**: Product
- **Read**: Products with category theming + stock health visualization
- **Update**: Product details, quantity, price
- **Delete**: Product (with confirmation)

---

## 9. Shifts

| Property | Value |
|---|---|
| **View Component** | `ShiftsView.tsx` |
| **Icon** | `History` |
| **Permission Section** | `Shifts` |
| **Sidebar Order** | 9 |

### Element Tree

#### Shifts Tab
- **Date filter**: ALL / TODAY / WEEK / MONTH / CUSTOM (from/to)
- **Search bar**: by worker name, shift ID
- **Shift cards** (timeline):
  - Worker name, start time, end time, duration
  - Pump volume total, pump revenue total, sales count
  - Discrepancy amount
  - Status (OPEN / CLOSED)
  - Click → `ShiftDetailOverlay` (full pump readings, chain data, sales breakdown)
- **Actions per shift**: print pump indexes report, print sales report, delete shift
- **Export**: shifts to Excel, pump readings to Excel
- **Bulk print**: pump indexes report (all filtered)

#### Sales Tab
- **DataTable**: date, client name, fuel/product type, quantity, unit price, total, payment method
- **Filters**: date range, search
- **Print sales report (filtered date range)**
- **Export**: shifts to Excel

| Data Source | Description |
|---|---|
| `services.shifts.getAllShifts()` | All shifts with chain-derived pump data |
| `services.sales.getAllSales()` | All sales records |
| Domain entity `Shift` / `ShiftPump` | Canonical getters (volume, revenue, discrepancy) |

### CRUD
- **Read**: Shifts with full pump chain + sales breakdown
- **Delete**: Shift (with confirmation)
- **Create/Update**: None (shifts are created in My Shift workflow)
- **Print/Export**: Reports + Excel files

---

## 10. Imports

| Property | Value |
|---|---|
| **View Component** | Container in `Dashboard.tsx` — switches sub-view |
| **Icon** | `Database` |
| **Permission Section** | `Imports` |
| **Sidebar Order** | 10 |

### Sub-views

#### 10a. Shift Data Import (`ShiftDataImportView.tsx`)
- **Purpose**: Batch-import pump readings + auto-create shifts from Excel
- **Workflow**:
  1. Download import template (Excel with pump columns)
  2. Upload filled Excel file
  3. Parse: read pump readings, prices, dates
  4. Validate: detect missing/duplicate data
  5. Preview table: per-pump start analog, end analog, volume, revenue, price
  6. Batch-save: create shift + shift_pump records + optionally map existing sales
- **Additional**: Bulk end-time update for existing shifts

#### 10b. Pit Refill Import (`PitRefillImportView.tsx`)
- **Purpose**: Batch-import pit refill deliveries from Excel
- **Workflow**:
  1. Download import template
  2. Upload Excel → parse refill entries
  3. Auto-match pit names → pit IDs, supplier names → supplier IDs
  4. Auto-calculate profit margin (price_out − cost_per_liter)
  5. Preview table: pit, volume, cost/L, margin, date, truck driver, depot
  6. Batch-save refill records
- **Supports**: fleet truck info (driver, vehicle plate)

#### 10c. Client Data Import (`ClientDataImportView.tsx`)
- **Purpose**: Batch-import client transactions (sales, debts, payments) from Excel
- **Workflow**:
  1. Download multi-sheet import template
  2. Upload Excel → parse rows typed as SALE / DEBT / PAYMENT
  3. Auto-match or auto-create clients by name
  4. Preview table: row type, client, date, product, qty, price, amount, payment method
  5. Per-row status: PENDING / IMPORTED / VOIDED
  6. Batch-import: create sales + debts + payments records
  7. Void individual imported rows

| Data Source | Description |
|---|---|
| `services.shifts` | Shift/shift_pump creation |
| `services.station` | Pit/supplier/refill creation |
| `services.sales` | Client/sale/debt/payment creation |
| `XLSX` (SheetJS) | Excel parsing |

### CRUD
- **Create**: Batch insert pump readings, shifts, refills, sales, debts, payments, clients
- **Read**: Preview parsed data before import
- **Update**: Void imported records
- **Delete**: None

---

## 11. Expenses

| Property | Value |
|---|---|
| **View Component** | `ExpensesView.tsx` |
| **Icon** | `Receipt` |
| **Permission Section** | `Expenses` |
| **Sidebar Order** | 11 |

### Element Tree

- **DataTable**: description, category, amount, quantity, date (timestamp), recorded by
  - Categories: SALARIES / UTILITIES / MAINTENANCE / TAXES / SUPPLIES / RENT / OTHERS
- **Search bar**: by description
- **Date filter**: ALL / TODAY / WEEK / MONTH / CUSTOM (start/end)
- **Add expense dialog**: description, amount, category, quantity, date
- **Edit expense dialog**: same as add, pre-filled
- **Delete expense** (with confirmation)
- **ExpenseAccelerator**: quick-entry mode
  - Autocomplete on existing descriptions
  - One-click add with pre-filled category
  - Rapid multi-entry workflow
- **Print report** (filtered)
- **Export to Excel**

| Data Source | Description |
|---|---|
| `services.expenses.getAllExpenses()` | All expense records |

### CRUD
- **Create**: Expense
- **Read**: Expenses with search, category, and date filters
- **Update**: Expense details
- **Delete**: Expense (with confirmation)

---

## 12. Reports

| Property | Value |
|---|---|
| **View Component** | `ReportsView.tsx` |
| **Icon** | `BarChart3` |
| **Permission Section** | `Statistics` |
| **Sidebar Order** | 12 |

### Element Tree (all scoped to `DateRangePicker` selection)

| Report Widget | Component | Data Shown |
|---|---|---|
| Audit Summary | `AuditSummaryCards.tsx` | Pump-derived totals vs. ledger sales, variance, pump deltas |
| Revenue Insights | `RevenueInsights.tsx` | Daily revenue trend, revenue by fuel type, revenue share |
| Fuel Insights | `FuelInsights.tsx` | Pump deltas (name, gasType, color, volume, revenue, analogVolume, variance%), volume by fuel type |
| Expense Insights | `ExpenseInsights.tsx` | Expense by category (amount + %), daily expense trend |
| Debt Insights | `DebtInsights.tsx` | Debt aging buckets (30/60/90+ days), top debtors, debt status distribution |
| Client Insights | `ClientInsights.tsx` | Top clients by volume/revenue, client count |
| Worker Performance | `WorkerPerformance.tsx` | Worker stats: shifts count, total sales, volume, revenue (ranked) |

### Global Controls

- **DateRangePicker**: preset dates (7D / 30D / 90D / 1Y / ALL / CUSTOM)
- **Print All**: unified print layout across all widgets
- **Export to Excel**: all report data

| Data Source | Description |
|---|---|
| All services (sales, shifts, pumps, expenses, debts, workers) | Aggregated and cross-referenced |
| `computeWorkerStats()` | Per-worker performance metrics |
| `buildWorkerNameMap()` | Worker ID → name mapping |

### CRUD
- **Read**: Cross-domain analytical aggregation
- **Create/Update/Delete**: None (view-only dashboards)

---

## 13. Workers

| Property | Value |
|---|---|
| **View Component** | `WorkersView.tsx` |
| **Icon** | `Users2` |
| **Permission Section** | `Workers` |
| **Sidebar Order** | 13 |

### Element Tree

- **DataTable**: full name, email, phone, role (badge), monthly salary, remaining salary (fetched live), status
- **Search bar**: by name, email, role
- **Add worker dialog**: full_name, email, phone, role, monthly_salary
- **Inline salary edit**: click to edit monthly salary field
- **Row click → HRProfileView**:
  - Worker profile details
  - Shift history
  - Salary advances management
- **Salary advances section**:
  - List: description, amount, status (PENDING / APPROVED / REJECTED), date
  - Approve / Reject actions (with confirmation)
  - Create new advance

| Data Source | Description |
|---|---|
| `services.users.getProfiles()` | All worker profiles |
| `services.users.getSalaryAdvances()` | All salary advance requests |
| `services.users.getRemainingSalary(workerId)` | Computed remaining salary |

### CRUD
- **Create**: Worker profile, salary advance
- **Read**: Worker list, detailed profile + shift history, advance status
- **Update**: Monthly salary (inline), advance approval/rejection
- **Delete**: None visible in UI

---

## 14. System Logs

| Property | Value |
|---|---|
| **View Component** | `LogsView.tsx` |
| **Icon** | `Terminal` |
| **Permission Section** | `System Logs` |
| **Sidebar Order** | 14 |

### Element Tree

- **DataTable**: timestamp, action, recorded by (user name), details
- **Search bar**: by action name, user name, details text
- **Level filter**: ALL / INFO / WARN / ERROR
  - Auto-detected from action keywords:
    - ERROR = DELETE / ERROR / FAIL / WIPE
    - WARN = UPDATE / WARN / ADJUST
    - INFO = everything else
- **Date filter**: ALL / TODAY / WEEK / MONTH / CUSTOM (start/end)
- **Print logs report** (filtered)
- **Clear logs** button (requires `management` permission, with confirmation)

| Data Source | Description |
|---|---|
| `services.logs.getLogs(200)` | Last 200 system log entries |

### CRUD
- **Read**: Filtered + searchable log history
- **Delete**: Bulk clear all logs (with confirmation, management permission only)
- **Create/Update**: None (logs are created automatically by the system)

---

## 15. Role Management

| Property | Value |
|---|---|
| **View Component** | `RoleManagementView.tsx` |
| **Icon** | `Shield` |
| **Permission Section** | `Role Management` |
| **Sidebar Order** | 15 |
| **Access** | `SUPER_USER` only |

### Element Tree

- **Permission matrix**:
  - Rows = permission sections:
    - Dashboard, My Shift, Station Management, Sales, Shifts, Clients, Workers, Expenses, Imports, Statistics, Settings, System Logs, Role Management
  - Columns = user roles:
    - SUPER_USER, ADMIN, MANAGER, SUPERVISOR, OPERATOR, AUDITOR (all values from `UserRole` enum)
  - Each cell = toggle switch (grant = on, revoke = off)
- **Save button per row**: persists changes for that section to PocketBase
- **Loading state**: "Accessing Security Protocols..." with spinner

### Data Flow

| Step | Description |
|---|---|
| 1 | `getAllPermissions()` fetches all section→allowedRoles mappings |
| 2 | User toggles roles on/off for a section (local state) |
| 3 | Click Save → `updateSectionRoles(section, allowedRoles[])` |
| 4 | On success → `refreshAppPermissions()` reloads runtime permissions |

| Data Source | Description |
|---|---|
| `usePermissions().getAllPermissions()` | All permission rules |
| `usePermissions().updateSectionRoles()` | Persist changes |
| PocketBase collection `app_permissions` | Backend storage |

### CRUD
- **Read**: Full permission matrix
- **Update**: Role→section grant/revoke (per-section save)
- **Create/Delete**: None (sections are fixed)

---

## 16. Settings

| Property | Value |
|---|---|
| **View Component** | `SettingsView.tsx` |
| **Icon** | `Settings` |
| **Permission Section** | `Settings` |
| **Sidebar Order** | 16 |

### Element Tree

#### Interface
- **Theme selector**: Dark / Light / System (preview cards with animated selection)
- **Language toggle**: i18n locale switch

#### Station Configuration
- Station name (text input)
- Currency (select)
- Timezone (select)

#### Data Management
- **Export Data**: downloads station data as JSON file
- **Import Data**: upload JSON file to restore data
- **Database Reset**: destructive wipe (requires high-level permission, double confirmation)

#### Advanced
- **Bulk Edit Template**: download Excel template for bulk operations
- **Version Info**: display current app version (`src/lib/version.ts`)

| Data Source | Description |
|---|---|
| `useStationStore` | Current station configuration |
| `useTheme()` | Theme mode + setter |
| `services.station.updateStationSettings()` | Persist station config |
| `services.settings.exportData()` / `importData()` | Data portability |

### CRUD
- **Read**: Station config, theme, version
- **Update**: Station name/currency/timezone, theme, language
- **Create**: Exported data file (download)
- **Delete**: Database reset (destructive, with confirmation)
