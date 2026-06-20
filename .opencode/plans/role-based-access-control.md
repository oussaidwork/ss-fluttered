# Role-Based Access Control + recordedBy Fix

## Files to Modify

### 1. `lib/core/presentation/pages/expenses_page.dart`

**a) recordedBy uses fullName from user profile**
- After auth check, fetch `users/{currentUser.uid}` from Firestore
- Extract `fullName` field, use it if non-empty, else fallback to email/uid
- Pass as `recordedBy`

**b) Convert to ConsumerStatefulWidget for role checks**
- Change `StatefulWidget` → `ConsumerStatefulWidget`
- Change `State<ExpensesPage>` → `ConsumerState<ExpensesPage>`
- Add `import 'package:flutter_riverpod/flutter_riverpod.dart';`
- Add `import '../../presentation/providers/auth_provider.dart';`

**c) Hide edit/delete for non-admin users**
- In `_buildExpenseTable`, wrap edit/delete `IconButton`s with `if (isAdmin)` check
- Get `isAdmin` via `ref.watch(isAdminProvider)` in build method
- Worker role can view and add expenses but not edit/delete

### 2. `lib/core/presentation/widgets/sidebar.dart`

- Convert from `StatelessWidget` to `ConsumerWidget`
- Import `package:flutter_riverpod/flutter_riverpod.dart`
- Import `../../presentation/providers/auth_provider.dart`
- In `build(context, ref)`, watch `ref.watch(userRoleProvider)`
- Permission mapping:
  - OVERVIEW (Dashboard) → All roles (Worker, Admin, SuperUser, Audit)
  - STATION (Fuel, Pits, Pumps, Products, Services) → Admin, SuperUser
  - OPERATIONS (POS, Shifts, Clients, Ledger, Expenses) → Worker, Admin, SuperUser
  - ADMIN (Reports, Workers, System Logs, Settings) → Admin, SuperUser
- Audit role sees only Dashboard + Reports

### 3. `lib/main.dart`

- Watch `userRoleProvider` from auth_provider
- Pass `userRole` to `createRouter()` alongside `isAuthenticated`

### 4. `lib/core/router/app_router.dart`

- Change signature to `createRouter({required bool isAuthenticated, required String userRole})`
- Define admin-only route lists: `_adminRoutes`, `_stationRoutes`
- Add role checks in `redirect`:
  - If user tries to access admin/station routes without Admin+ role → redirect to `/`
- Import `permission_utils.dart`

### 5. `firestore.rules`

- Add role-based rules using Firestore `get()` to read user doc:
```
match /expenses/{doc} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update, delete: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['Admin', 'SuperUser'];
}
```
- Add similar rules for pits, pumps, products, services, workers, settings
- Then `firebase deploy --only firestore:rules`
