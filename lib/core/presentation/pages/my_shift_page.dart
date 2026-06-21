import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../data/auth/firebase_auth_provider.dart';
import '../../../domain/entities/work_shift.dart';
import '../../../domain/entities/shift_pump.dart';
import '../../../domain/entities/pump.dart';
import '../../../domain/entities/gas_type.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/enums/shift_status.dart';
import '../../../presentation/providers/auth_provider.dart';

/// Phase of the My Shift workflow.
enum _ShiftPhase {
  /// No active shift — show LaunchBay to start one.
  open,

  /// Active shift — record transactions.
  active,

  /// Closing sub-flow: select which pumps were used.
  pumpSelect,

  /// Closing sub-flow: enter end analog counter readings.
  endReadings,

  /// Closing sub-flow: review audit + print Z-report + submit.
  auditPrint,

  /// Closed — show summary.
  done,
}

/// Worker-facing "My Shift" page with a phase-based orchestrator.
/// Mirrors the React MyShiftWorkflow.tsx spec.
class MyShiftPage extends ConsumerStatefulWidget {
  const MyShiftPage({super.key});

  @override
  ConsumerState<MyShiftPage> createState() => _MyShiftPageState();
}

class _MyShiftPageState extends ConsumerState<MyShiftPage> {
  _ShiftPhase _phase = _ShiftPhase.open;
  WorkShift? _activeShift;
  String? _workerId;
  String? _workerName;

  // Close-flow state
  final Set<String> _selectedPumpIds = {};
  final Map<String, TextEditingController> _endCounterControllers = {};
  final _cashController = TextEditingController();
  final _otherRevenueController = TextEditingController(text: '0');

  // Sales recorded during this shift
  final List<Sale> _sales = [];

  @override
  void initState() {
    super.initState();
    _otherRevenueController.text = '0';
  }

  @override
  void dispose() {
    _cashController.dispose();
    _otherRevenueController.dispose();
    for (final c in _endCounterControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);

    return profileAsync.when(
      data: (profile) {
        _workerId = currentUser?.uid ?? profile?.id;
        _workerName = profile?.fullName ?? currentUser?.email ?? 'Worker';
        // Check for existing active shift
        return _buildWithActiveShiftCheck();
      },
      loading: () =>
          Center(child: CircularProgressIndicator(color: cs.primary)),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: cs.error)),
      ),
    );
  }

  Widget _buildWithActiveShiftCheck() {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('work_shifts')
          .where('status', isEqualTo: 'OPEN')
          .where('workerId', isEqualTo: _workerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final doc = snapshot.data!.docs.first;
          _activeShift = WorkShift.fromMap(doc.data() as Map<String, dynamic>);
          // If we were in open phase but found an active shift, switch to active
          if (_phase == _ShiftPhase.open) {
            _phase = _ShiftPhase.active;
          }
        } else {
          _activeShift = null;
          if (_phase != _ShiftPhase.done) {
            _phase = _ShiftPhase.open;
          }
        }

        return _buildPhaseContent();
      },
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _ShiftPhase.open:
        return _LaunchBay(
          workerName: _workerName ?? 'Worker',
          onStartShift: _startShift,
        );
      case _ShiftPhase.active:
        return _TransactionPod(
          shift: _activeShift,
          workerName: _workerName ?? 'Worker',
          onCloseShift: () => setState(() => _phase = _ShiftPhase.pumpSelect),
        );
      case _ShiftPhase.pumpSelect:
        return _PumpSelectionView(
          selectedPumpIds: _selectedPumpIds,
          onToggle: (id) {
            setState(() {
              if (_selectedPumpIds.contains(id)) {
                _selectedPumpIds.remove(id);
              } else {
                _selectedPumpIds.add(id);
              }
            });
          },
          onNext: () => setState(() => _phase = _ShiftPhase.endReadings),
          onCancel: () => setState(() {
            _selectedPumpIds.clear();
            _phase = _ShiftPhase.active;
          }),
        );
      case _ShiftPhase.endReadings:
        return _EndReadingsView(
          shift: _activeShift,
          selectedPumpIds: _selectedPumpIds,
          controllers: _endCounterControllers,
          onNext: () => setState(() => _phase = _ShiftPhase.auditPrint),
          onCancel: () => setState(() => _phase = _ShiftPhase.pumpSelect),
        );
      case _ShiftPhase.auditPrint:
        return _AuditPrintView(
          shift: _activeShift,
          selectedPumpIds: _selectedPumpIds,
          endCounterControllers: _endCounterControllers,
          cashController: _cashController,
          otherRevenueController: _otherRevenueController,
          onSubmit: _closeShift,
          onCancel: () => setState(() => _phase = _ShiftPhase.endReadings),
        );
      case _ShiftPhase.done:
        return _ShiftSummary(
          shift: _activeShift,
          onNewShift: () => setState(() {
            _activeShift = null;
            _selectedPumpIds.clear();
            _endCounterControllers.clear();
            _cashController.clear();
            _otherRevenueController.text = '0';
            _sales.clear();
            _phase = _ShiftPhase.open;
          }),
        );
    }
  }

  // ──────────────────────────────────────────────
  // START SHIFT
  // ──────────────────────────────────────────────

  Future<void> _startShift() async {
    final workerId = _workerId;
    if (workerId == null) return;

    try {
      // Get all active pumps
      final pumpsSnap = await firestore
          .collection('pumps')
          .where('isDeleted', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .get();
      final pumps = pumpsSnap.docs
          .map(
            (d) =>
                Pump.fromMap({...d.data() as Map<String, dynamic>, 'id': d.id}),
          )
          .toList();

      // Get gas types for pricing
      final gasTypesSnap = await firestore
          .collection('gas_types')
          .where('isDeleted', isEqualTo: false)
          .get();
      final gasTypes = gasTypesSnap.docs
          .map(
            (d) => GasType.fromMap({
              ...d.data() as Map<String, dynamic>,
              'id': d.id,
            }),
          )
          .toList();

      // Get pits to map pitId -> gasTypeId
      final pitsSnap = await firestore
          .collection('pits')
          .where('isDeleted', isEqualTo: false)
          .get();
      final Map<String, String> pitGasTypeMap = {};
      for (final d in pitsSnap.docs) {
        final data = d.data();
        if (data['gasTypeId'] != null) {
          pitGasTypeMap[d.id] = data['gasTypeId'] as String;
        }
      }

      // Build pump -> gasType mapping
      final Map<String, String> pumpGasTypeMap = {};
      for (final pump in pumps) {
        final gasTypeId = pitGasTypeMap[pump.pitId];
        if (gasTypeId != null) {
          pumpGasTypeMap[pump.id] = gasTypeId;
        }
      }

      // Get last shift's counters for chain data
      final lastShiftSnap = await firestore
          .collection('work_shifts')
          .where('status', isEqualTo: 'CLOSED')
          .orderBy('endTime', descending: true)
          .limit(1)
          .get();
      String? lastShiftId;
      if (lastShiftSnap.docs.isNotEmpty) {
        lastShiftId = lastShiftSnap.docs.first.id;
      }

      final Map<String, double> lastEndCounters = {};
      if (lastShiftId != null) {
        final lastSpSnap = await firestore
            .collection('shift_pumps')
            .where('shiftId', isEqualTo: lastShiftId)
            .get();
        for (final d in lastSpSnap.docs) {
          final data = d.data();
          final pumpId = data['pumpId'] as String? ?? '';
          final endCounter = (data['endAnalogCounter'] as num?)?.toDouble();
          if (pumpId.isNotEmpty && endCounter != null) {
            lastEndCounters[pumpId] = endCounter;
          }
        }
      }

      final now = DateTime.now();
      final shiftId = firestore.collection('work_shifts').doc().id;

      // Create WorkShift
      await firestore.collection('work_shifts').doc(shiftId).set({
        'id': shiftId,
        'workerId': workerId,
        'startTime': Timestamp.fromDate(now),
        'endTime': Timestamp.fromDate(now),
        'status': 'OPEN',
        'actualCash': null,
        'expectedCash': null,
        'createdAt': Timestamp.fromDate(now),
        'isDeleted': false,
      });

      // Create ShiftPump records for each active pump
      final batch = firestore.batch();
      for (final pump in pumps) {
        final spId = firestore.collection('shift_pumps').doc().id;
        final startCounter =
            lastEndCounters[pump.id] ?? pump.initialAnalogCounter;
        final gasTypeId = pumpGasTypeMap[pump.id];
        final priceAtShift = gasTypes
            .where((g) => g.id == gasTypeId)
            .map((g) => g.priceOut)
            .firstOrNull;

        final spDoc = firestore.collection('shift_pumps').doc(spId);
        batch.set(spDoc, {
          'id': spId,
          'shiftId': shiftId,
          'pumpId': pump.id,
          'startAnalogCounter': startCounter,
          'endAnalogCounter': null,
          'priceAtShift': priceAtShift,
          'volume': 0,
          'revenue': 0,
        });
      }
      await batch.commit();

      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shift started successfully!'),
            backgroundColor: cs.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start shift: $e'),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────────────
  // CLOSE SHIFT
  // ──────────────────────────────────────────────

  Future<void> _closeShift() async {
    final shift = _activeShift;
    if (shift == null) return;

    try {
      // Get all shift_pump records for this shift
      final spSnap = await firestore
          .collection('shift_pumps')
          .where('shiftId', isEqualTo: shift.id)
          .get();
      final shiftPumps = spSnap.docs
          .map(
            (d) => ShiftPump.fromMap({
              ...d.data() as Map<String, dynamic>,
              'id': d.id,
            }),
          )
          .toList();

      // Update each ShiftPump with end analog counters
      double totalPumpRevenue = 0;
      final batch = firestore.batch();
      for (final pumpId in _selectedPumpIds) {
        final controller = _endCounterControllers[pumpId];
        if (controller == null) continue;
        final endCounter = double.tryParse(controller.text);
        if (endCounter == null) continue;

        final sp = shiftPumps.firstWhere(
          (s) => s.pumpId == pumpId,
          orElse: () => ShiftPump(
            id: '',
            shiftId: shift.id,
            pumpId: pumpId,
            startAnalogCounter: 0,
          ),
        );
        if (sp.id.isEmpty) continue;

        final volume = endCounter - sp.startAnalogCounter;
        final revenue = volume * (sp.priceAtShift ?? 0);

        batch.update(firestore.collection('shift_pumps').doc(sp.id), {
          'endAnalogCounter': endCounter,
          'volume': volume,
          'revenue': revenue,
        });
        totalPumpRevenue += revenue;
      }

      await batch.commit();

      // Update WorkShift
      final otherRevenue = double.tryParse(_otherRevenueController.text) ?? 0;
      final actualCash = double.tryParse(_cashController.text) ?? 0;
      final expectedCash = totalPumpRevenue + otherRevenue;

      await firestore.collection('work_shifts').doc(shift.id).update({
        'status': 'CLOSED',
        'endTime': Timestamp.now(),
        'actualCash': actualCash,
        'expectedCash': expectedCash,
      });

      if (mounted) {
        setState(() {
          _activeShift = shift.copyWith(
            status: ShiftStatus.closed,
            actualCash: actualCash,
            expectedCash: expectedCash,
            endTime: DateTime.now(),
          );
          _phase = _ShiftPhase.done;
        });

        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Shift closed. Expected: ${expectedCash.toStringAsFixed(2)} DA, Actual: ${actualCash.toStringAsFixed(2)} DA',
            ),
            backgroundColor: cs.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close shift: $e'),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 1: LAUNCH BAY
// ══════════════════════════════════════════════════════════════════════════════

class _LaunchBay extends StatelessWidget {
  final String workerName;
  final VoidCallback onStartShift;

  const _LaunchBay({required this.workerName, required this.onStartShift});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 80, color: cs.secondary),
          const SizedBox(height: 24),
          Text(
            'Welcome, $workerName',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your shift to begin recording transactions',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.54),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 260,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onStartShift,
              icon: const Icon(Icons.play_arrow, size: 24),
              label: const Text('Start Shift', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.secondary,
                foregroundColor: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 2: TRANSACTION POD
// ══════════════════════════════════════════════════════════════════════════════

class _TransactionPod extends StatelessWidget {
  final WorkShift? shift;
  final String workerName;
  final VoidCallback onCloseShift;

  const _TransactionPod({
    required this.shift,
    required this.workerName,
    required this.onCloseShift,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shiftStart = shift?.startTime ?? DateTime.now();
    final duration = DateTime.now().difference(shiftStart);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.play_circle, color: cs.secondary, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Shift',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    '$workerName  •  ${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.54),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: cs.secondary),
                    SizedBox(width: 6),
                    Text(
                      'OPEN',
                      style: TextStyle(
                        color: cs.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions card
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 64,
                    color: cs.onSurface.withValues(alpha: 0.24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recording transactions...',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.54),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the POS page or Clients page to record sales',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.38),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 240,
                    child: ElevatedButton.icon(
                      onPressed: onCloseShift,
                      icon: const Icon(Icons.lock_clock, size: 20),
                      label: const Text('Close Shift'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 3: PUMP SELECTION
// ══════════════════════════════════════════════════════════════════════════════

class _PumpSelectionView extends StatelessWidget {
  final Set<String> selectedPumpIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const _PumpSelectionView({
    required this.selectedPumpIds,
    required this.onToggle,
    required this.onNext,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Select Active Pumps',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select which pumps were used during this shift',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.54),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('pumps')
                  .where('isDeleted', isEqualTo: false)
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final cs = Theme.of(context).colorScheme;
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }
                final pumps = snapshot.data!.docs;
                if (pumps.isEmpty) {
                  return Center(
                    child: Text(
                      'No active pumps found',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.54),
                      ),
                    ),
                  );
                }
                // change this tiles with group folding and a select all togle
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: pumps.length,
                  itemBuilder: (ctx, idx) {
                    final doc = pumps[idx];
                    final data = doc.data() as Map<String, dynamic>;
                    final pumpId = doc.id;
                    final name = data['name'] ?? 'Pump ${idx + 1}';
                    final isSelected = selectedPumpIds.contains(pumpId);
                    return GestureDetector(
                      onTap: () => onToggle(pumpId),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primary.withValues(alpha: 0.2)
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.12),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.local_gas_station,
                              color: isSelected
                                  ? cs.secondary
                                  : cs.onSurface.withValues(alpha: 0.38),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              style: TextStyle(
                                color: isSelected
                                    ? cs.onSurface
                                    : cs.onSurface.withValues(alpha: 0.7),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface.withValues(alpha: 0.54),
                  side: BorderSide(color: cs.onSurface.withValues(alpha: 0.12)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: selectedPumpIds.isEmpty ? null : onNext,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text('Next (${selectedPumpIds.length} selected)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onSurface,
                  disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
                  disabledForegroundColor: cs.onSurface.withValues(alpha: 0.24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 4: END READINGS
// ══════════════════════════════════════════════════════════════════════════════

class _EndReadingsView extends StatelessWidget {
  final WorkShift? shift;
  final Set<String> selectedPumpIds;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const _EndReadingsView({
    required this.shift,
    required this.selectedPumpIds,
    required this.controllers,
    required this.onNext,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'End Counter Readings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the end analog counter readings for each selected pump',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.54),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('shift_pumps')
                  .where('shiftId', isEqualTo: shift?.id ?? '')
                  .snapshots(),
              builder: (context, snapshot) {
                final cs = Theme.of(context).colorScheme;
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }
                final shiftPumps = snapshot.data!.docs
                    .map(
                      (d) => ShiftPump.fromMap({
                        ...d.data() as Map<String, dynamic>,
                        'id': d.id,
                      }),
                    )
                    .where((sp) => selectedPumpIds.contains(sp.pumpId))
                    .toList();

                if (shiftPumps.isEmpty) {
                  return Center(
                    child: Text(
                      'No pump data found',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.54),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: shiftPumps.length,
                  itemBuilder: (ctx, idx) {
                    final sp = shiftPumps[idx];
                    // Ensure controller exists
                    controllers.putIfAbsent(sp.pumpId, () {
                      return TextEditingController(
                        text: sp.endAnalogCounter?.toStringAsFixed(1) ?? '',
                      );
                    });

                    return FutureBuilder<DocumentSnapshot>(
                      future: firestore
                          .collection('pumps')
                          .doc(sp.pumpId)
                          .get(),
                      builder: (ctx, pumpSnap) {
                        final data = pumpSnap.hasData
                            ? pumpSnap.data!.data()
                            : null;
                        final pumpName =
                            (data as Map<String, dynamic>?)?['name']
                                as String? ??
                            sp.pumpId;

                        return Card(
                          color: cs.surfaceContainerHighest,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pumpName,
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Start: ${sp.startAnalogCounter.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          color: cs.onSurface.withValues(
                                            alpha: 0.54,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: TextFormField(
                                    controller: controllers[sp.pumpId],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'End counter',
                                      hintStyle: TextStyle(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.24,
                                        ),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: cs.onSurface.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: cs.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface.withValues(alpha: 0.54),
                  side: BorderSide(color: cs.onSurface.withValues(alpha: 0.54)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Back'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Review & Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 5: AUDIT PRINT & SUBMIT
// ══════════════════════════════════════════════════════════════════════════════

class _AuditPrintView extends StatelessWidget {
  final WorkShift? shift;
  final Set<String> selectedPumpIds;
  final Map<String, TextEditingController> endCounterControllers;
  final TextEditingController cashController;
  final TextEditingController otherRevenueController;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _AuditPrintView({
    required this.shift,
    required this.selectedPumpIds,
    required this.endCounterControllers,
    required this.cashController,
    required this.otherRevenueController,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Audit & Submit',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('shift_pumps')
                  .where('shiftId', isEqualTo: shift?.id ?? '')
                  .snapshots(),
              builder: (context, snapshot) {
                final cs = Theme.of(context).colorScheme;
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }
                final shiftPumps = snapshot.data!.docs
                    .map(
                      (d) => ShiftPump.fromMap({
                        ...d.data() as Map<String, dynamic>,
                        'id': d.id,
                      }),
                    )
                    .where((sp) => selectedPumpIds.contains(sp.pumpId))
                    .toList();

                double totalExpected = 0;
                final pumpDetails = <Map<String, dynamic>>[];

                for (final sp in shiftPumps) {
                  final ctrl = endCounterControllers[sp.pumpId];
                  final endVal = double.tryParse(ctrl?.text ?? '');
                  double volume = 0;
                  double revenue = 0;
                  if (endVal != null && endVal > sp.startAnalogCounter) {
                    volume = endVal - sp.startAnalogCounter;
                    revenue = volume * (sp.priceAtShift ?? 0);
                    totalExpected += revenue;
                  }
                  pumpDetails.add({
                    'pumpId': sp.pumpId,
                    'start': sp.startAnalogCounter,
                    'end': endVal ?? 0,
                    'volume': volume,
                    'revenue': revenue,
                    'price': sp.priceAtShift,
                  });
                }

                final otherRev =
                    double.tryParse(otherRevenueController.text) ?? 0;
                totalExpected += otherRev;
                final actualCash = double.tryParse(cashController.text) ?? 0;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Pump summary table
                      ...pumpDetails.map(
                        (pd) => FutureBuilder<DocumentSnapshot>(
                          future: firestore
                              .collection('pumps')
                              .doc(pd['pumpId'] as String)
                              .get(),
                          builder: (ctx, pumpSnap) {
                            final pumpData = pumpSnap.hasData
                                ? pumpSnap.data!.data()
                                : null;
                            final pumpName =
                                (pumpData as Map<String, dynamic>?)?['name']
                                    as String? ??
                                pd['pumpId'];
                            return Card(
                              color: cs.surfaceContainerHighest,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pumpName,
                                            style: TextStyle(
                                              color: cs.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${(pd['start'] as double).toStringAsFixed(1)} → ${(pd['end'] as double).toStringAsFixed(1)}',
                                            style: TextStyle(
                                              color: cs.onSurface.withValues(
                                                alpha: 0.54,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${(pd['volume'] as double).toStringAsFixed(1)}L',
                                      style: TextStyle(
                                        color: cs.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${(pd['revenue'] as double).toStringAsFixed(2)} DA',
                                      style: TextStyle(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Other revenue field
                      Card(
                        color: cs.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Text(
                                'Other Revenue (DA):',
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: otherRevenueController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  style: TextStyle(color: cs.onSurface),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: cs.primary),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Expected total
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _summaryRow(
                              cs,
                              'Pump Revenue',
                              '${(totalExpected - otherRev).toStringAsFixed(2)} DA',
                            ),
                            _summaryRow(
                              cs,
                              'Other Revenue',
                              '${otherRev.toStringAsFixed(2)} DA',
                            ),
                            Divider(
                              color: cs.onSurface.withValues(alpha: 0.12),
                            ),
                            _summaryRow(
                              cs,
                              'Total Expected',
                              '${totalExpected.toStringAsFixed(2)} DA',
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actual cash
                      Card(
                        color: cs.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Actual Cash in Register',
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: cashController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  prefixText: 'DA ',
                                  prefixStyle: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.38),
                                  ),
                                  hintStyle: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.24),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: cs.primary),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              if (actualCash > 0 && totalExpected > 0) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Difference:',
                                      style: TextStyle(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.54,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(actualCash - totalExpected) >= 0 ? '+' : ''}${(actualCash - totalExpected).toStringAsFixed(2)} DA',
                                      style: TextStyle(
                                        color: actualCash >= totalExpected
                                            ? cs.secondary
                                            : cs.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface.withValues(alpha: 0.54),
                  side: BorderSide(color: cs.onSurface.withValues(alpha: 0.12)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Back'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.lock_clock, size: 18),
                label: const Text('Close Shift & Print Z-Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.secondary,
                  foregroundColor: cs.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    ColorScheme cs,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.54),
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: bold ? cs.secondary : cs.onSurface,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 6: SHIFT SUMMARY
// ══════════════════════════════════════════════════════════════════════════════

class _ShiftSummary extends StatelessWidget {
  final WorkShift? shift;
  final VoidCallback onNewShift;

  const _ShiftSummary({required this.shift, required this.onNewShift});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expected = shift?.expectedCash ?? 0;
    final actual = shift?.actualCash ?? 0;
    final diff = actual - expected;
    final isBalanced = diff.abs() < 0.01;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBalanced ? Icons.check_circle : Icons.warning_amber,
            size: 80,
            color: isBalanced ? cs.secondary : cs.tertiary,
          ),
          const SizedBox(height: 24),
          Text(
            'Shift Closed',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBalanced
                ? 'All cash reconciled successfully'
                : 'There is a cash discrepancy',
            style: TextStyle(
              color: isBalanced ? cs.secondary : cs.tertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _summaryLine(
                  cs,
                  'Expected',
                  '${expected.toStringAsFixed(2)} DA',
                ),
                const SizedBox(height: 8),
                _summaryLine(cs, 'Actual', '${actual.toStringAsFixed(2)} DA'),
                Divider(color: cs.onSurface.withValues(alpha: 0.12)),
                _summaryLine(
                  cs,
                  'Difference',
                  '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)} DA',
                  color: isBalanced ? cs.secondary : cs.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 240,
            child: ElevatedButton.icon(
              onPressed: onNewShift,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Start New Shift'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(
    ColorScheme cs,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.54),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
