import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

/// Animated speed-dial FAB expanding into quick-action buttons.
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
  bool _isAnimating = false;
  OverlayEntry? _overlayEntry;

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
    _controller.addListener(_rebuildOverlay);
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuildOverlay);
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _rebuildOverlay() => _overlayEntry?.markNeedsBuild();

  void _toggle() {
    if (_isAnimating) return;
    if (_isOpen) {
      _closeDial();
    } else {
      _openDial();
    }
  }

  void _openDial() {
    if (_isAnimating) return;
    _isAnimating = true;
    _showOverlay();
    _controller.forward().then((_) => _isAnimating = false);
    setState(() => _isOpen = true);
  }

  void _closeDial() {
    if (_isAnimating) return;
    _isAnimating = true;
    _controller.reverse().then((_) {
      _isAnimating = false;
      if (mounted) _removeOverlay();
    });
    setState(() => _isOpen = false);
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (_) => _FabOverlay(
        expandAnimation: _expandAnimation,
        onClose: _closeDial,
        onAction: _closeDial,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FloatingActionButton(
      onPressed: _toggle,
      backgroundColor: _isOpen ? cs.error : cs.primary,
      child: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: _controller,
        color: cs.onPrimary,
      ),
    );
  }
}

// ── Overlay ──────────────────────────────────────────────────────

class _FabOverlay extends StatelessWidget {
  final Animation<double> expandAnimation;
  final VoidCallback onClose;
  final VoidCallback onAction;

  const _FabOverlay({
    required this.expandAnimation,
    required this.onClose,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    const fabSize = 56.0;
    const safeGap = 16.0;
    const actionSpacing = 8.0;
    const estimatedActionsHeight = 5.0 * 56.0 + 24.0;

    final fabBottomFromScreenBottom = safeGap + fabSize;
    final fabRightFromScreenRight = safeGap;

    final bool expandUpward =
        (screenHeight - fabBottomFromScreenBottom - bottomInset) >=
            estimatedActionsHeight + actionSpacing;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          right: isRtl ? null : fabRightFromScreenRight,
          left: isRtl ? fabRightFromScreenRight : null,
          bottom: expandUpward
              ? fabBottomFromScreenBottom + actionSpacing
              : null,
          top: expandUpward ? null : fabBottomFromScreenBottom + actionSpacing,
          child: _ActionsPanel(animation: expandAnimation, onAction: onAction),
        ),
      ],
    );
  }
}

// ── Action buttons ───────────────────────────────────────────────

class _ActionsPanel extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onAction;

  const _ActionsPanel({required this.animation, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _SpeedDialAction(
          icon: Icons.point_of_sale,
          label: 'New Sale',
          color: cs.secondary,
          onTap: () {
            onAction();
            context.go(AppRoutes.pos);
          },
          animValue: animation,
          index: 0,
        ),
        _SpeedDialAction(
          icon: Icons.work_history,
          label: 'New Shift',
          color: cs.primary,
          onTap: () {
            onAction();
            context.go(AppRoutes.shifts);
          },
          animValue: animation,
          index: 1,
        ),
        _SpeedDialAction(
          icon: Icons.monetization_on,
          label: 'Add Expense',
          color: cs.tertiary,
          onTap: () {
            onAction();
            context.go(AppRoutes.expenses);
          },
          animValue: animation,
          index: 2,
        ),
        _SpeedDialAction(
          icon: Icons.people,
          label: 'Add Client',
          color: cs.primaryContainer,
          onTap: () {
            onAction();
            context.go(AppRoutes.clients);
          },
          animValue: animation,
          index: 3,
        ),
        _SpeedDialAction(
          icon: Icons.local_gas_station,
          label: 'Fuel Prices',
          color: cs.secondaryContainer,
          onTap: () {
            onAction();
            context.go(AppRoutes.fuel);
          },
          animValue: animation,
          index: 4,
        ),
      ],
    );
  }
}

// ── Individual action ────────────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;

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
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  label,
                  style: TextStyle(color: cs.onSurface, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'fab_action_$index',
                backgroundColor: color,
                onPressed: onTap,
                child: Icon(icon, color: cs.onPrimary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
