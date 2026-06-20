import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/locale_provider.dart';
import '../../router/app_router.dart';
import '../../services/json_export_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Color(0xFF0066CC), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection('Language', Icons.language, [
              _buildLanguageSelector(currentLocale),
            ]),
            const SizedBox(height: 24),
            _buildSection('Appearance', Icons.palette, [
              _buildThemeToggle(),
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
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0066CC), size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(Locale currentLocale) {
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
                  ? const Color(0xFF0066CC).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF0066CC)
                    : Colors.white.withValues(alpha: 0.1),
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
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      lang.$1.languageCode.toUpperCase(),
                      style: TextStyle(
                        color: selected ? const Color(0xFF0066CC) : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Color(0xFF0066CC), size: 18),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeToggle() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _isDarkMode = true),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? const Color(0xFF0066CC).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDarkMode
                      ? const Color(0xFF0066CC)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dark_mode, color: _isDarkMode ? const Color(0xFF0066CC) : Colors.white54),
                  const SizedBox(width: 8),
                  Text(
                    'Dark',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.white54,
                      fontWeight: _isDarkMode ? FontWeight.w600 : FontWeight.normal,
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
            onTap: () => setState(() => _isDarkMode = false),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_isDarkMode
                    ? const Color(0xFF0066CC).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_isDarkMode
                      ? const Color(0xFF0066CC)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.light_mode, color: !_isDarkMode ? const Color(0xFF0066CC) : Colors.white54),
                  const SizedBox(width: 8),
                  Text(
                    'Light',
                    style: TextStyle(
                      color: !_isDarkMode ? Colors.white : Colors.white54,
                      fontWeight: !_isDarkMode ? FontWeight.w600 : FontWeight.normal,
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
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.download,
          title: 'Export Data',
          subtitle: 'Export all data to CSV or JSON format',
          color: const Color(0xFF84CC16),
          onTap: () => _exportData(),
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          icon: Icons.upload,
          title: 'Import Data',
          subtitle: 'Import data from a backup file',
          color: const Color(0xFF0066CC),
          onTap: () => context.go(AppRoutes.importData),
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          icon: Icons.backup,
          title: 'Backup to Cloud',
          subtitle: 'Create a backup on cloud storage',
          color: const Color(0xFF8B5CF6),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_gas_station, color: Color(0xFF0066CC), size: 40),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gas Station POS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Version 1.0.0',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 2),
          const Text(
            'Built with Flutter & Firebase',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const Divider(color: Colors.white12, height: 24),
          _infoRow('Platform', 'Android / Web'),
          _infoRow('Backend', 'Firebase Firestore'),
          _infoRow('Auth', 'Firebase Auth'),
          _infoRow('License', 'Proprietary'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  void _exportData() async {
    try {
      final exportService = JsonExportService();
      await exportService.downloadJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: Color(0xFF84CC16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        backgroundColor: const Color(0xFF1A2332),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'OK',
          textColor: const Color(0xFF0066CC),
          onPressed: () {},
        ),
      ),
    );
  }
}
