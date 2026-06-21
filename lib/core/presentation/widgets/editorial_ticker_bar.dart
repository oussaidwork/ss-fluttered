import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/auth_provider.dart';
import '../../../data/auth/firebase_auth_provider.dart';
import '../../router/app_router.dart';
import '../../theme/theme.dart';

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
    final cs = Theme.of(context).colorScheme;
    final themeController = ThemeProvider.of(context);

    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      title: Text(
        'SS-RAGRAGA Station OS',
        style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Chip(
            label: const Text('Fuel: 10.72 MAD/L', style: TextStyle(fontSize: 11)),
            backgroundColor: cs.surfaceContainerHighest,
            labelStyle: TextStyle(color: cs.secondary),
            side: BorderSide(color: cs.secondary, width: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.language, size: 20),
          onPressed: () {},
          tooltip: 'Language',
        ),
        IconButton(
          icon: Icon(
            themeController.isDark ? Icons.dark_mode : Icons.light_mode,
            size: 20,
          ),
          onPressed: () => themeController.toggleTheme(),
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
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: cs.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: cs.secondary,
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
                backgroundColor: cs.surfaceContainerHighest,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: cs.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
            ],
          ),
        ),
      ],
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
