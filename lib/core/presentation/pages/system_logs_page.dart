import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/log_entry.dart';

class SystemLogsPage extends StatefulWidget {
  const SystemLogsPage({super.key});

  @override
  State<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends State<SystemLogsPage> {
  String? _actionFilter;
  DateTimeRange? _dateRange;
  static const _actionTypes = [
    'CREATE',
    'UPDATE',
    'DELETE',
    'LOGIN',
    'LOGOUT',
    'SALE',
    'PAYMENT',
    'SHIFT_OPEN',
    'SHIFT_CLOSE',
    'SETTINGS_CHANGE',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text(
                'System Audit Logs',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              _buildFilters(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('log_entries')
                  .orderBy('timestamp', descending: true)
                  .limit(500)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }
                final logs = snapshot.data!.docs
                    .map((doc) => LogEntry.fromMap(doc.data() as Map<String, dynamic>))
                    .where((l) => _matchesFilter(l))
                    .toList();
                if (logs.isEmpty) return _buildEmptyState();
                return _buildLogsTable(logs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2332),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _actionFilter,
              dropdownColor: const Color(0xFF1A2332),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.filter_list, color: Colors.white54, size: 20),
              hint: const Text('All Actions', style: TextStyle(color: Colors.white54)),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All Actions')),
                ..._actionTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))),
              ],
              onChanged: (val) => setState(() => _actionFilter = val),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF0066CC),
                      surface: Color(0xFF1A2332),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            setState(() => _dateRange = picked);
          },
          icon: Icon(
            Icons.date_range,
            color: _dateRange != null ? const Color(0xFF0066CC) : Colors.white54,
          ),
          tooltip: _dateRange != null
              ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
              : 'Date range filter',
        ),
        if (_dateRange != null)
          IconButton(
            onPressed: () => setState(() => _dateRange = null),
            icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
            tooltip: 'Clear date filter',
          ),
      ],
    );
  }

  bool _matchesFilter(LogEntry log) {
    if (_actionFilter != null && log.action != _actionFilter) return false;
    if (_dateRange != null) {
      final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
      final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
      if (logDate.isBefore(start) || logDate.isAfter(end)) return false;
    }
    return true;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _actionFilter != null || _dateRange != null ? Icons.filter_list_off : Icons.list_alt,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            _actionFilter != null || _dateRange != null
                ? 'No logs match the current filters'
                : 'No audit logs yet',
            style: const TextStyle(fontSize: 18, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTable(List<LogEntry> logs) {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.05)),
            columns: const [
              DataColumn(label: Text('Timestamp', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Action', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Details', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('User', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))),
            ],
            rows: logs.map((log) {
              return DataRow(
                cells: [
                  DataCell(Text(
                    _formatDateTime(log.timestamp),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  )),
                  DataCell(_buildActionBadge(log.action)),
                  DataCell(
                    SizedBox(
                      width: 300,
                      child: Text(
                        log.details ?? '--',
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  DataCell(Text(
                    log.userId ?? '--',
                    style: const TextStyle(color: Colors.white70),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBadge(String action) {
    Color color;
    switch (action) {
      case 'CREATE':
        color = const Color(0xFF84CC16);
        break;
      case 'UPDATE':
        color = const Color(0xFF0066CC);
        break;
      case 'DELETE':
        color = const Color(0xFFEF4444);
        break;
      case 'LOGIN':
      case 'LOGOUT':
        color = const Color(0xFF8B5CF6);
        break;
      case 'SALE':
        color = const Color(0xFF06B6D4);
        break;
      case 'PAYMENT':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = Colors.white54;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        action,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
