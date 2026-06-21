import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    this.currentIndex = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: cs.surface,
      indicatorColor: cs.secondary.withValues(alpha: 0.2),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard),
          label: 'Home',
          selectedIcon: Icon(Icons.dashboard),
        ),
        NavigationDestination(
          icon: Icon(Icons.local_gas_station),
          label: 'Fuel',
          selectedIcon: Icon(Icons.local_gas_station),
        ),
        NavigationDestination(
          icon: Icon(Icons.schedule),
          label: 'Shifts',
          selectedIcon: Icon(Icons.schedule),
        ),
        NavigationDestination(
          icon: Icon(Icons.people),
          label: 'Clients',
          selectedIcon: Icon(Icons.people),
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'More',
          selectedIcon: Icon(Icons.more_horiz),
        ),
      ],
    );
  }
}
