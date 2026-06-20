import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

/// An animated speed-dial FAB that expands into quick-action buttons.
class FabSpeedDial extends StatefulWidget {
  const FabSpeedDial({super.key});

  @override
  State<FabSpeedDial> createState() => _FabSpeedDialState();
}

class _FabSpeedDialState extends State<FabSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) _toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isOpen) ...[
          _SpeedDialAction(
            icon: Icons.point_of_sale,
            label: 'New Sale',
            color: const Color(0xFF84CC16),
            onTap: () { _close(); context.go(AppRoutes.pos); },
            animValue: _expandAnimation,
            index: 0,
          ),
          _SpeedDialAction(
            icon: Icons.work_history,
            label: 'New Shift',
            color: const Color(0xFF0066CC),
            onTap: () { _close(); context.go(AppRoutes.shifts); },
            animValue: _expandAnimation,
            index: 1,
          ),
          _SpeedDialAction(
            icon: Icons.monetization_on,
            label: 'Add Expense',
            color: Colors.amber,
            onTap: () { _close(); context.go(AppRoutes.expenses); },
            animValue: _expandAnimation,
            index: 2,
          ),
          _SpeedDialAction(
            icon: Icons.people,
            label: 'Add Client',
            color: Colors.teal,
            onTap: () { _close(); context.go(AppRoutes.clients); },
            animValue: _expandAnimation,
            index: 3,
          ),
          _SpeedDialAction(
            icon: Icons.local_gas_station,
            label: 'Fuel Prices',
            color: Colors.orange,
            onTap: () { _close(); context.go(AppRoutes.fuel); },
            animValue: _expandAnimation,
            index: 4,
          ),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: _isOpen
              ? Colors.red.shade400
              : const Color(0xFF0066CC),
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SpeedDialAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Animation<double> animValue;
  final int index;

  const _SpeedDialAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.animValue,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizeTransition(
        sizeFactor: animValue,
        axisAlignment: 1.0,
        child: FadeTransition(
          opacity: animValue,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'fab_action_$index',
                backgroundColor: color,
                onPressed: onTap,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
