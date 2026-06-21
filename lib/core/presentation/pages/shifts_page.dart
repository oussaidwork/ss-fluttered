import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/work_shift.dart';
import '../../../domain/entities/shift_pump.dart';
import '../../../domain/entities/pump.dart';
import '../../../domain/entities/gas_type.dart';
import '../../../domain/enums/shift_status.dart';

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  ShiftStatus? _statusFilter;
  String? _selectedShiftId;
  bool _isStartingShift = false;

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
              Icon(Icons.schedule, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Shift Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              _buildStartShiftButton(),
              const SizedBox(width: 12),
              _buildStatusFilter(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('work_shifts')
                  .where('isDeleted', isEqualTo: false)
                  .orderBy('startTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }
                final shifts = snapshot.data!.docs
                    .map(
                      (doc) =>
                          WorkShift.fromMap(doc.data() as Map<String, dynamic>),
                    )
                    .where(
                      (s) => _statusFilter == null || s.status == _statusFilter,
                    )
                    .toList();
                if (shifts.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildShiftTable(shifts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartShiftButton() {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: _isStartingShift ? null : _startNewShift,
      icon: _isStartingShift
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.onSurface,
              ),
            )
          : const Icon(Icons.add, size: 18),
      label: Text(_isStartingShift ? 'Starting...' : 'Start New Shift'),
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.secondary,
        foregroundColor: cs.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ShiftStatus?>(
          value: _statusFilter,
          dropdownColor: cs.surfaceContainerHighest,
          style: TextStyle(color: cs.onSurface),
          icon: Icon(Icons.filter_list, color: cs.onSurface.withValues(alpha: 0.54), size: 20),
          hint: Text(
            'All Status',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
          ),
          items: [
            DropdownMenuItem<ShiftStatus?>(
              value: null,
              child: Text('All Status'),
            ),
            ...ShiftStatus.values.map(
              (s) => DropdownMenuItem(value: s, child: Text(s.value)),
            ),
          ],
          onChanged: (val) => setState(() => _statusFilter = val),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusFilter != null ? Icons.filter_list_off : Icons.schedule,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.24),
          ),
          const SizedBox(height: 16),
          Text(
            _statusFilter != null
                ? 'No shifts with this status'
                : 'No shifts yet',
            style: TextStyle(fontSize: 18, color: cs.onSurface.withValues(alpha: 0.54)),
          ),
          const SizedBox(height: 24),
          if (_statusFilter == null)
            ElevatedButton.icon(
              onPressed: _startNewShift,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Start First Shift'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.secondary,
                foregroundColor: cs.surface,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShiftTable(List<WorkShift> shifts) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              cs.onSurface.withValues(alpha: 0.05),
            ),
            columns: [
              DataColumn(
                label: Text(
                  'Worker',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Start Time',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'End Time',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Revenue',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Expected',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actual Cash',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Diff',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            rows: shifts.map((shift) {
              final isSelected = _selectedShiftId == shift.id;
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) => _showShiftDetails(shift),
                color: shift.status == ShiftStatus.open
                    ? WidgetStateProperty.all(
                        cs.secondary.withAlpha(8),
                      )
                    : null,
                cells: [
                  DataCell(_WorkerNameCell(workerId: shift.workerId)),
                  DataCell(
                    Text(
                      _formatDate(shift.startTime),
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                  DataCell(
                    Text(
                      shift.status == ShiftStatus.open
                          ? '--'
                          : _formatDate(shift.endTime),
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                  DataCell(_buildStatusBadge(shift.status)),
                  DataCell(
                    Text(
                      shift.expectedCash != null
                          ? '${shift.expectedCash!.toStringAsFixed(2)} DA'
                          : '--',
                      style: TextStyle(
                        color: shift.expectedCash != null
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      shift.expectedCash != null
                          ? '${shift.expectedCash!.toStringAsFixed(2)} DA'
                          : '--',
                      style: TextStyle(color: cs.secondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      shift.actualCash != null
                          ? '${shift.actualCash!.toStringAsFixed(2)} DA'
                          : '--',
                      style: TextStyle(
                        color: shift.actualCash != null
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                  DataCell(_buildDiffCell(shift)),
                  DataCell(
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: cs.error,
                        size: 20,
                      ),
                      tooltip: 'Delete shift',
                      onPressed: () => _deleteShift(shift),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDiffCell(WorkShift shift) {
    final cs = Theme.of(context).colorScheme;
    if (shift.actualCash == null || shift.expectedCash == null) {
      return Text('--', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38)));
    }
    final diff = shift.actualCash! - shift.expectedCash!;
    final isOver = diff >= 0;
    return Text(
      '${isOver ? '+' : ''}${diff.toStringAsFixed(2)} DA',
      style: TextStyle(
        color: isOver ? cs.secondary : cs.error,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _deleteShift(WorkShift shift) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text(
          'Delete Shift',
          style: TextStyle(color: cs.onSurface),
        ),
        content: Text(
          'Delete shift for ${_formatDate(shift.startTime)}?',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );},
    );

    if (confirmed != true || !mounted) return;

    try {
      final batch = firestore.batch();
      batch.delete(firestore.collection('work_shifts').doc(shift.id));

      final shiftPumpsSnap = await firestore
          .collection('shift_pumps')
          .where('shiftId', isEqualTo: shift.id)
          .get();

      for (final doc in shiftPumpsSnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shift deleted successfully.'),
            backgroundColor: cs.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete shift: $e'),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(ShiftStatus status) {
    final cs = Theme.of(context).colorScheme;
    final isOpen = status == ShiftStatus.open;
    final badgeColor = isOpen ? cs.secondary : cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // START NEW SHIFT
  // ──────────────────────────────────────────────

  Future<void> _startNewShift() async {
    // Check if there's already an open shift
    final openSnap = await firestore
        .collection('work_shifts')
        .where('status', isEqualTo: 'OPEN')
        .limit(1)
        .get();
    if (openSnap.docs.isNotEmpty && mounted) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An open shift already exists. Close it first.'),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    // Show worker selection dialog
    final selectedWorkerId = await _showWorkerSelectionDialog();
    if (selectedWorkerId == null || !mounted) return;

    setState(() => _isStartingShift = true);

    try {
      // Get all active pumps
      final pumpsSnap = await firestore
          .collection('pumps')
          .where('isDeleted', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .get();
      final pumps = pumpsSnap.docs
          .map((d) => Pump.fromMap(d.data()..putIfAbsent('id', () => d.id)))
          .toList();

      // Get gas types for pricing
      final gasTypesSnap = await firestore
          .collection('gas_types')
          .where('isDeleted', isEqualTo: false)
          .get();
      final gasTypes = gasTypesSnap.docs
          .map((d) => GasType.fromMap(d.data()..putIfAbsent('id', () => d.id)))
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

      // Build a map pumpPitId -> gasTypeId
      final Map<String, String> pumpGasTypeMap = {};
      for (final pump in pumps) {
        final gasTypeId = pitGasTypeMap[pump.pitId];
        if (gasTypeId != null) {
          pumpGasTypeMap[pump.id] = gasTypeId;
        }
      }

      // Get the last shift's pump counters for chain
      final lastShiftSnap = await firestore
          .collection('work_shifts')
          .where('status', isEqualTo: 'CLOSED')
          .orderBy('endTime', descending: true)
          .limit(1)
          .get();
      String? lastShiftId;
      if (lastShiftSnap.docs.isNotEmpty) {
        final lastShift = WorkShift.fromMap(lastShiftSnap.docs.first.data());
        lastShiftId = lastShift.id;
      }

      // Get end counters from last shift
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
        'workerId': selectedWorkerId,
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
            content: Text('Shift started successfully with pump matrix.'),
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
    } finally {
      if (mounted) setState(() => _isStartingShift = false);
    }
  }

  Future<String?> _showWorkerSelectionDialog() async {
    final workersSnap = await firestore.collection('users').get();
    final workers = workersSnap.docs.map((d) {
      final data = d.data();
      return MapEntry(d.id, data['fullName'] as String? ?? d.id);
    }).toList();

    if (!mounted) return null;
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Worker',
          style: TextStyle(color: cs.onSurface),
        ),
        content: SizedBox(
          width: 320,
          child: workers.isEmpty
              ? Text(
                  'No workers found. Add workers first.',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: workers.map((entry) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primary.withAlpha(30),
                        child: Text(
                          entry.value.isNotEmpty
                              ? entry.value[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: cs.primary),
                        ),
                      ),
                      title: Text(
                        entry.value,
                        style: TextStyle(color: cs.onSurface),
                      ),
                      onTap: () => Navigator.of(ctx).pop(entry.key),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
            ),
          ),
        ],
      );},
    );
  }

  // ──────────────────────────────────────────────
  // SHIFT DETAILS / CLOSE SHIFT
  // ──────────────────────────────────────────────

  void _showShiftDetails(WorkShift shift) {
    setState(() => _selectedShiftId = shift.id);
    showDialog(
      context: context,
      builder: (ctx) => _ShiftDetailsDialog(
        shift: shift,
        onClose: () {
          Navigator.of(ctx).pop();
          _closeShiftWithPumps(shift);
        },
        onDismiss: () {
          Navigator.of(ctx).pop();
          setState(() => _selectedShiftId = null);
        },
      ),
    ).then((_) => setState(() => _selectedShiftId = null));
  }

  Future<void> _closeShiftWithPumps(WorkShift shift) async {
    // Get all shift_pump records for this shift
    final spSnap = await firestore
        .collection('shift_pumps')
        .where('shiftId', isEqualTo: shift.id)
        .get();
    final shiftPumps = spSnap.docs
        .map((d) => ShiftPump.fromMap(d.data()..putIfAbsent('id', () => d.id)))
        .toList();

    // Get pump names
    final pumpsSnap = await firestore
        .collection('pumps')
        .where('isDeleted', isEqualTo: false)
        .get();
    final Map<String, String> pumpNames = {};
    for (final d in pumpsSnap.docs) {
      final data = d.data();
      pumpNames[d.id] = data['name'] as String? ?? d.id;
    }

    if (!mounted) return;
    final result = await showDialog<_CloseShiftResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CloseShiftDialog(
        shift: shift,
        shiftPumps: shiftPumps,
        pumpNames: pumpNames,
      ),
    );

    if (result == null || !mounted) return;

    try {
      // Update each ShiftPump with end analog counters
      double totalPumpRevenue = 0;
      final batch = firestore.batch();
      for (final entry in result.pumpEndCounters.entries) {
        final pumpId = entry.key;
        final endCounter = entry.value;
        final sp = shiftPumps.firstWhere((s) => s.pumpId == pumpId);
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
      final expectedCash = totalPumpRevenue + result.otherRevenue;
      await firestore.collection('work_shifts').doc(shift.id).update({
        'status': 'CLOSED',
        'endTime': Timestamp.now(),
        'actualCash': result.actualCash,
        'expectedCash': expectedCash,
      });

      if (mounted) {
        if (mounted) {
          final cs = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Shift closed. Expected: ${expectedCash.toStringAsFixed(2)} DA, Actual: ${result.actualCash.toStringAsFixed(2)} DA',
              ),
              backgroundColor: cs.primary,
            ),
          );
        }
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

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ──────────────────────────────────────────────
// SHIFT DETAILS DIALOG
// ──────────────────────────────────────────────

class _ShiftDetailsDialog extends StatelessWidget {
  final WorkShift shift;
  final VoidCallback onClose;
  final VoidCallback onDismiss;

  const _ShiftDetailsDialog({
    required this.shift,
    required this.onClose,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.schedule, color: cs.primary, size: 22),
          const SizedBox(width: 8),
          Text('Shift Details', style: TextStyle(color: cs.onSurface)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: cs.onSurface.withValues(alpha: 0.54), size: 20),
            onPressed: onDismiss,
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('shift_pumps')
              .where('shiftId', isEqualTo: shift.id)
              .snapshots(),
          builder: (context, spSnap) {
            final shiftPumps = spSnap.hasData
                ? spSnap.data!.docs
                      .map(
                        (d) =>
                            ShiftPump.fromMap(d.data() as Map<String, dynamic>),
                      )
                      .toList()
                : <ShiftPump>[];
            final totalRevenue = shiftPumps.fold<double>(
              0,
              (t, sp) => t + sp.revenue,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(cs, 'Worker ID', shift.workerId),
                _detailRow(cs, 'Status', shift.status.value),
                _detailRow(cs, 'Start', _formatDate(shift.startTime)),
                if (shift.status == ShiftStatus.closed) ...[
                  _detailRow(cs, 'End', _formatDate(shift.endTime)),
                  Divider(color: cs.onSurface.withValues(alpha: 0.12)),
                  _detailRow(cs,
                    'Pump Revenue',
                    '${totalRevenue.toStringAsFixed(2)} DA',
                  ),
                  _detailRow(cs,
                    'Expected Cash',
                    shift.expectedCash != null
                        ? '${shift.expectedCash!.toStringAsFixed(2)} DA'
                        : '--',
                  ),
                  _detailRow(cs,
                    'Actual Cash',
                    shift.actualCash != null
                        ? '${shift.actualCash!.toStringAsFixed(2)} DA'
                        : '--',
                  ),
                ],
                if (shiftPumps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Pump Counters',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...shiftPumps.map(
                    (sp) => _PumpCounterRow(
                      sp: sp,
                      pumpNameFuture: _getPumpName(sp.pumpId),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (shift.status == ShiftStatus.open)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.lock_clock, size: 18),
                      label: const Text('Close Shift'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String> _getPumpName(String pumpId) async {
    final doc = await firestore.collection('pumps').doc(pumpId).get();
    if (!doc.exists) return pumpId;
    return (doc.data()?['name'] as String? ?? pumpId);
  }

  Widget _detailRow(ColorScheme cs, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _PumpCounterRow extends StatelessWidget {
  final ShiftPump sp;
  final Future<String> pumpNameFuture;

  const _PumpCounterRow({required this.sp, required this.pumpNameFuture});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: pumpNameFuture,
      builder: (ctx, snap) {
        final name = snap.data ?? sp.pumpId;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 12),
                ),
              ),
              Text(
                'Start: ${sp.startAnalogCounter.toStringAsFixed(1)}',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                'End: ${sp.endAnalogCounter?.toStringAsFixed(1) ?? '--'}',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                'Vol: ${sp.volume.toStringAsFixed(1)}L',
                style: TextStyle(color: cs.secondary, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// CLOSE SHIFT DIALOG (Pump Counter Matrix)
// ──────────────────────────────────────────────

class _CloseShiftResult {
  final Map<String, double> pumpEndCounters;
  final double actualCash;
  final double otherRevenue;

  const _CloseShiftResult({
    required this.pumpEndCounters,
    required this.actualCash,
    required this.otherRevenue,
  });
}

class _CloseShiftDialog extends StatefulWidget {
  final WorkShift shift;
  final List<ShiftPump> shiftPumps;
  final Map<String, String> pumpNames;

  const _CloseShiftDialog({
    required this.shift,
    required this.shiftPumps,
    required this.pumpNames,
  });

  @override
  State<_CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<_CloseShiftDialog> {
  final Map<String, TextEditingController> _startControllers = {};
  final Map<String, TextEditingController> _endControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};
  final _dateController = TextEditingController();
  final _startCashController = TextEditingController(text: '0');
  final _endCashController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();
  String? _selectedOperator;
  bool _deductFromPits = true;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().substring(0, 16);

    for (final sp in widget.shiftPumps) {
      _startControllers[sp.pumpId] = TextEditingController(
        text: sp.startAnalogCounter.toStringAsFixed(1),
      );
      _endControllers[sp.pumpId] = TextEditingController(
        text: sp.endAnalogCounter?.toStringAsFixed(1) ?? '',
      );
      _priceControllers[sp.pumpId] = TextEditingController(
        text: (sp.priceAtShift ?? 0).toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _startControllers.values) {
      c.dispose();
    }
    for (final c in _endControllers.values) {
      c.dispose();
    }
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    _dateController.dispose();
    _startCashController.dispose();
    _endCashController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  Widget _buildNumberField(
    TextEditingController controller,
    void Function(double value) onChanged,
  ) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 90,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: cs.onSurface, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cs.primary),
          ),
        ),
        onChanged: (v) {
          onChanged(double.tryParse(v) ?? 0);
          setState(() {});
        },
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, double> endCounters = {};
    for (final sp in widget.shiftPumps) {
      final value = double.tryParse(_endControllers[sp.pumpId]?.text ?? '');
      if (value != null) {
        endCounters[sp.pumpId] = value;
      }
    }

    final actualCash = double.tryParse(_endCashController.text) ?? 0;
    final otherRevenue = double.tryParse(_otherController.text) ?? 0;

    Navigator.of(context).pop(
      _CloseShiftResult(
        pumpEndCounters: endCounters,
        actualCash: actualCash,
        otherRevenue: otherRevenue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    double totalVolume = 0;
    double totalExpected = 0;
    final pumpRevenueMap = <String, double>{};

    for (final sp in widget.shiftPumps) {
      final startVal =
          double.tryParse(_startControllers[sp.pumpId]?.text ?? '') ??
          sp.startAnalogCounter;
      final endVal = double.tryParse(_endControllers[sp.pumpId]?.text ?? '');
      final price =
          double.tryParse(_priceControllers[sp.pumpId]?.text ?? '') ??
          (sp.priceAtShift ?? 0);

      final computedVol = endVal != null && endVal >= startVal
          ? endVal - startVal
          : 0;
      final computedRev = computedVol * price;

      totalVolume += computedVol;
      totalExpected += computedRev;
      pumpRevenueMap[sp.pumpId] = computedRev;
    }

    final otherRev = double.tryParse(_otherController.text) ?? 0;
    totalExpected += otherRev;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: cs.surface,
      child: SizedBox(
        width: 1100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.input, color: cs.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'SHIFT DATA IMPORT',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dateController,
                              style: TextStyle(color: cs.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Date',
                                labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedOperator,
                              style: TextStyle(color: cs.onSurface),
                              dropdownColor: cs.surfaceContainerHighest,
                              decoration: InputDecoration(
                                labelText: 'Operator',
                                labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'operator1',
                                  child: Text('Operator 1'),
                                ),
                                DropdownMenuItem(
                                  value: 'operator2',
                                  child: Text('Operator 2'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedOperator = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startCashController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(color: cs.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Start Cash',
                                labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endCashController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(color: cs.onSurface),
                              decoration: InputDecoration(
                                labelText: 'End Cash',
                                labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Checkbox(
                            value: _deductFromPits,
                            onChanged: (v) =>
                                setState(() => _deductFromPits = v ?? true),
                            activeColor: cs.secondary,
                          ),
                          Text(
                            'Deduct From Pits',
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 42,
                          columns: [
                            DataColumn(
                              label: Text(
                                '#',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Pump',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Start Index',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'End Index',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Volume',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Price',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Amount',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                            ),
                          ],
                          rows: List.generate(widget.shiftPumps.length, (
                            index,
                          ) {
                            final sp = widget.shiftPumps[index];
                            final name =
                                widget.pumpNames[sp.pumpId] ?? sp.pumpId;
                            final startController =
                                _startControllers[sp.pumpId]!;
                            final endController = _endControllers[sp.pumpId]!;
                            final priceController =
                                _priceControllers[sp.pumpId]!;

                            final startVal =
                                double.tryParse(startController.text) ??
                                sp.startAnalogCounter;
                            final endVal = double.tryParse(endController.text);
                            final price =
                                double.tryParse(priceController.text) ??
                                (sp.priceAtShift ?? 0);
                            final volume = endVal != null && endVal >= startVal
                                ? endVal - startVal
                                : 0;
                            final amount = volume * price;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    (index + 1).toString(),
                                    style: TextStyle(color: cs.onSurface),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    name,
                                    style: TextStyle(color: cs.onSurface),
                                  ),
                                ),
                                DataCell(
                                  _buildNumberField(
                                    startController,
                                    (v) => startController.text = v
                                        .toStringAsFixed(1),
                                  ),
                                ),
                                DataCell(
                                  _buildNumberField(
                                    endController,
                                    (v) => endController.text = v
                                        .toStringAsFixed(1),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    volume.toStringAsFixed(2),
                                    style: TextStyle(color: cs.onSurface),
                                  ),
                                ),
                                DataCell(
                                  _buildNumberField(
                                    priceController,
                                    (v) => priceController.text = v
                                        .toStringAsFixed(2),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    amount.toStringAsFixed(2),
                                    style: TextStyle(color: cs.onSurface),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TOTAL VOLUME',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.54),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              totalVolume.toStringAsFixed(2),
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TOTAL REVENUE',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.54),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              totalExpected.toStringAsFixed(2),
                              style: TextStyle(
                                color: cs.secondary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text('SAVE SHIFT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onSurface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerNameCell extends StatelessWidget {
  final String workerId;
  const _WorkerNameCell({required this.workerId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<DocumentSnapshot>(
      future: firestore.collection('users').doc(workerId).get(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return SizedBox(
            width: 120,
            child: LinearProgressIndicator(value: 0.5),
          );
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        final name = data?['fullName'] ?? workerId;
        return Text(
          name,
          style: TextStyle(color: cs.onSurface),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
