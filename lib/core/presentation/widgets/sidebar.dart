import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final l10n = AppLocalizations.of(context)!;

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
                  title: l10n.sectionOverview,
                  items: [
                    _NavItem(
                      icon: Icons.dashboard,
                      label: l10n.dashboard,
                      route: AppRoutes.dashboard,
                      currentPath: currentPath,
                    ),
                  ],
                ),
                _NavSection(
                  title: l10n.sectionStation,
                  items: [
                    _NavItem(
                      icon: Icons.water_drop,
                      label: l10n.fuel,
                      route: AppRoutes.fuel,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.archive,
                      label: l10n.pits,
                      route: AppRoutes.pits,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.local_gas_station,
                      label: l10n.pumps,
                      route: AppRoutes.pumps,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.inventory_2,
                      label: l10n.products,
                      route: AppRoutes.products,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.design_services,
                      label: l10n.services,
                      route: AppRoutes.services,
                      currentPath: currentPath,
                    ),
                  ],
                ),
                _NavSection(
                  title: l10n.sectionOperations,
                  items: [
                    _NavItem(
                      icon: Icons.point_of_sale,
                      label: l10n.posSale,
                      route: AppRoutes.pos,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.schedule,
                      label: l10n.shifts,
                      route: AppRoutes.shifts,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.people,
                      label: l10n.clients,
                      route: AppRoutes.clients,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.book,
                      label: l10n.ledger,
                      route: AppRoutes.ledger,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.receipt_long,
                      label: l10n.expenses,
                      route: AppRoutes.expenses,
                      currentPath: currentPath,
                    ),
                  ],
                ),
                _NavSection(
                  title: l10n.sectionImport,
                  items: [
                    _NavExpandoItem(
                      icon: Icons.upload_file,
                      label: l10n.importData,
                      currentPath: currentPath,
                      children: [
                        _NavItem(
                          icon: Icons.people,
                          label: l10n.importClients,
                          route: AppRoutes.importClients,
                          currentPath: currentPath,
                        ),
                        _NavItem(
                          icon: Icons.group,
                          label: l10n.importWorkers,
                          route: AppRoutes.importWorkers,
                          currentPath: currentPath,
                        ),
                        _NavItem(
                          icon: Icons.schedule,
                          label: l10n.importShifts,
                          route: AppRoutes.importShifts,
                          currentPath: currentPath,
                        ),
                        _NavItem(
                          icon: Icons.local_gas_station,
                          label: l10n.importStation,
                          route: AppRoutes.importStation,
                          currentPath: currentPath,
                        ),
                        _NavItem(
                          icon: Icons.receipt_long,
                          label: l10n.importFinancial,
                          route: AppRoutes.importFinancial,
                          currentPath: currentPath,
                        ),
                      ],
                    ),
                  ],
                ),
                _NavSection(
                  title: l10n.sectionAdmin,
                  items: [
                    _NavItem(
                      icon: Icons.assessment,
                      label: l10n.reports,
                      route: AppRoutes.reports,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.group,
                      label: l10n.workers,
                      route: AppRoutes.workers,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.list_alt,
                      label: l10n.systemLogs,
                      route: AppRoutes.systemLogs,
                      currentPath: currentPath,
                    ),
                    _NavItem(
                      icon: Icons.settings,
                      label: l10n.settings,
                      route: AppRoutes.settings,
                      currentPath: currentPath,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.version,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
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

class _NavExpandoItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String currentPath;
  final List<_NavItem> children;

  const _NavExpandoItem({
    required this.icon,
    required this.label,
    required this.currentPath,
    required this.children,
  });

  @override
  State<_NavExpandoItem> createState() => _NavExpandoItemState();
}

class _NavExpandoItemState extends State<_NavExpandoItem> {
  late bool _expanded;

  bool get _anyChildActive => widget.children.any((c) => c.currentPath == c.route);
  bool get _isActive => _anyChildActive;

  @override
  void initState() {
    super.initState();
    _expanded = _anyChildActive;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(
            widget.icon,
            size: 20,
            color: isActive ? const Color(0xFF84CC16) : Colors.white54,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Colors.white38,
              ),
            ],
          ),
          dense: true,
          selected: isActive,
          selectedTileColor: const Color(0xFF84CC16).withAlpha(25),
          onTap: () {
            setState(() => _expanded = !_expanded);
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.children,
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
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
