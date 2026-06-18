# SS-RAGRAGA — Firestore Data Schema

## Overview

All collections are **root-level** (no subcollections) for simplicity and query performance.
Each document uses its entity `id` as the document ID. Timestamps use Firestore `Timestamp`.
Soft deletes use an `isDeleted` boolean field (never hard-delete).

---

## Collections

### 1. `users`
Firestore doc ID = Firebase Auth UID.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Same as document ID (Firebase UID) |
| `email` | string | yes | Login email |
| `fullName` | string | no | Display name |
| `role` | string | yes | `Worker` \| `Admin` \| `SuperUser` \| `Audit` |
| `isActive` | boolean | yes | Account enabled/disabled |
| `monthlySalary` | number | no | For salary tracking |
| `createdAt` | timestamp | no | Account creation time |

**Indexes:**
- `role` ASC, `isActive` ASC (worker list by role)

---

### 2. `gasTypes`
Fuel type definitions (e.g., Unleaded 92, Diesel, Premium 95).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Auto-generated ID |
| `name` | string | yes | Display name |
| `priceIn` | number | yes | Cost per liter (station buys at) |
| `priceOut` | number | yes | Retail price per liter |
| `color` | string | no | UI color hex |
| `isDeleted` | boolean | yes | Soft delete |
| `createdAt` | timestamp | yes | |
| `updatedAt` | timestamp | yes | |

**Indexes:**
- `isDeleted` ASC

---

### 3. `pits`
Underground fuel storage tanks.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `name` | string | yes | e.g., "Pit 1 - Diesel" |
| `capacity` | number | yes | Max volume in liters |
| `currentVolume` | number | yes | Current stock in liters |
| `gasTypeId` | string | no | FK → gasTypes |
| `isDeleted` | boolean | yes | |

**Indexes:**
- `isDeleted` ASC
- `gasTypeId` ASC, `isDeleted` ASC

---

### 4. `pumps`
Fuel dispensing pumps connected to pits.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `name` | string | yes | e.g., "Pump 1" |
| `isActive` | boolean | yes | Can be temporarily disabled |
| `initialAnalogCounter` | number | yes | Starting counter value |
| `groupId` | string | no | Grouping for multi-hose pumps |
| `subgroup` | string | no | Sub-grouping |
| `color` | string | no | UI color |
| `pitId` | string | yes | FK → pits |
| `isDeleted` | boolean | yes | |

**Indexes:**
- `isDeleted` ASC
- `pitId` ASC, `isDeleted` ASC

---

### 5. `products`
Convenience store / shop items.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `name` | string | yes | |
| `price` | number | yes | Default selling price |
| `priceIn` | number | no | Cost price |
| `priceOut` | number | no | Alternative selling price |
| `unit` | string | no | e.g., "pcs", "kg", "L" |
| `stockQuantity` | number | yes | Current inventory |
| `category` | string | no | Product category |
| `isActive` | boolean | yes | |
| `isDeleted` | boolean | yes | |

**Indexes:**
- `isDeleted` ASC
- `isActive` ASC, `isDeleted` ASC
- `category` ASC, `isDeleted` ASC

---

### 6. `services`
Services offered (car wash, oil change, etc.).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `name` | string | yes | |
| `priceIn` | number | no | Cost |
| `priceOut` | number | yes | Selling price |
| `unit` | string | no | e.g., "per car" |
| `isDeleted` | boolean | yes | |

**Indexes:**
- `isDeleted` ASC

---

### 7. `paymentTypes`
Payment method definitions (Cash, Card, Mobile, Check).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `name` | string | yes | Display name |
| `code` | string | yes | Unique code (CASH, CARD, MOBILE, CHECK) |
| `icon` | string | no | Icon name |

---

### 8. `clients`
Customer / fleet accounts.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `name` | string | yes | Company or person name |
| `phone` | string | no | |
| `plateNumber` | string | no | Default vehicle plate |
| `creditLimit` | number | no | Max allowed debt |
| `currentBalance` | number | yes | Outstanding balance (+ = owes us, - = we owe) |
| `address` | string | no | |
| `email` | string | no | |
| `isDeleted` | boolean | yes | |

**Indexes:**
- `isDeleted` ASC
- `name` ASC (for search)

---

### 9. `work_shifts`
Worker shifts (open/close cycle).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `startTime` | timestamp | yes | Shift start |
| `endTime` | timestamp | yes | Shift end (same as start if open) |
| `status` | string | yes | `OPEN` \| `CLOSED` |
| `actualCash` | number | no | Cash counted at close |
| `workerId` | string | yes | FK → users |

**Indexes:**
- `status` ASC, `startTime` DESC (active shift lookup)
- `workerId` ASC, `startTime` DESC (worker history)
- `startTime` DESC (date-range queries)

---

### 10. `shiftPumps`
Pump readings per shift — the "counter chain" linking one shift's end counter to the next shift's start counter.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `shiftId` | string | yes | FK → work_shifts |
| `pumpId` | string | yes | FK → pumps |
| `previousEndAnalogCounter` | number | no | End counter from previous shift |
| `endAnalogCounter` | number | no | End counter for this shift (set at close) |
| `priceAtShift` | number | yes | Price per liter at time of shift |
| `volume` | number | yes | Calculated: endAnalog - previousEndAnalog |
| `revenue` | number | yes | Calculated: volume × priceAtShift |

**Indexes:**
- `shiftId` ASC (all pumps for a shift)
- `pumpId` ASC, `shiftId` DESC (pump history / counter chain)
- `shiftId` ASC, `pumpId` ASC (unique lookup)

**Composite unique constraint (application-level):**
One `shiftPump` per (shiftId, pumpId) pair.

---

### 11. `sales`
All transactions — fuel sales, product sales, and service sales.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `saleType` | string | yes | `FUEL` \| `PRODUCT` \| `SERVICE` |
| `volume` | number | no | Liters (fuel only) |
| `unitPrice` | number | no | Price per unit |
| `totalPrice` | number | yes | Final amount |
| `driverName` | string | no | |
| `vehiclePlate` | string | no | |
| `driverPhone` | string | no | |
| `notes` | string | no | |
| `timestamp` | timestamp | yes | Transaction time |
| `shiftId` | string | no | FK → work_shifts |
| `clientId` | string | no | FK → clients (credit sales) |
| `gasTypeId` | string | no | FK → gasTypes (fuel sales) |
| `productId` | string | no | FK → products (product sales) |
| `serviceId` | string | no | FK → services (service sales) |
| `paymentTypeId` | string | no | FK → paymentTypes |
| `workerId` | string | no | FK → users (who made the sale) |
| `isDeleted` | boolean | yes | |

**Indexes (critical for reports):**
- `isDeleted` ASC, `timestamp` DESC (date-range listing)
- `saleType` ASC, `isDeleted` ASC, `timestamp` DESC (by type)
- `shiftId` ASC, `isDeleted` ASC (shift sales)
- `clientId` ASC, `isDeleted` ASC, `timestamp` DESC (client history)
- `gasTypeId` ASC, `isDeleted` ASC, `timestamp` DESC (fuel sales by type)
- `workerId` ASC, `isDeleted` ASC, `timestamp` DESC (worker sales)
- `paymentTypeId` ASC, `isDeleted` ASC, `timestamp` DESC (by payment method)
- `timestamp` DESC, `isDeleted` ASC (general listing)

---

### 12. `payments`
Payment records against sales or debts.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `amount` | number | yes | Payment amount |
| `status` | string | yes | `PENDING` \| `COMPLETED` \| `REJECTED` \| `CANCELLED` |
| `checkBankName` | string | no | For check payments |
| `checkNumber` | string | no | For check payments |
| `dueDate` | timestamp | no | When check is expected to clear |
| `clearedAt` | timestamp | no | When check cleared |
| `notes` | string | no | |
| `clientId` | string | no | FK → clients |
| `saleId` | string | no | FK → sales |
| `paymentTypeId` | string | no | FK → paymentTypes |
| `recordedBy` | string | no | FK → users |
| `isDeleted` | boolean | yes | |
| `createdAt` | timestamp | yes | |

**Indexes:**
- `isDeleted` ASC, `createdAt` DESC
- `clientId` ASC, `isDeleted` ASC, `createdAt` DESC
- `saleId` ASC, `isDeleted` ASC
- `status` ASC, `isDeleted` ASC (pending checks)
- `dueDate` ASC, `status` ASC (check clearing schedule)

---

### 13. `debts`
Outstanding debts per client.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `amount` | number | yes | Debt amount |
| `dueDate` | timestamp | no | |
| `clientId` | string | yes | FK → clients |
| `driverName` | string | no | |
| `vehiclePlate` | string | no | |
| `isDeleted` | boolean | yes | |
| `created` | timestamp | yes | |

**Indexes:**
- `clientId` ASC, `isDeleted` ASC, `created` DESC
- `isDeleted` ASC, `dueDate` ASC (overdue report)
- `isDeleted` ASC, `created` DESC (listing)

---

### 14. `expenses`
Operating expenses.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `description` | string | yes | |
| `amount` | number | yes | |
| `quantity` | number | no | |
| `category` | string | no | `SUPPLIES` \| `MAINTENANCE` \| `SALARY` \| `UTILITIES` \| `RENT` \| `TRANSPORT` \| `OTHER` |
| `timestamp` | timestamp | yes | |
| `recordedBy` | string | no | FK → users |

**Indexes:**
- `timestamp` DESC (date range)
- `category` ASC, `timestamp` DESC (by category)
- `recordedBy` ASC, `timestamp` DESC (by worker)

---

### 15. `fuelSuppliers`
Fuel supplier companies.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `name` | string | yes | |
| `isActive` | boolean | yes | |

---

### 16. `pitRefills`
Fuel delivery records (truck delivers fuel to pit).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `volume` | number | yes | Liters delivered |
| `costPerLiter` | number | no | Purchase price |
| `totalCost` | number | no | volume × costPerLiter |
| `profitMargin` | number | no | |
| `timestamp` | timestamp | yes | Delivery time |
| `pitId` | string | yes | FK → pits |
| `recordedBy` | string | no | FK → users |
| `supplierId` | string | no | FK → fuelSuppliers |
| `fleetTruckId` | string | no | |
| `fleetDriverName` | string | no | |
| `fleetVehiclePlate` | string | no | |
| `truckDriver` | string | no | |
| `depotNum` | string | no | |
| `bchNum` | string | no | |
| `vehPlate` | string | no | |
| `tankId` | string | no | |

**Indexes:**
- `pitId` ASC, `timestamp` DESC (pit refills history)
- `timestamp` DESC (listing)
- `supplierId` ASC, `timestamp` DESC (by supplier)

---

### 17. `refillPayments`
Payments made to fuel suppliers for pit refills.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `amount` | number | yes | |
| `transferReference` | string | no | |
| `bankName` | string | no | |
| `accountNumber` | string | no | |
| `paymentDate` | timestamp | no | |
| `refillId` | string | yes | FK → pitRefills |
| `paymentTypeId` | string | no | FK → paymentTypes |

**Indexes:**
- `refillId` ASC (payments for a refill)

---

### 18. `fuelPriceHistory`
Audit trail for fuel price changes.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `oldPriceIn` | number | no | |
| `newPriceIn` | number | no | |
| `oldPriceOut` | number | no | |
| `newPriceOut` | number | no | |
| `changedAt` | timestamp | yes | |
| `gasTypeId` | string | yes | FK → gasTypes |
| `changedBy` | string | no | FK → users |
| `isDeleted` | boolean | yes | |

**Indexes:**
- `gasTypeId` ASC, `changedAt` DESC (price history for a fuel type)
- `changedAt` DESC (global history)

---

### 19. `salaryAdvances`
Worker salary advance requests.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `amount` | number | yes | |
| `status` | string | yes | `PENDING` \| `APPROVED` \| `REJECTED` |
| `requestDate` | timestamp | yes | |
| `resolutionDate` | timestamp | no | |
| `workerId` | string | yes | FK → users |
| `resolvedBy` | string | no | FK → users (admin who approved/rejected) |

**Indexes:**
- `workerId` ASC, `requestDate` DESC (worker history)
- `status` ASC, `requestDate` DESC (pending queue)

---

### 20. `logEntries`
System audit logs.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | |
| `action` | string | yes | e.g., `SHIFT_OPEN`, `SALE_CREATE`, `PRICE_CHANGE` |
| `details` | string | no | JSON or human-readable |
| `timestamp` | timestamp | yes | |
| `userId` | string | no | FK → users |

**Indexes:**
- `timestamp` DESC (chronological listing)
- `action` ASC, `timestamp` DESC (filter by action)
- `userId` ASC, `timestamp` DESC (by user)

---

### 21. `appPermissions`
Role-based access control per section.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Section identifier |
| `section` | string | yes | e.g., `DASHBOARD`, `SHIFTS`, `REPORTS` |
| `permittedRoles` | array\<string\> | yes | Roles allowed to access |

---

## Key Relationships

```
gasTypes ──< pits ──< pumps ──< shiftPumps ──< work_shifts ──< users
                                         └──< sales ──< payments
                                         └──< sales ──< debts ──< clients
                              products ──< sales
                              services ──< sales
fuelSuppliers ──< pitRefills ──< pits
                             └──< refillPayments
gasTypes ──< fuelPriceHistory
users ──< salaryAdvances
users ──< logEntries
```

## Required Firestore Indexes (composite)

All single-field indexes are created automatically. The following **composite indexes** are needed:

| Collection | Fields | Purpose |
|------------|--------|---------|
| `work_shifts` | `status` ASC, `startTime` DESC | Active shift lookup |
| `work_shifts` | `workerId` ASC, `startTime` DESC | Worker shift history |
| `shiftPumps` | `shiftId` ASC, `pumpId` ASC | Unique pair lookup |
| `shiftPumps` | `pumpId` ASC, `shiftId` DESC | Counter chain |
| `sales` | `isDeleted` ASC, `timestamp` DESC | Date-range listing |
| `sales` | `saleType` ASC, `isDeleted` ASC, `timestamp` DESC | By type |
| `sales` | `shiftId` ASC, `isDeleted` ASC | Shift sales |
| `sales` | `clientId` ASC, `isDeleted` ASC, `timestamp` DESC | Client history |
| `sales` | `gasTypeId` ASC, `isDeleted` ASC, `timestamp` DESC | Fuel by type |
| `sales` | `workerId` ASC, `isDeleted` ASC, `timestamp` DESC | By worker |
| `sales` | `paymentTypeId` ASC, `isDeleted` ASC, `timestamp` DESC | By payment |
| `payments` | `clientId` ASC, `isDeleted` ASC, `createdAt` DESC | Client payments |
| `payments` | `status` ASC, `isDeleted` ASC | Pending checks |
| `payments` | `dueDate` ASC, `status` ASC | Check clearing |
| `debts` | `clientId` ASC, `isDeleted` ASC, `created` DESC | Client debts |
| `debts` | `isDeleted` ASC, `dueDate` ASC | Overdue report |
| `expenses` | `timestamp` DESC | Date range |
| `expenses` | `category` ASC, `timestamp` DESC | By category |
| `pitRefills` | `pitId` ASC, `timestamp` DESC | Pit history |
| `pitRefills` | `supplierId` ASC, `timestamp` DESC | By supplier |
| `fuelPriceHistory` | `gasTypeId` ASC, `changedAt` DESC | Price history |
| `logEntries` | `timestamp` DESC | Chronological |
| `logEntries` | `action` ASC, `timestamp` DESC | By action |
| `logEntries` | `userId` ASC, `timestamp` DESC | By user |
| `salaryAdvances` | `status` ASC, `requestDate` DESC | Pending queue |
