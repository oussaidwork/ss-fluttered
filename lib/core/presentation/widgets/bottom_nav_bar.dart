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
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: const Color(0xFF0B1220),
      indicatorColor: const Color(0xFF84CC16).withAlpha(30),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard, color: Colors.white54),
          label: 'Home',
          selectedIcon: Icon(Icons.dashboard, color: Color(0xFF84CC16)),
        ),
        NavigationDestination(
          icon: Icon(Icons.local_gas_station, color: Colors.white54),
          label: 'Fuel',
          selectedIcon: Icon(Icons.local_gas_station, color: Color(0xFF84CC16)),
        ),
        NavigationDestination(
          icon: Icon(Icons.schedule, color: Colors.white54),
          label: 'Shifts',
          selectedIcon: Icon(Icons.schedule, color: Color(0xFF84CC16)),
        ),
        NavigationDestination(
          icon: Icon(Icons.people, color: Colors.white54),
          label: 'Clients',
          selectedIcon: Icon(Icons.people, color: Color(0xFF84CC16)),
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz, color: Colors.white54),
          label: 'More',
          selectedIcon: Icon(Icons.more_horiz, color: Color(0xFF84CC16)),
        ),
      ],
    );
  }
}
