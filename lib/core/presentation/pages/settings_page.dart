import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/locale_provider.dart';
import '../../router/app_router.dart';
import '../../services/json_export_service.dart';
import '../../../data/datasource/firestore_datasource.dart';
import '../../../core/theme/theme.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = ThemeProvider.of(context).isDark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: cs.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection('Language', Icons.language, [
              _buildLanguageSelector(currentLocale),
            ]),
            const SizedBox(height: 24),
            _buildSection('Appearance', Icons.palette, [
              _buildThemeToggle(isDark),
            ]),
            const SizedBox(height: 24),
            _buildSection('Data Management', Icons.storage, [
              _buildDataExportImport(),
            ]),
            const SizedBox(height: 24),
            _buildSection('About', Icons.info_outline, [
              _buildAppInfo(),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Divider(color: cs.onSurface.withValues(alpha: 0.12), height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(Locale currentLocale) {
    final cs = Theme.of(context).colorScheme;
    final languages = [
      (const Locale('en'), 'English', '🇺🇸'),
      (const Locale('fr'), 'Français', '🇫🇷'),
      (const Locale('ar'), 'العربية', '🇩🇿'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: languages.map((lang) {
        final selected = currentLocale.languageCode == lang.$1.languageCode;
        return InkWell(
          onTap: () => ref.read(localeProvider.notifier).setLocale(lang.$1),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.15)
                  : cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang.$3, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.$2,
                      style: TextStyle(
                        color: selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.7),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      lang.$1.languageCode.toUpperCase(),
                      style: TextStyle(
                        color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.38),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: cs.primary, size: 18),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeToggle(bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => ThemeProvider.of(context).setThemeMode(ThemeMode.dark),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? cs.primary.withValues(alpha: 0.15)
                    : cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dark_mode, color: isDark ? cs.primary : cs.onSurface.withValues(alpha: 0.54)),
                  const SizedBox(width: 8),
                  Text(
                    'Dark',
                    style: TextStyle(
                      color: isDark ? cs.onSurface : cs.onSurface.withValues(alpha: 0.54),
                      fontWeight: isDark ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => ThemeProvider.of(context).setThemeMode(ThemeMode.light),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !isDark
                    ? cs.primary.withValues(alpha: 0.15)
                    : cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isDark
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.light_mode, color: !isDark ? cs.primary : cs.onSurface.withValues(alpha: 0.54)),
                  const SizedBox(width: 8),
                  Text(
                    'Light',
                    style: TextStyle(
                      color: !isDark ? cs.onSurface : cs.onSurface.withValues(alpha: 0.54),
                      fontWeight: !isDark ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataExportImport() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.download,
          title: 'Export Data',
          subtitle: 'Export all data to CSV or JSON format',
          color: cs.secondary,
          onTap: () => _exportData(),
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          icon: Icons.upload,
          title: 'Import Data',
          subtitle: 'Import data from a backup file',
          color: cs.primary,
          onTap: () => context.go(AppRoutes.importData),
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          icon: Icons.backup,
          title: 'Backup to Cloud',
          subtitle: 'Create a backup on cloud storage',
          color: cs.secondaryContainer,
          onTap: () => _showComingSoon('Cloud Backup'),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.24), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_gas_station, color: cs.primary, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            'Gas Station POS',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'Built with Flutter & Firebase',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12),
          ),
          Divider(color: cs.onSurface.withValues(alpha: 0.12), height: 24),
          _infoRow('Platform', 'Android / Web'),
          _infoRow('Backend', 'Firebase Firestore'),
          _infoRow('Auth', 'Firebase Auth'),
          _infoRow('License', 'Proprietary'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13)),
          Text(value, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13)),
        ],
      ),
    );
  }

  void _exportData() async {
    final cs = Theme.of(context).colorScheme;
    try {
      final exportService = JsonExportService(FirestoreDataSourceImpl());
      await exportService.downloadJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data exported successfully!'),
            backgroundColor: cs.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showComingSoon(String feature) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        backgroundColor: cs.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'OK',
          textColor: cs.primary,
          onPressed: () {},
        ),
      ),
    );
  }
}
