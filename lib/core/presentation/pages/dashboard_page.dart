import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sidebar.dart';
import '../widgets/editorial_ticker_bar.dart';
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
      );
    }

    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final displayName = profileAsync.when(
      data: (p) => p?.fullName ?? user?.email ?? 'User',
      loading: () => user?.email ?? 'User',
      error: (_, _a) => user?.email ?? 'User',
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.local_gas_station, color: Color(0xFF84CC16), size: 22),
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
            backgroundColor: const Color(0xFF1A2332),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Color(0xFF84CC16),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 20),
            color: const Color(0xFF1A2332),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red.shade300, size: 18),
                    const SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.red.shade300)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
    );
  }
}

void _showLogoutDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A2332),
      title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Are you sure you want to sign out?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await firebaseAuthProvider.signOut();
            if (context.mounted) context.go(AppRoutes.login);
          },
          child: Text('Sign Out', style: TextStyle(color: Colors.red.shade300)),
        ),
      ],
    ),
  );
}
