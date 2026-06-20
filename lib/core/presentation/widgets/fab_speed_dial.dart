import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';

/// An animated speed-dial FAB that expands into quick-action buttons.
///
/// Uses an [OverlayEntry] to render the action buttons in a separate layer
/// so they are properly positioned within the viewport and never overflow
/// beyond the screen bounds.
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
  final GlobalKey _fabKey = GlobalKey();

  // ────────────────────────────────────────────────────────────────
  // Lifecycle
  // ────────────────────────────────────────────────────────────────

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

  // ────────────────────────────────────────────────────────────────
  // Overlay management
  // ────────────────────────────────────────────────────────────────

  void _rebuildOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

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

  // ────────────────────────────────────────────────────────────────
  // OverlayEntry
  // ────────────────────────────────────────────────────────────────

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (_) => _FabOverlay(
        fabKey: _fabKey,
        expandAnimation: _expandAnimation,
        onClose: _closeDial,
        onAction: _closeDial,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      key: _fabKey,
      onPressed: _toggle,
      backgroundColor: _isOpen
          ? Colors.red.shade400
          : const Color(0xFF0066CC),
      child: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: _controller,
        color: Colors.white,
      ),
    );
  }
}

// ======================================================================
// Overlay widget that positions the action buttons above the FAB
// ======================================================================

class _FabOverlay extends StatelessWidget {
  final GlobalKey fabKey;
  final Animation<double> expandAnimation;
  final VoidCallback onClose;
  final VoidCallback onAction;

  const _FabOverlay({
    required this.fabKey,
    required this.expandAnimation,
    required this.onClose,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final fabRenderBox =
        fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (fabRenderBox == null || !fabRenderBox.hasSize) {
      return const SizedBox.shrink();
    }

    final fabPosition = fabRenderBox.localToGlobal(Offset.zero);
    final fabSize = fabRenderBox.size;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final bottomInset =
        mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // The FAB centre X on screen
    final fabCenterX = fabPosition.dx + fabSize.width / 2;

    // Available vertical space above the FAB (subtract bottom insets
    // for keyboard / navigation bar so we don't over-estimate)
    final spaceAbove = fabPosition.dy - bottomInset;
    // Estimated height of all actions (5 actions × ~56dp + padding)
    const estimatedActionsHeight = 5.0 * 56.0 + 24.0;

    // If there's not enough room above, flip the direction so actions
    // appear below the FAB instead (pointing upward is the default).
    final bool expandUpward = spaceAbove >= estimatedActionsHeight;

    // Distance from the FAB's top/bottom edge to the screen edge
    final fabBottomFromScreenBottom = screenHeight - fabPosition.dy;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ---- Tap barrier (dismisses the speed dial) ----
        // We exclude the FAB area from the barrier so tapping the
        // FAB button itself still toggles the dial.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        // ---- Actions positioned relative to the FAB ----
        // The actions column is aligned so that the small FAB buttons
        // sit directly above (or below) the main FAB.
        // In LTR the column is right-aligned (FAB.small on the right,
        // labels extending left). In RTL the opposite.
        Positioned(
          right: isRtl ? null : screenWidth - fabCenterX,
          left: isRtl ? fabCenterX : null,
          bottom: expandUpward
              ? fabBottomFromScreenBottom + 8.0
              : null,
          top: expandUpward
              ? null
              : fabPosition.dy + fabSize.height + 8.0,
          child: _ActionsPanel(
            animation: expandAnimation,
            onAction: onAction,
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// The list of action buttons (animated)
// ======================================================================

class _ActionsPanel extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onAction;

  const _ActionsPanel({
    required this.animation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _SpeedDialAction(
          icon: Icons.point_of_sale,
          label: 'New Sale',
          color: const Color(0xFF84CC16),
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
          color: const Color(0xFF0066CC),
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
          color: Colors.amber,
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
          color: Colors.teal,
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
          color: Colors.orange,
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

// ======================================================================
// Individual action button (label + small FAB)
// ======================================================================

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  label,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 12),
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
