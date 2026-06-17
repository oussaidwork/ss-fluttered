import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/work_shift.dart';
import '../../../domain/enums/shift_status.dart';

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  ShiftStatus? _statusFilter;
  String? _selectedShiftId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Shift Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _buildStatusFilter(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('work_shifts')
                  .orderBy('startTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0066CC)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }
                final shifts = snapshot.data!.docs
                    .map((doc) => WorkShift.fromMap(doc.data() as Map<String, dynamic>))
                    .where((s) => _statusFilter == null || s.status == _statusFilter)
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

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ShiftStatus?>(
          value: _statusFilter,
          dropdownColor: const Color(0xFF1A2332),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.filter_list, color: Colors.white54, size: 20),
          hint: const Text('All Status', style: TextStyle(color: Colors.white54)),
          items: [
            const DropdownMenuItem<ShiftStatus?>(
              value: null,
              child: Text('All Status'),
            ),
            ...ShiftStatus.values.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.value),
                )),
          ],
          onChanged: (val) => setState(() => _statusFilter = val),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusFilter != null ? Icons.filter_list_off : Icons.schedule,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            _statusFilter != null ? 'No shifts with this status' : 'No shifts yet',
            style: const TextStyle(fontSize: 18, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTable(List<WorkShift> shifts) {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
            columns: const [
              DataColumn(label: Text('Worker', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Start Time', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('End Time', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Actual Cash', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            ],
            rows: shifts.map((shift) {
              final isSelected = _selectedShiftId == shift.id;
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) => _showShiftDetails(shift),
                cells: [
                  DataCell(_WorkerNameCell(workerId: shift.workerId)),
                  DataCell(Text(
                    _formatDate(shift.startTime),
                    style: const TextStyle(color: Colors.white),
                  )),
                  DataCell(Text(
                    shift.status == ShiftStatus.open ? '--' : _formatDate(shift.endTime),
                    style: const TextStyle(color: Colors.white),
                  )),
                  DataCell(_buildStatusBadge(shift.status)),
                  DataCell(Text(
                    shift.actualCash != null ? '${shift.actualCash!.toStringAsFixed(2)} DA' : '--',
                    style: TextStyle(
                      color: shift.actualCash != null ? Colors.white : Colors.white38,
                    ),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ShiftStatus status) {
    final isOpen = status == ShiftStatus.open;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isOpen ? const Color(0xFF84CC16) : const Color(0xFF0066CC)).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOpen ? const Color(0xFF84CC16) : const Color(0xFF0066CC)).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          color: isOpen ? const Color(0xFF84CC16) : const Color(0xFF0066CC),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showShiftDetails(WorkShift shift) {
    setState(() => _selectedShiftId = shift.id);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.schedule, color: Color(0xFF0066CC), size: 22),
            const SizedBox(width: 8),
            const Text('Shift Details', style: TextStyle(color: Colors.white)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Shift ID', shift.id),
              _detailRow('Worker ID', shift.workerId),
              _detailRow('Status', shift.status.value),
              _detailRow('Start Time', _formatDate(shift.startTime)),
              _detailRow('End Time', shift.status == ShiftStatus.open ? 'In Progress' : _formatDate(shift.endTime)),
              _detailRow('Actual Cash', shift.actualCash != null ? '${shift.actualCash!.toStringAsFixed(2)} DA' : 'Not set'),
              const SizedBox(height: 16),
              if (shift.status == ShiftStatus.open)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _closeShift(ctx, shift),
                    icon: const Icon(Icons.lock_clock, size: 18),
                    label: const Text('Close Shift'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).then((_) => setState(() => _selectedShiftId = null));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _closeShift(BuildContext ctx, WorkShift shift) async {
    final cashController = TextEditingController();
    final result = await showDialog<double?>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Close Shift', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: cashController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Actual Cash Amount',
            labelStyle: const TextStyle(color: Colors.white54),
            prefixText: 'DA ',
            prefixStyle: const TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0066CC)),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final cash = double.tryParse(cashController.text);
              Navigator.of(dCtx).pop(cash);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066CC)),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && ctx.mounted) {
      await firestore.collection('work_shifts').doc(shift.id).update({
        'status': ShiftStatus.closed.value,
        'endTime': Timestamp.now(),
        'actualCash': result,
      });
      if (ctx.mounted) Navigator.of(ctx).pop();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _WorkerNameCell extends StatelessWidget {
  final String workerId;
  const _WorkerNameCell({required this.workerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: firestore.collection('users').doc(workerId).get(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            width: 120,
            child: LinearProgressIndicator(value: 0.5),
          );
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        final name = data?['fullName'] ?? workerId;
        return Text(
          name,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
