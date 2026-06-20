import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/enums/user_role.dart';
import '../../../data/repositories/permission_repository_impl.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../constants/firestore_paths.dart';

/// The permission sections that appear as rows in the matrix.
const _allSections = [
  'Dashboard',
  'My Shift',
  'Station Management',
  'Sales',
  'Shifts',
  'Clients',
  'Workers',
  'Expenses',
  'Imports',
  'Statistics',
  'Settings',
  'System Logs',
  'Role Management',
];

/// All roles that appear as columns.
final _allRoles = UserRole.values;

/// Role Management page with a permission matrix.
/// Mirrors the React RoleManagementView.tsx spec.
class RoleManagementPage extends ConsumerStatefulWidget {
  const RoleManagementPage({super.key});

  @override
  ConsumerState<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends ConsumerState<RoleManagementPage> {
  Map<String, List<String>> _localPermissions = {};
  final Set<String> _savingSections = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Role Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SUPER_USER ONLY',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildPermissionMatrix(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionMatrix() {
    return StreamBuilder<List<AppPermission>>(
      stream: permissionRepository.watchPermissions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF0066CC),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Accessing Security Protocols...',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load permissions: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          );
        }

        final permissions = snapshot.data ?? [];
        // Build local state from data
        if (_localPermissions.isEmpty && permissions.isNotEmpty) {
          _localPermissions = {
            for (final p in permissions) p.section: List.from(p.permittedRoles),
          };
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Card(
              color: const Color(0xFF1A2332),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
                columnSpacing: 20,
                horizontalMargin: 16,
                columns: [
                  const DataColumn(
                    label: Text(
                      'Permission Section',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ..._allRoles.map((role) => DataColumn(
                    label: Text(
                      role.value,
                      style: TextStyle(
                        color: _roleColor(role),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  )),
                  const DataColumn(
                    label: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                rows: _allSections.map((section) {
                  final allowedRoles = _localPermissions[section] ?? [];
                  final isSaving = _savingSections.contains(section);
                  return DataRow(
                    color: WidgetStateProperty.all(
                      _allSections.indexOf(section).isEven
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.transparent,
                    ),
                    cells: [
                      // Section name
                      DataCell(
                        SizedBox(
                          width: 160,
                          child: Text(
                            section,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      // Role toggles
                      ..._allRoles.map((role) {
                        final isGranted = allowedRoles.contains(role.value);
                        return DataCell(
                          SizedBox(
                            width: 60,
                            child: Center(
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: isGranted,
                                  onChanged: isSaving
                                      ? null
                                      : (val) {
                                          setState(() {
                                            if (val) {
                                              allowedRoles.add(role.value);
                                            } else {
                                              allowedRoles.remove(role.value);
                                            }
                                            _localPermissions[section] = List.from(allowedRoles);
                                          });
                                        },
                                  activeTrackColor: const Color(0xFF84CC16),
                                  activeThumbColor: Colors.white,
                                  inactiveTrackColor: Colors.white12,
                                  inactiveThumbColor: Colors.white38,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      // Save button
                      DataCell(
                        isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF84CC16),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.save,
                                  size: 18,
                                  color: Color(0xFF0066CC),
                                ),
                                onPressed: () => _saveSection(section, allowedRoles),
                                tooltip: 'Save ${section} permissions',
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveSection(String section, List<String> allowedRoles) async {
    setState(() => _savingSections.add(section));

    try {
      // Find existing permission or create a new one
      final permissions = await permissionRepository.watchPermissions().first;
      final existing = permissions.where((p) => p.section == section).toList();

      if (existing.isNotEmpty) {
        await permissionRepository.updatePermission(
          existing.first.copyWith(permittedRoles: allowedRoles),
        );
      } else {
        // Create new permission document
        final docRef = firestore.collection(FirestorePaths.appPermissions).doc();
        await docRef.set({
          'id': docRef.id,
          'section': section,
          'permittedRoles': allowedRoles,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$section permissions updated'),
            backgroundColor: const Color(0xFF84CC16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingSections.remove(section));
    }
  }

  Color _roleColor(UserRole role) {
    if (role == UserRole.superUser) return const Color(0xFFF59E0B);
    if (role == UserRole.admin) return const Color(0xFF0066CC);
    if (role == UserRole.worker) return const Color(0xFF84CC16);
    return Colors.white54;
  }
}
