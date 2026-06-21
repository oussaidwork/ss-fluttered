import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../widgets/pump_dialog.dart';
import '../widgets/pump_card_view.dart';
import '../widgets/pump_list_view.dart';

/// Dispensing Pumps management with view mode toggle, group filter,
/// search bar, and card-based layout.
class PumpsPage extends StatefulWidget {
  const PumpsPage({super.key});

  @override
  State<PumpsPage> createState() => _PumpsPageState();
}

class _PumpsPageState extends State<PumpsPage> {
  String _searchQuery = '';
  String _selectedGroup = 'All';
  bool _cardView = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        onPressed: () => showPumpDialog(context),
        child: Icon(Icons.add, color: cs.onSurface),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('pumps')
            .where('isDeleted', isEqualTo: false)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child:
                  CircularProgressIndicator(color: cs.primary),
            );
          }
          final pumpDocs = snap.data?.docs ?? [];
          if (pumpDocs.isEmpty) {
            return _buildEmpty();
          }
          return StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('pits')
                .where('isDeleted', isEqualTo: false)
                .snapshots(),
            builder: (ctx, pitSnap) {
              final pitDocs = pitSnap.data?.docs ?? [];
              final pitMap = <String, Map<String, dynamic>>{};
              for (final d in pitDocs) {
                pitMap[d.id] = d.data() as Map<String, dynamic>;
              }

              final groups = <String>{'All'};
              for (final doc in pumpDocs) {
                final d = doc.data() as Map<String, dynamic>;
                final g = d['groupId'] as String? ?? '';
                if (g.isNotEmpty) groups.add(g);
              }

              var filtered = pumpDocs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final name =
                    (d['name'] as String?)?.toLowerCase() ?? '';
                final group = d['groupId'] as String? ?? '';
                if (_selectedGroup != 'All' &&
                    group != _selectedGroup) {
                  return false;
                }
                if (_searchQuery.isNotEmpty &&
                    !name.contains(_searchQuery.toLowerCase())) {
                  return false;
                }
                return true;
              }).toList();

              return Column(
                children: [
                  _buildToolbar(groups),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filtered.length} pump${filtered.length != 1 ? 's' : ''}',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _cardView
                        ? PumpCardView(docs: filtered, pitMap: pitMap)
                        : PumpListView(docs: filtered, pitMap: pitMap),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildHeaderRow(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed,
                    size: 64, color: cs.primary),
                const SizedBox(height: 16),
                Text('No pumps',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.54), fontSize: 18)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Icon(Icons.speed,
              color: cs.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'Dispensing Pumps',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => showPumpDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Pump'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(Set<String> groups) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Icon(Icons.speed,
              color: cs.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'Dispensing Pumps',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 220,
            child: TextField(
              onChanged: (v) =>
                  setState(() => _searchQuery = v),
              style: TextStyle(
                  color: cs.onSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search pumps...',
                hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12),
                prefixIcon: Icon(Icons.search,
                    color: cs.onSurface.withValues(alpha: 0.38), size: 18),
                filled: true,
                fillColor:
                    cs.onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedGroup,
              dropdownColor: cs.surfaceContainerHighest,
              underline: const SizedBox(),
              isDense: true,
              style: TextStyle(
                  color: cs.onSurface, fontSize: 12),
              items: groups
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g,
                            style:
                                TextStyle(fontSize: 12)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedGroup = v ?? 'All'),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => showPumpDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Pump'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onSurface,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              _cardView ? Icons.view_list : Icons.grid_view,
              color: cs.onSurface.withValues(alpha: 0.54),
              size: 20,
            ),
            onPressed: () =>
                setState(() => _cardView = !_cardView),
            tooltip: _cardView
                ? 'Switch to list'
                : 'Switch to cards',
          ),
        ],
      ),
    );
  }
}
