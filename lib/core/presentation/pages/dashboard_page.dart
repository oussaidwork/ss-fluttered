import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sidebar.dart';
import '../widgets/editorial_ticker_bar.dart';
import '../widgets/fab_speed_dial.dart';
import '../../../../presentation/providers/auth_provider.dart';
import '../../../data/auth/firebase_auth_provider.dart';
import '../../router/app_router.dart';

class DashboardPage extends ConsumerWidget {
  final Widget child;
  const DashboardPage({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (isDesktop) {
      return Scaffold(
        appBar: const EditorialTickerBar(),
        body: Row(
          children: [
            const Sidebar(),
            Expanded(child: child),
          ],
        ),
        floatingActionButton: const FabSpeedDial(),
      );
    }

    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final displayName = profileAsync.when(
      data: (p) => p?.fullName ?? user?.email ?? 'User',
      loading: () => user?.email ?? 'User',
      error: (_, _a) => user?.email ?? 'User',
    );
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.local_gas_station, color: cs.secondary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'SS-RAGRAGA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          CircleAvatar(
            radius: 14,
            backgroundColor: cs.surfaceContainerHighest,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: cs.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(Icons.arrow_drop_down, size: 20),
            color: cs.surface,
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  displayName,
                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: cs.error, size: 18),
                    const SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: cs.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      floatingActionButton: const FabSpeedDial(),
    );
  }
}

void _showLogoutDialog(BuildContext context, WidgetRef ref) {
  final cs = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: cs.surface,
      title: Text('Sign Out', style: TextStyle(color: cs.onSurface)),
      content: Text(
        'Are you sure you want to sign out?',
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await firebaseAuthProvider.signOut();
            if (context.mounted) context.go(AppRoutes.login);
          },
          child: Text('Sign Out', style: TextStyle(color: cs.error)),
        ),
      ],
    ),
  );
}
