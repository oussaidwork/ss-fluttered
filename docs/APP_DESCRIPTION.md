# SS-RAGRAGA Station OS — Application Description

## 1. App Identity & Purpose

**Product Name:** SS-RAGRAGA Station OS (aka "SS-E-RAGRAGA")

**Developer:** PNA Service

**Version:** 0.8.0

**Platform:** Web application (SPA) — target for Flutter + Firebase web

**Purpose:** Industrial-grade Point-of-Sale (POS) and operations management platform for fuel/gas stations in the Moroccan market. It is a vertically-integrated system covering every aspect of station operations: fuel dispensing, inventory management, shift management for pump attendants, client/credit ledger, expense tracking, HR and salary advances, and robust reporting with A4-formatted printed reports and Excel exports.

---

## 2. Target Users

| Role | Description | Permissions |
|------|-------------|-------------|
| **Worker** | Pump attendant / cashier | Record sales, start/end shifts, view operational sections (sales, shifts, expenses), request salary advances |
| **Admin** | Station manager | Full CRUD on pumps, pits, products, users, expenses, all reports, check clearing, salary advance approval, data imports |
| **SuperUser** | System administrator | Full system access, user management, role management, database reset, all admin capabilities |
| **Audit** | Read-only inspector | View-only access to all reports and system logs |

---

## 3. Core Functional Modules

### 3.1 Shift Management

The shift system is the heart of the app. Each pump attendant (Worker) starts a shift by selecting which pumps they will operate and recording the initial analog counter readings. At shift end, they record the final counter readings, and the system computes:

- **Volume sold per pump** = `max(0, end_analog_counter - previous_end_analog_counter)`
- **Revenue per pump** = `round2(volume × price_at_shift)`
- **Total shift revenue** = sum of all pump revenues
- **Pit volume deduction** = each pit's `current_volume` is decremented by the total volume dispensed from its pumps

Shifts chain together: each shift's `start_time` must match the previous closed shift's `end_time`. This "counter chain" ensures no gaps or overlaps in pump readings.

**Shift states:** `OPEN` → `CLOSED`

### 3.2 Point of Sale (POS)

Three sale types:

| Type | Description | Fields |
|------|-------------|--------|
| **FUEL** | Fuel dispensing by gas type | gas_type, volume (L), unit_price, total_price, client, driver/vehicle, payment method |
| **PRODUCT** | Shop product sale | product, quantity, unit_price, total_price, client, payment method |
| **SERVICE** | Service fee | service, total_price, client, payment method |

**Payment methods:**

| Method | Status on Creation | Workflow |
|--------|-------------------|----------|
| **CASH** | COMPLETED immediately | Immediate settlement |
| **CHECK** | PENDING | Must be cleared or rejected by admin later |
| **TRANSFER** | PENDING | Must be cleared or rejected by admin later |
| **DEBT** | Recorded as SALE + DEBT | Client balance increases, tracked in ledger |

**Atomic transaction:** A sale creation is an atomic operation that:
1. Creates the sale record
2. Creates the payment record (if paid > 0)
3. Decrements the pit volume (if FUEL sale)
4. On failure, rolls back all steps

### 3.3 Inventory Tracking

**Pits (Underground Fuel Tanks):**
- Each pit has: name, capacity (L), current_volume (live), gas_type relation
- Volume decreases when shifts close (fuel dispensed from pumps)
- Volume increases when pit refills are recorded
- Cannot go negative (Math.max(0, ...) on deduction, server-side guard)

**Pumps:**
- Each pump has: name, initial_analog_counter, pit relation, group_id, subgroup, color, is_active
- Analog counters track mechanical meter readings
- Multiple pumps can draw from the same pit

**Products (Shop Items):**
- Store items with: name, price (sell), price_in (cost), price_out (retail), unit, stock_quantity, category, is_active

**Services:**
- Service fees with: name, price_in, price_out, unit

### 3.4 Client & Debt Ledger

**Client records:** name, phone, plate_number, credit_limit, current_balance, address, email

**Ledger tracking:** Each client has a timeline of:
- **Sales** (fuel, product, service purchases)
- **Payments** (cash, check with clearing workflow)
- **Debts** (with due dates)

**Balance formula:** `current_balance = sum(debts) - sum(completed_payments)`

A positive balance means the client owes money. Credit limits are tracked but not hard-enforced at sale time.

### 3.5 Payment Lifecycle

```
CASH:     Created as COMPLETED (immediate settlement)
CHECK:    Created as PENDING → Admin clears → COMPLETED
                              → Admin rejects → REJECTED
TRANSFER: Created as PENDING → Admin clears → COMPLETED
                              → Admin rejects → REJECTED
```

**Check fields:** bank_name, check_number, due_date, cleared_at

### 3.6 Expense Tracking

Expenses recorded with: description, amount, quantity, category (SUPPLIES, MAINTENANCE, SALARY, UTILITIES, RENT, TRANSPORT, OTHER), timestamp, recorded_by

### 3.7 HR & Salary Advances

**Worker profiles:** name, role, is_active, monthly_salary

**Salary advances:** Workers can request advances against their salary. Admin approves/rejects.

**Advance states:** `PENDING` → `APPROVED | REJECTED`

Optionally records approved advances as expenses.

### 3.8 Fuel Price Management

Each gas_type has `price_in` (cost) and `price_out` (selling price). Price changes are tracked in `fuel_price_history` with old/new values, who changed them, and when. A quick price edit modal allows admin to update prices on the fly.

### 3.9 Audit Logging

All financial actions are automatically logged:
- Sale recorded, payment recorded, debt created
- Shift started/closed
- Expense recorded
- Inventory refill
- Check cleared/rejected
- Payment deleted/updated

Logs have a 90-day TTL (auto-cleaned daily via cron).

### 3.10 Data Imports

**Types:**
1. **Shift Data Import** — Bulk import of historical shifts with pump readings from Excel
2. **Pit Refill Import** — Import refill data from Excel with supplier details
3. **Client Data Import** — Import client sales, payments, and debts from Excel or JSON

### 3.11 Reports & Export (9 Report Types)

| Report | Content | Format |
|--------|---------|--------|
| **Pump Indexes Report** | Per-pump: name, fuel, price, volume (L), revenue (DH) | A4 print |
| **Sales Report** | Per-sale: time, client, product, volume, price, total, method | A4 print |
| **Debts Report** | Per-debt: client, date issued, due date, amount | A4 print |
| **Payments Settlement Report** | Per-payment: client, amount, method, status | A4 print |
| **Pit Refill Report** | Per-refill: pit, volume, cost, margin, date | A4 print |
| **Fuel Price History Report** | Price changes: fuel type, old/new prices, date, who | A4 print |
| **Audit Log Report** | Chronological action log | A4 print |
| **Shift Summary Report** | Per-shift: worker, pumps, volume, revenue | A4 print |
| **Statistics & Charts** | Admin dashboard with KPI cards, bar charts, trend lines | Live |

All reports are A4-formatted with logo, RTL support for Arabic, and auto-print via `window.print()`.

**Excel Export:** Shifts can be exported to multi-sheet Excel workbooks with carry-forward analog counter logic for bulk editing.

---

## 4. Complete Data Model

### 4.1 Entity-Relationship Map

```
gas_types ──1:N── pits ──1:N── pumps
gas_types ──1:N── fuel_price_history
gas_types ──1:N── sales (fuel sales only)

work_shifts ──1:N── shift_pumps ──N:1── pumps
work_shifts ──1:N── sales

users (worker) ──1:N── work_shifts
users (worker) ──1:N── sales
users ──1:N── salary_advances (as worker_id)
users ──1:N── salary_advances (as resolved_by)
users ──1:N── logs
users ──1:N── expenses (as recorded_by)
users ──1:N── pit_refills (as recorded_by)

clients ──1:N── sales
clients ──1:N── payments
clients ──1:N── debts

payment_types ──1:N── sales
payment_types ──1:N── payments

sales ──1:N── payments

fuel_suppliers ──1:N── pit_refills
pit_refills ──1:N── refill_payments
```

### 4.2 Collection Schemas

#### gas_types
| Field | Type | Required | Unique | Notes |
|-------|------|----------|--------|-------|
| id | text (PK) | auto | yes | |
| name | text | yes | yes | e.g. "Diesel", "Super" (max: 100 chars) |
| price_in | number (0–999999) | yes | no | Cost price per liter |
| price_out | number (0–999999) | yes | no | Selling price per liter |
| color | text | no | no | Display color (max: 20 chars) |
| is_deleted | bool | no | no | Soft delete flag |
| created | autodate | auto | — | |
| updated | autodate | auto | — | |

#### pits
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| name | text (max: 100) | yes | |
| capacity | number (0–999999) | yes | Max volume in liters |
| current_volume | number (0+) | no | Current fuel volume in pit |
| gas_type_id | relation → gas_types | no | maxSelect: 1 |
| is_deleted | bool | no | |

#### pumps
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| name | text (max: 100) | yes | |
| is_active | bool | no | |
| initial_analog_counter | number (0+) | no | Baseline meter reading |
| group_id | text (max: 50) | no | Block/group label (1=Block A, 2=Block B, 3=Block C, 4=Block D) |
| subgroup | text (max: 50) | no | Subgroup within block |
| color | text (max: 20) | no | Display color |
| pit_id | relation → pits | **yes** | Must be assigned to a pit |
| is_deleted | bool | no | |

#### products
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| name | text (max: 200) | yes | |
| price | number (0–999999) | yes | Selling price |
| price_in | number (0–999999) | no | Cost price |
| price_out | number (0–999999) | no | Retail price |
| unit | text (max: 20) | no | e.g. "L", "pc", "box" |
| stock_quantity | number (0–999999) | no | |
| category | text (max: 100) | no | Product category |
| is_active | bool | no | |
| is_deleted | bool | no | |

#### services
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| name | text (max: 200) | yes | |
| price_in | number (0–999999) | no | Cost |
| price_out | number (0–999999) | yes | Selling price |
| unit | text (max: 20) | no | |
| is_deleted | bool | no | |

#### work_shifts
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| start_time | date | yes | Shift start timestamp |
| end_time | date | yes | Shift end timestamp (set on close) |
| status | select: OPEN, CLOSED | yes | |
| actual_cash | number (0+) | no | Cash in drawer at shift end |
| worker_id | relation → users | yes | The pump attendant |

#### shift_pumps
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| end_analog_counter | number (0+) | no | Counter reading at shift end |
| price_at_shift | number (0–999999) | no | Fuel price at time of shift |
| shift_id | relation → work_shifts | yes | cascadeDelete: true |
| pump_id | relation → pumps | yes | |

#### clients
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| name | text (max: 200) | yes | |
| phone | text (max: 50) | no | |
| plate_number | text (max: 50) | no | |
| credit_limit | number (0–9999999) | no | |
| current_balance | number | no | Computed field |
| address | text (max: 200) | no | |
| email | text (max: 100) | no | |
| is_deleted | bool | no | |

#### sales
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| sale_type | select: FUEL, PRODUCT, SERVICE | yes | |
| volume | number (0–999999) | no | Fuel volume or product qty |
| unit_price | number (0–999999) | no | |
| total_price | number (0–99999999) | yes | |
| driver_name | text (max: 200) | no | |
| vehicle_plate | text (max: 50) | no | |
| driver_phone | text (max: 50) | no | |
| notes | text (max: 1000) | no | |
| timestamp | date | no | |
| shift_id | relation → work_shifts | no | |
| client_id | relation → clients | no | |
| gas_type_id | relation → gas_types | no | For FUEL sales |
| product_id | relation → products | no | For PRODUCT sales |
| service_id | relation → services | no | For SERVICE sales |
| payment_type_id | relation → payment_types | no | |
| worker_id | relation → users | no | |
| is_deleted | bool | no | |

#### debts
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| amount | number (0–99999999) | yes | |
| due_date | date | no | |
| client_id | relation → clients | yes | |
| driver_name | text (max: 200) | no | |
| vehicle_plate | text (max: 50) | no | |
| is_deleted | bool | no | |
| created | autodate | auto | |

#### payments
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| amount | number (0–99999999) | yes | |
| status | select: PENDING, COMPLETED, REJECTED, CANCELLED | yes | |
| check_bank_name | text (max: 100) | no | |
| check_number | text (max: 100) | no | |
| due_date | date | no | |
| cleared_at | date | no | |
| notes | text (max: 1000) | no | |
| client_id | relation → clients | no | |
| sale_id | relation → sales | no | |
| payment_type_id | relation → payment_types | no | |
| recorded_by | relation → users | no | |
| is_deleted | bool | no | |

#### payment_types
| Field | Type | Required | Unique |
|-------|------|----------|--------|
| id | text (PK) | auto | yes |
| name | text (max: 50) | yes | no |
| code | text (max: 20) | yes | yes (CASH, CHECK, TRANSFER, etc.) |
| icon | text (max: 50) | no | no |

#### fuel_suppliers
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| name | text (max: 200) | yes | |
| is_active | bool | no | |

#### pit_refills
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| volume | number (0–999999) | yes | Volume added in liters |
| cost_per_liter | number (0–999999) | no | |
| total_cost | number (0–99999999) | no | |
| profit_margin | number (0–99999999) | no | |
| timestamp | date | yes | |
| pit_id | relation → pits | yes | |
| recorded_by | relation → users | no | |
| supplier_id | relation → fuel_suppliers | no | |
| fleet_truck_id | text (max: 50) | no | |
| fleet_driver_name | text (max: 200) | no | |
| fleet_vehicle_plate | text (max: 50) | no | |
| truck_driver | text (max: 200) | no | |
| depot_num | text (max: 50) | no | |
| bch_num | text (max: 50) | no | |
| veh_plate | text (max: 50) | no | |
| tank_id | text (max: 50) | no | |

#### refill_payments
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| amount | number (0–99999999) | yes | |
| transfer_reference | text (max: 100) | no | |
| bank_name | text (max: 100) | no | |
| account_number | text (max: 100) | no | |
| payment_date | date | no | |
| refill_id | relation → pit_refills | yes | cascadeDelete: true |
| payment_type_id | relation → payment_types | no | |

#### fuel_price_history
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| old_price_in | number (0–999999) | no | |
| new_price_in | number (0–999999) | no | |
| old_price_out | number (0–999999) | no | |
| new_price_out | number (0–999999) | no | |
| changed_at | date | yes | |
| gas_type_id | relation → gas_types | yes | |
| changed_by | relation → users | no | |
| is_deleted | bool | no | |

#### expenses
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| description | text (max: 500) | yes | |
| amount | number (0–99999999) | yes | |
| quantity | number (0+) | no | |
| category | select: SUPPLIES, MAINTENANCE, SALARY, UTILITIES, RENT, TRANSPORT, OTHER | no | |
| timestamp | date | yes | |
| recorded_by | relation → users | no | |

#### salary_advances
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| amount | number (0–99999999) | yes | |
| status | select: PENDING, APPROVED, REJECTED | yes | |
| request_date | date | yes | |
| resolution_date | date | no | |
| worker_id | relation → users | yes | |
| resolved_by | relation → users | no | |

#### logs
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| action | text (max: 100) | yes | e.g. "SHIFT_STARTED", "SALE_RECORDED", "CHECK_CLEARED" |
| details | text (max: 2000) | no | Human-readable description |
| timestamp | date | yes | |
| user_id | relation → users | no | Who performed the action |

#### app_permissions
| Field | Type | Required | Unique |
|-------|------|----------|--------|
| id | text (PK) | auto | yes |
| section | text (max: 100) | yes | yes |
| permitted_roles | json (array of strings) | no | e.g. ["Admin", "SuperUser", "Worker"] |
| roles | json (array of strings) | no | |

#### users (auth)
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | text (PK) | auto | |
| email | email | yes | unique, used for login |
| password | text | yes | Not queryable |
| full_name | text (max: 200) | no | Display name |
| role | select: Worker, Admin, SuperUser, Audit | yes | |
| is_active | bool | no | |
| monthly_salary | number (0–99999999) | no | |

---

## 5. Business Logic & Key Formulas

### 5.1 Shift Counter Chain

```
For each pump in a shift:
  1. Find the pump's end_analog_counter from all previous shifts (sorted by end_time ASC)
  2. Previous counter = most recent previous end_analog_counter, or pump's initial_analog_counter
  3. volume = max(0, current_end_analog_counter - previous_counter)
  4. revenue = round2(volume × price_at_shift)
```

Chain is verified on shift creation: new shift's `start_time` must equal the latest closed shift's `end_time`.

### 5.2 Pit Volume Management

- **On shift close (deduction):** `new_volume = round2(max(0, current_volume - total_pump_volume_for_pit))`
- **On refill (increase):** `new_volume = round2(current_volume + refill_volume)`
- **On shift delete (reversal):** `new_volume = round2(current_volume + previous_deduction)`
- **On refill delete (reversal):** `new_volume = round2(max(0, current_volume - refill_volume))`
- **On fuel sale (real-time decrement):** `new_volume = round2(max(0, current_volume - sale_volume))`

### 5.3 Refill Cost & Profit

- `total_cost = round2(volume × cost_per_liter)`
- `profit_margin = round2(volume × 0.5)` (default: 0.50 MAD/L)
- Profit margin can be overridden manually

### 5.4 Client Balance

- `balance = round2(total_non_deleted_debts - total_completed_payments)`
- Positive balance = client owes money

### 5.5 Payment Status Machine

```
CASH → status: COMPLETED (immediate)
CHECK → status: PENDING → COMPLETED (on clearCheck()) or REJECTED (on rejectCheck())
TRANSFER → status: PENDING → COMPLETED (on clearCheck()) or REJECTED (on rejectCheck())
```

### 5.6 Rounding

All monetary and volume values: `round2(n) = Math.round(n × 100) / 100`

### 5.7 Credit Limit

Credit limit is stored on clients but not enforced at sale time. The system tracks which clients have exceeded their limit for alerting on the admin dashboard.

### 5.8 Audit Log Auto-Recording

| Event | Log Entry |
|-------|-----------|
| Sale recorded | `Sale: {total} MAD recorded` |
| Payment recorded | `Payment: {amount} MAD recorded` |
| Debt created | `Debt: {amount} MAD created` |
| Pit refill | `{volume}L refill for pit {pit_id}` |
| Shift closed | `Shift closed` |
| Shift started | `Shift started` |
| Expense recorded | `Expense: {amount} MAD - {description}` |
| Check cleared | `CHECK_CLEARED` |
| Check rejected | `CHECK_REJECTED` |
| Payment deleted | `PAYMENT_DELETED` |

Logs older than 90 days are automatically deleted.

---

## 6. User Flows

### 6.1 Login / Authentication

1. App loads → checks persisted auth session
2. If valid → refresh token server-side → Dashboard
3. If invalid → Login screen (email + password)
4. On first login (no profile name/role set) → "Configuring Identity" screen
5. After profile set → Dashboard

### 6.2 Worker Daily Flow

```
Login
  ↓
Dashboard (Worker view)
  ↓
No active shift? → Start Shift workflow:
  1. Select pumps from matrix (filtered by group/block)
  2. Enter initial analog counter for each selected pump
  3. Confirm → Shift created (OPEN status)
  ↓
Active shift → Operations Terminal:
  → Record Sale (FUEL / PRODUCT / SERVICE)
    - Select asset (gas type / product / service)
    - Enter volume/quantity + price → auto-calculates total
    - Select client (or "PASS_BY" for cash walk-ins)
    - Select payment method (CASH = immediate, CHECK = pending)
    - For CHECK: enter bank name, check number, maturity date
    - Optional: driver name, vehicle plate, notes
    - Commit → atomic transaction (sale + payment + pit deduction)
  → End Shift:
    - Enter end analog counter for each pump (via TerminalKeypad)
    - Optionally use camera OCR to read mechanical counter digits
    - Review Master Audit screen:
      * Pump delta summary (start → end, volume, revenue per pump)
      * Pit deduction toggle
      * Liquidity audit (expected cash vs recorded ledger sales)
    - Confirm → Shift closed (CLOSED status), volumes computed, pits deducted
  → Request Salary Advance:
    - Enter amount → PENDING status → admin reviews later
```

### 6.3 Admin Daily Flow

```
Login
  ↓
Dashboard (Admin view):
  - KPI Cards: Total Fuel Sales (L + MAD), Product Sales (count + MAD), Unpaid Debts (count + MAD)
  - Fuel Prices panel (with Quick Edit)
  - Fuel Sales by Type chart
  - Shift Performance bar chart (Week/Month toggle, Revenue/Volume)
  - Debt Status (due, critical 60+ days)
  - Payment Status (rejected, due)
  - Critical Alerts (pending advances, exceeded credit limits)
  - Recent Activity feed (last 5 sales)
  ↓
Manage Station:
  → Pits: CRUD, view refill history, record new refill
  → Pumps: CRUD, assign to pits, configure groups
  → Fuel: CRUD gas types, view price history, quick price edit
  → Products: CRUD shop items
  → Services: CRUD service fees
  ↓
Operations:
  → Shifts: view all, filter, export to Excel, print reports, delete
  → Clients: CRUD, ledger timeline, import/export, archive/restore
  → Workers: HR profiles, salary advance management (approve/reject)
  → Expenses: CRUD by category
  ↓
Data Imports:
  → Shift Data Import (Excel with pump readings)
  → Pit Refill Import (Excel with supplier + payment details)
  → Client Data Import (sales + payments + debts from Excel/JSON)
  ↓
Administration:
  → Role Management (set per-section role permissions)
  → System Logs (audit trail, printable)
  → Settings (language, theme, data vault export/import)
```

### 6.4 Client Ledger Flow

```
Admin clicks "Ledger" or "Clients"
  ↓
Client list → Select client
  ↓
Transaction Timeline view:
  - Summary KPI bar: Revenue, Collected, Outstanding, Net
  - Filter bar: Date presets (All/Today/Week/Month/Custom), Type (All/Sales/Payments/Debts), Search
  - Virtualized table: #, Date, Type, Client, Amount, Status, Payment
  - Expand rows for actions:
    * SALE: Void
    * PAYMENT (PENDING): Clear / Reject
    * PAYMENT (COMPLETED): Reopen
    * DEBT: Mark Paid / Delete
  ↓
"Record Transaction" button (or Ctrl+K):
  - Slide-over panel with SALE / PAYMENT / DEBT tabs
  - Client autocomplete search
  - Type-specific fields + validation
  - Commit to ledger
```

---

## 7. UI/UX Specifications

### 7.1 Responsive Layout

- **Phone (< 768px):** Single column, bottom navigation bar, full-width forms
- **Tablet (768–1023px):** Mini sidebar (60px, icons only) with overlay, compact layout
- **Desktop (≥ 1024px):** Full sidebar (220px with labels), multi-column layouts

### 7.2 Navigation

**Sidebar (Desktop/Tablet):**
- Sections grouped by category: Dashboard, Sales, My Shift, Station Management (Pits, Pumps, Fuel, Products), Shifts, Clients, Imports, Expenses, Reports, Workers, System Logs, Role Management, Settings
- Permission-filtered: each user role sees only their authorized sections
- Collapsible sub-items per section

**Bottom Nav (Phone):**
- 8 primary tabs + overflow "More" menu with 7 additional items
- Active tab indicator (top border + background)
- Auto-collapses to floating pill

**FAB Speed Dial (All screen sizes):**
- 7 quick actions: Quick Price, Record Sale, Record Payment, Record Debt, Add Client, Add Expense, Start Shift
- Draggable position (persisted in localStorage)
- Rotation animation on open
- Permission-filtered

### 7.3 Login Screen

- Split design on desktop: editorial left panel (branding, tagline, feature list) + login form right panel
- Mobile: stacked layout
- Background radial gradient vignette
- Dark form inputs with mono font
- Loading splash: animated fuel icon + progress bar + "Synchronizing Operational Data..."

### 7.4 Worker Terminal

- "Operations Terminal" header
- Grid layout: transaction entry (full width) + shift termination panel
- Sale entry: three-way toggle (FUEL / PRODUCT / SERVICE), asset dropdown, volume/price auto-calc, payment protocol card, client ID sidebar
- Shift termination: end readings per pump with TerminalKeypad + camera OCR option, then Master Audit screen with pump delta summary, pit deduction toggle, liquidity audit sidebar

### 7.5 Admin Dashboard

- Three-pillar KPI cards (Fuel Sales, Product Sales, Unpaid Debts)
- Fuel Prices panel with colored fuel type cards + Quick Edit
- Fuel Sales by Type breakdown
- Shift Performance bar chart (Week/Month + Revenue/Volume toggle)
- Debt Status (due / critical 60+ days)
- Payment Status (rejected / due)
- Critical Alerts (pending advances, exceeded limits)
- Recent Activity feed

### 7.6 Forms & Validation

| Form | Fields | Validation |
|------|--------|------------|
| Sale (inline) | Sale type toggle, asset select, volume, price, total, payment mode, client, driver, plate, notes | Asset+price+worker required. PASS_BY not allowed for CHECK |
| Transaction (slide-over) | Type toggle, client search, product, volume, price, total, payment method, check fields, due date, notes | Client required. Product required for SALE. |
| Shift Start | Pump matrix selection, analog counter per pump (TerminalKeypad) | ≥1 pump. Counter ≥ reference, max +5000 |
| Shift End | End analog counter per pump (TerminalKeypad/OCR) | Integer only (decimal blocked for analog) |
| Client | Name, phone, plate, credit limit, address, email | Name required |
| Expense | Description, amount, quantity, category, date | Description + amount required |
| Salary Advance | Amount | > 0 |

### 7.7 Custom Input Components

- **TerminalKeypad:** Full-screen digit keypad for counter entry. Digits 0-9, Enter (NEXT), Backspace (DEL), Escape (CLR). Integer-only mode for analog counters.
- **CounterPicker:** Industrial-style digit spinner dialog with up/down arrow wheels per digit. Mechanical counter aesthetic (dark gradient, inset shadow). Standard (integer) and High Precision (2 decimal) modes.
- **MechanicalCounterReader:** Camera-based OCR for 7-segment mechanical counters. 7 states: idle→camera→preview→processing→success→error→manual. 7-segment pattern matching algorithm. Torch/flashlight support. Front/back camera toggle. File upload fallback.
- **AutocompleteInput:** Search-as-you-type with dropdown. Used for client search, historical banks, driver names, vehicle plates, notes presets.

### 7.8 Theming

- Dark mode (primary: blue `#0066CC`, green accent `#84CC16`, navy surfaces `#0B1220`)
- Light mode (warm cream palette)
- Editorial/print-magazine aesthetic with serif typography
- Arabic: Noto Naskh Arabic font with full RTL support
- Glassmorphism panels, dense data tables

---

## 8. Internationalization

- **3 languages:** English (eng), French (fr), Arabic (ar)
- **1434 translation keys** per language
- **RTL support:** Arabic auto-sets `dir="rtl"` on the document
- Language is persisted in localStorage and cycled via a top-bar button (EN → FR → AR → EN)

---

## 9. External Integrations

| Integration | Purpose |
|-------------|---------|
| **Gemini AI OCR** | Reading mechanical 7-segment pump counter digits via camera |
| **PocketBase** | Self-hosted backend: database (SQLite), auth, real-time subscriptions, REST API |
| **Google Fonts** | Inter, JetBrains Mono, IBM Plex Mono, Noto Naskh Arabic |
| **ExcelJS / xlsx** | Excel file generation for reports and bulk edit templates |
| **Recharts** | SVG bar charts on admin dashboard |
| **Docker** | Multi-stage container build |
| **Railway** | Cloud deployment |

---

## 10. Data Import Templates

### Shift Import (Excel)
Columns: date, worker name, pump-specific end_analog_counter + price columns, start/end time

### Pit Refill Import (Excel)
Columns: pit name, volume added, cost per liter, profit margin, date, recorded by, truck driver, depot number, BCH number, vehicle plate, tank ID, supplier, payment details

### Client Data Import (Excel/JSON)
Three sub-templates:
1. **Sales:** date, fleet name, fleet plate, product (gas type), qty, price, amount, payment type, check fields
2. **Payments:** date, amount, payment type, reference, due date, check fields
3. **Debts:** date, amount, due date

All imports resolve foreign keys by name (case-insensitive) and support rollback on failure.

---

## 11. Security

- **Authentication:** Email/password via PocketBase Auth
- **Session persistence:** localStorage with auto-refresh
- **Role-based access control:** 4 roles with per-section permissions stored in `app_permissions` collection
- **Access rules per collection:** Built into PocketBase (listRule, viewRule, createRule, updateRule, deleteRule)
- **Audit logging:** All financial actions logged immutably
- **Soft deletes:** All major records use `is_deleted` flag instead of hard deletion
- **Pit volume guard:** Server-side hook prevents negative pit volumes

---

## 12. Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| UI Framework | React 19 + TypeScript 5.8 |
| Build Tool | Vite 6.2 |
| Styling | Tailwind CSS 4.1 + shadcn/ui |
| State (Client) | Zustand 5 |
| State (Server) | TanStack Query 5 |
| Data Tables | TanStack Table 8 + Virtual 3 |
| Backend | PocketBase 0.22.21 (Go + SQLite) |
| Auth | PocketBase Auth (email/password) |
| Real-time | PocketBase Subscriptions |
| Charts | Recharts 3 |
| i18n | i18next + react-i18next |
| PDF Reports | HTML → window.print() |
| Excel | ExcelJS / xlsx |
| AI OCR | @google/genai |
| Animations | Motion (framer-motion) 12 |
| Deployment | Docker + Railway |
