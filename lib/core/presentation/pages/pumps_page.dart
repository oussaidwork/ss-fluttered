import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

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

  static const _colorMap = {
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Color(0xFF84CC16),
    'yellow': Colors.yellow,
    'white': Colors.white,
  };

  // ─── Add/Edit Dialog ──────────────────────────────────────────
  void _showDialog({Map<String, dynamic>? pump, String? docId}) {
    final nameCtrl = TextEditingController(text: pump?['name'] ?? '');
    final counterCtrl = TextEditingController(
      text: pump?['initialAnalogCounter']?.toString() ?? '',
    );
    String? selectedGroupId = pump?['groupId'] ?? 'Block A';
    String? selectedPitId = pump?['pitId'];
    bool isActive = pump?['isActive'] ?? true;
    String selectedColor = pump?['color'] ?? 'red';

    final blockOptions = ['Block A', 'Block B', 'Block C', 'Block D'];
    final colorOptions = ['red', 'blue', 'green', 'yellow', 'white'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: Text(
            docId == null ? 'Add Pump' : 'Edit Pump',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGroupId,
                  dropdownColor: const Color(0xFF1A2332),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Block (Group)',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                  items: blockOptions
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedGroupId = v),
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('pits')
                      .where('isDeleted', isEqualTo: false)
                      .snapshots(),
                  builder: (ctx, snap) {
                    final docs = snap.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      value: selectedPitId,
                      dropdownColor: const Color(0xFF1A2332),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Pit',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                      items: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: d.id,
                          child: Text(data['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => selectedPitId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: counterCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Initial Counter',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  title: const Text(
                    'Active',
                    style: TextStyle(color: Colors.white),
                  ),
                  activeColor: const Color(0xFF84CC16),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  dropdownColor: const Color(0xFF1A2332),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                  items: colorOptions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedColor = v ?? 'red'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final counter = double.tryParse(counterCtrl.text) ?? 0;
                if (name.isEmpty || selectedPitId == null) return;
                final data = {
                  'name': name,
                  'groupId': selectedGroupId,
                  'pitId': selectedPitId,
                  'initialAnalogCounter': counter,
                  'isActive': isActive,
                  'color': selectedColor,
                  'isDeleted': false,
                };
                if (docId == null) {
                  final id = firestore.collection('pumps').doc().id;
                  await firestore.collection('pumps').doc(id).set({
                    ...data,
                    'id': id,
                  });
                } else {
                  await firestore.collection('pumps').doc(docId).update(data);
                }
                //if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(
                docId == null ? 'Add' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0066CC),
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('pumps')
            .where('isDeleted', isEqualTo: false)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066CC)),
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
              final gasTypeMap = <String, String>{};
              // We'll map pit -> gasTypeId -> color from the pit data
              // For now, just use the pit color directly

              // Build groups set
              final groups = <String>{'All'};
              for (final doc in pumpDocs) {
                final d = doc.data() as Map<String, dynamic>;
                final g = d['groupId'] as String? ?? '';
                if (g.isNotEmpty) groups.add(g);
              }
              groups.add('All');

              // Filter by group and search
              var filtered = pumpDocs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final name = (d['name'] as String?)?.toLowerCase() ?? '';
                final group = d['groupId'] as String? ?? '';
                if (_selectedGroup != 'All' && group != _selectedGroup) {
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
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.speed,
                          color: Color(0xFF0066CC),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Dispensing Pumps',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Search
                        SizedBox(
                          width: 220,
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search pumps...',
                              hintStyle: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white38,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Group filter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedGroup,
                            dropdownColor: const Color(0xFF1A2332),
                            underline: const SizedBox(),
                            isDense: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            items: groups
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      g,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedGroup = v ?? 'All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add pump button
                        ElevatedButton.icon(
                          onPressed: () => _showDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Pump'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066CC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // View toggle
                        IconButton(
                          icon: Icon(
                            _cardView ? Icons.view_list : Icons.grid_view,
                            color: Colors.white54,
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
                  ),
                  // ── Count ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filtered.length} pump${filtered.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Content ──
                  Expanded(
                    child: _cardView
                        ? _buildCardView(filtered, pitMap)
                        : _buildListView(filtered, pitMap),
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
    return Column(
      children: [
        _buildHeaderRow(),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, size: 64, color: Color(0xFF0066CC)),
                SizedBox(height: 16),
                Text(
                  'No pumps',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Icon(Icons.speed, color: Color(0xFF0066CC), size: 28),
          const SizedBox(width: 12),
          const Text(
            'Dispensing Pumps',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Pump'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card View ─────────────────────────────────────────────────
  Widget _buildCardView(
    List<QueryDocumentSnapshot> docs,
    Map<String, Map<String, dynamic>> pitMap,
  ) {
    // Group by groupId
    final grouped = <String, List<QueryDocumentSnapshot>>{};
    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final g = d['groupId'] as String? ?? 'Ungrouped';
      grouped.putIfAbsent(g, () => []).add(doc);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (ctx, idx) {
        final group = grouped.keys.elementAt(idx);
        final pumps = grouped[group]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      group,
                      style: const TextStyle(
                        color: Color(0xFF0066CC),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pumps.length} pump${pumps.length != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: pumps
                  .map((doc) => _buildPumpCard(doc, pitMap))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPumpCard(
    QueryDocumentSnapshot doc,
    Map<String, Map<String, dynamic>> pitMap,
  ) {
    final d = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    final name = d['name'] ?? '';
    final counter = (d['initialAnalogCounter'] as num?)?.toDouble() ?? 0;
    final active = d['isActive'] ?? false;
    final colorName = d['color'] ?? 'red';
    final pitId = d['pitId'] as String? ?? '';
    final pit = pitMap[pitId];
    final pitName = pit?['name'] ?? '-';
    final chipColor = _colorMap[colorName] ?? Colors.blue;

    return SizedBox(
      width: 260,
      child: Card(
        color: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Color swatch
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: chipColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  // Active badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF84CC16).withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      active ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: active ? const Color(0xFF84CC16) : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('Pit', pitName),
              _infoRow('Counter', counter.toStringAsFixed(1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDialog(pump: d, docId: id),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0066CC),
                        side: const BorderSide(color: Color(0xFF0066CC)),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await firestore.collection('pumps').doc(id).update({
                          'isDeleted': true,
                        });
                      },
                      icon: const Icon(Icons.delete, size: 14),
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── List View (DataTable) ────────────────────────────────────
  Widget _buildListView(
    List<QueryDocumentSnapshot> docs,
    Map<String, Map<String, dynamic>> pitMap,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text('Name', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('Block', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('Pit', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('Counter', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('Active', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('Actions', style: TextStyle(color: Colors.white)),
            ),
          ],
          rows: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            final name = d['name'] ?? '';
            final groupId = d['groupId'] ?? '';
            final pitId = d['pitId'] ?? '';
            final counter =
                (d['initialAnalogCounter'] as num?)?.toDouble() ?? 0;
            final active = d['isActive'] ?? false;
            final pitName = pitMap[pitId]?['name'] ?? '-';
            return DataRow(
              cells: [
                DataCell(
                  Text(name, style: const TextStyle(color: Colors.white)),
                ),
                DataCell(
                  Text(groupId, style: const TextStyle(color: Colors.white54)),
                ),
                DataCell(
                  Text(pitName, style: const TextStyle(color: Colors.white54)),
                ),
                DataCell(
                  Text(
                    counter.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                DataCell(
                  Icon(
                    active ? Icons.check_circle : Icons.cancel,
                    color: active ? const Color(0xFF84CC16) : Colors.red,
                    size: 20,
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Color(0xFF0066CC),
                        ),
                        onPressed: () => _showDialog(pump: d, docId: id),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          await firestore.collection('pumps').doc(id).update({
                            'isDeleted': true,
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
