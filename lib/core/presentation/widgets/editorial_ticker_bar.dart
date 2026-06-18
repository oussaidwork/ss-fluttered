import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/auth_provider.dart';
import '../../../data/auth/firebase_auth_provider.dart';
import '../../router/app_router.dart';

class EditorialTickerBar extends ConsumerWidget implements PreferredSizeWidget {
  const EditorialTickerBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final displayName = profileAsync.when(
      data: (p) => p?.fullName ?? user?.email ?? 'User',
      loading: () => user?.email ?? 'User',
      error: (_, _a) => user?.email ?? 'User',
    );
    final role = profileAsync.when(
      data: (p) => p?.role.value ?? 'Worker',
      loading: () => 'Worker',
      error: (_, __) => 'Worker',
    );

    return AppBar(
      backgroundColor: const Color(0xFF0B1220),
      elevation: 0,
      title: const Text(
        'SS-RAGRAGA Station OS',
        style: TextStyle(fontSize: 14, color: Colors.white70),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Chip(
            label: Text(
              'Fuel: 10.72 MAD/L',
              style: TextStyle(fontSize: 11),
            ),
            backgroundColor: Color(0xFF1A2332),
            labelStyle: TextStyle(color: Color(0xFF84CC16)),
            side: BorderSide(color: Color(0xFF84CC16), width: 0.5),
            padding: EdgeInsets.symmetric(horizontal: 8),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.language, size: 20, color: Colors.white54),
          onPressed: () {},
          tooltip: 'Language',
        ),
        IconButton(
          icon: const Icon(Icons.brightness_6, size: 20, color: Colors.white54),
          onPressed: () {},
          tooltip: 'Theme',
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84CC16).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: Color(0xFF84CC16),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1A2332),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Color(0xFF84CC16),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
            ],
          ),
        ),
      ],
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
