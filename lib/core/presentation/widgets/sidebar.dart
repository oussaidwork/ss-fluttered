import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 220,
      color: const Color(0xFF0B1220),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.local_gas_station, color: Color(0xFF84CC16), size: 28),
                SizedBox(width: 8),
                Text(
                  'SS-RAGRAGA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavSection(
                  title: 'OVERVIEW',
                  items: [
                    _NavItem(
                      icon: Icons.dashboard,
                      label: 'Dashboard',
                      route: AppRoutes.dashboard,
                      currentPath: currentPath,
                    ),
                  ],
                ),
                _NavSection(
                  title: 'STATION',
                  items: [
                    _NavItem(
                      icon: Icons.water_drop,
                      label: 'Fuel Types',
                      route: AppRoutes.fuel,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.archive,
                      label: 'Pits',
                      route: AppRoutes.pits,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.local_gas_station,
                      label: 'Pumps',
                      route: AppRoutes.pumps,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.inventory_2,
                      label: 'Products',
                      route: AppRoutes.products,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.design_services,
                      label: 'Services',
                      route: AppRoutes.services,
                      currentPath: currentPath,
                    ),
                  ],
                ),
                _NavSection(
                  title: 'OPERATIONS',
                  items: [
                    _NavItem(
                      icon: Icons.point_of_sale,
                      label: 'POS Sale',
                      route: AppRoutes.pos,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.schedule,
                      label: 'Shifts',
                      route: AppRoutes.shifts,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.people,
                      label: 'Clients',
                      route: AppRoutes.clients,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.book,
                      label: 'Ledger',
                      route: AppRoutes.ledger,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.receipt_long,
                      label: 'Expenses',
                      route: AppRoutes.expenses,
                      currentPath: currentPath,
                    ),
                  ],
                ),
                _NavSection(
                  title: 'ADMIN',
                  items: [
                    _NavItem(
                      icon: Icons.assessment,
                      label: 'Reports',
                      route: AppRoutes.reports,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.group,
                      label: 'Workers',
                      route: AppRoutes.workers,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.list_alt,
                      label: 'System Logs',
                      route: AppRoutes.systemLogs,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.settings,
                      label: 'Settings',
                      route: AppRoutes.settings,
                      currentPath: currentPath,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'v0.8.0',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String title;
  final List<_NavItem> items;
  const _NavSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentPath;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == route;
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: isActive ? const Color(0xFF84CC16) : Colors.white54,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontSize: 14,
        ),
      ),
      dense: true,
      selected: isActive,
      selectedTileColor: const Color(0xFF84CC16).withAlpha(25),
      onTap: () => context.go(route),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
