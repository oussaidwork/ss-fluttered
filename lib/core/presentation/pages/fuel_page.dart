import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/firestore/firestore_provider.dart';

/// Fuel / Gas Types management page with Price History chart + QuickPriceModal.
class FuelPage extends StatefulWidget {
  const FuelPage({super.key});

  @override
  State<FuelPage> createState() => _FuelPageState();
}

class _FuelPageState extends State<FuelPage> {
  // ─── Gas Type CRUD ────────────────────────────────────────────
  void _showGasTypeDialog({Map<String, dynamic>? gasType, String? docId}) {
    final nameCtrl = TextEditingController(text: gasType?['name'] ?? '');
    final priceInCtrl =
        TextEditingController(text: gasType?['priceIn']?.toString() ?? '');
    final priceOutCtrl =
        TextEditingController(text: gasType?['priceOut']?.toString() ?? '');
    String selectedColor = gasType?['color'] ?? 'blue';
    final colorOptions = ['red', 'blue', 'green', 'yellow', 'white'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            backgroundColor: cs.surfaceContainerHighest,
            title: Text(docId == null ? 'Add Fuel Type' : 'Edit Fuel Type',
                style: TextStyle(color: cs.onSurface)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceInCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  ],
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                      labelText: 'Price In (MAD/L)',
                      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceOutCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  ],
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                      labelText: 'Price Out (MAD/L)',
                      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)))),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  dropdownColor: cs.surfaceContainerHighest,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                      labelText: 'Color',
                      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
                  items: colorOptions
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedColor = v ?? 'blue'),
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final priceIn = double.tryParse(priceInCtrl.text) ?? 0;
                  final priceOut = double.tryParse(priceOutCtrl.text) ?? 0;
                  if (name.isEmpty) return;
                  final now = Timestamp.now();
                  final data = {
                    'name': name,
                    'priceIn': priceIn,
                    'priceOut': priceOut,
                    'color': selectedColor,
                    'isDeleted': false,
                    'createdAt': gasType?['createdAt'] ?? now,
                    'updatedAt': now,
                  };
                  if (docId == null) {
                    final id = firestore.collection('gas_types').doc().id;
                    await firestore
                        .collection('gas_types')
                        .doc(id)
                        .set({...data, 'id': id});
                  } else {
                    await firestore
                        .collection('gas_types')
                        .doc(docId)
                        .update(data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(docId == null ? 'Add' : 'Save',
                    style: TextStyle(color: cs.onSurface)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Quick Price Modal ────────────────────────────────────────
  void _showQuickPriceModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.bolt, color: cs.tertiary, size: 22),
            const SizedBox(width: 8),
            Text('Quick Price Update',
                style: TextStyle(color: cs.onSurface, fontSize: 18)),
          ]),
          content: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('gas_types')
                .where('isDeleted', isEqualTo: false)
                .snapshots(),
            builder: (ctx, snap) {
              final cs = Theme.of(ctx).colorScheme;
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Text('No fuel types available',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)));
              }
              return SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final priceOutCtrl = TextEditingController(
                            text: d['priceOut']?.toString() ?? '');
                        return Card(
                          color: cs.surface,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: _parseColor(cs, d['color'] ?? 'blue'),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(d['name'] ?? '',
                                    style: TextStyle(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: priceOutCtrl,
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'))
                                  ],
                                  style:
                                      TextStyle(color: cs.onSurface),
                                  decoration: InputDecoration(
                                    labelText: 'Price Out',
                                    labelStyle: TextStyle(
                                        color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                          color: cs.onSurface.withValues(alpha: 0.24)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.check,
                                    size: 18,
                                    color: cs.secondary),
                                onPressed: () async {
                                  final newPrice =
                                      double.tryParse(priceOutCtrl.text);
                                  if (newPrice == null) return;
                                  final cs = Theme.of(ctx).colorScheme;
                                  await firestore
                                      .collection('gas_types')
                                      .doc(doc.id)
                                      .update({
                                    'priceOut': newPrice,
                                    'updatedAt': Timestamp.now(),
                                  });
                                  final historyRef = firestore
                                      .collection('fuelPriceHistory')
                                      .doc();
                                  await historyRef.set({
                                    'id': historyRef.id,
                                    'gasTypeId': doc.id,
                                    'oldPrice':
                                        (d['priceOut'] as num?)?.toDouble() ?? 0,
                                    'newPrice': newPrice,
                                    'changedAt': Timestamp.now(),
                                    'isDeleted': false,
                                  });
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              '${d['name']} updated to $newPrice DA'),
                                          backgroundColor:
                                              cs.secondary),
                                    );
                                  }
                                },
                              ),
                            ]),
                          ),
                        );
                      }).toList()),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Done',
                  style: TextStyle(color: cs.primary)),
            ),
          ],
        );
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        onPressed: () => _showGasTypeDialog(),
        child: Icon(Icons.add, color: cs.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Icon(Icons.water_drop,
                  color: cs.primary, size: 28),
              const SizedBox(width: 12),
              Text('Fuel Management',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showQuickPriceModal,
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('Quick Price Update'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: cs.tertiary,
                    foregroundColor: cs.onSurface,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
              ),
            ]),
            const SizedBox(height: 24),
            // ── Fuel Types ──
            _buildCard(cs, 'Fuel Types', Icons.list, _buildGasTypesTable(cs)),
            const SizedBox(height: 16),
            // ── Price History ──
            _buildCard(cs, 'Price History', Icons.trending_up, _buildPriceHistory(cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ColorScheme cs, String title, IconData icon, Widget child) {
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Icon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: child,
          ),
        ],
      ),
    );
  }

  // ─── Gas Types Table ──────────────────────────────────────────
  Widget _buildGasTypesTable(ColorScheme cs) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('gas_types')
          .where('isDeleted', isEqualTo: false)
          .snapshots(),
      builder: (ctx, snap) {
        final cs = Theme.of(ctx).colorScheme;
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: cs.primary));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
                child: Text('No fuel types',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)))),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(
                  label: Text('Name',
                      style: TextStyle(color: cs.onSurface))),
              DataColumn(
                  label: Text('Price In (MAD/L)',
                      style: TextStyle(color: cs.onSurface))),
              DataColumn(
                  label: Text('Price Out (MAD/L)',
                      style: TextStyle(color: cs.onSurface))),
              DataColumn(
                  label: Text('Margin',
                      style: TextStyle(color: cs.onSurface))),
              DataColumn(
                  label: Text('Color',
                      style: TextStyle(color: cs.onSurface))),
              DataColumn(
                  label: Text('Actions',
                      style: TextStyle(color: cs.onSurface))),
            ],
            rows: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final name = d['name'] ?? '';
              final priceIn = (d['priceIn'] as num?)?.toDouble() ?? 0;
              final priceOut = (d['priceOut'] as num?)?.toDouble() ?? 0;
              final margin = priceOut - priceIn;
              final colorName = d['color'] ?? 'blue';
              final chipColor = _parseColor(cs, colorName);
              return DataRow(cells: [
                DataCell(Text(name,
                    style: TextStyle(color: cs.onSurface))),
                DataCell(Text(priceIn.toStringAsFixed(2),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)))),
                DataCell(Text(priceOut.toStringAsFixed(2),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)))),
                DataCell(Text(margin.toStringAsFixed(2),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)))),
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(colorName,
                      style:
                          TextStyle(color: cs.onSurface, fontSize: 12)),
                )),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(Icons.edit,
                        size: 18, color: cs.primary),
                    onPressed: () =>
                        _showGasTypeDialog(gasType: d, docId: id),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete,
                        size: 18, color: cs.error),
                    onPressed: () async {
                      await firestore
                          .collection('gas_types')
                          .doc(id)
                          .update({'isDeleted': true});
                    },
                  ),
                ])),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  // ─── Price History ────────────────────────────────────────────
  String _priceFilter = 'ALL';
  final Set<String> _selectedGasTypes = {};

  Widget _buildPriceHistory(ColorScheme cs) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('fuelPriceHistory')
          .where('isDeleted', isEqualTo: false)
          .orderBy('changedAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        final cs = Theme.of(ctx).colorScheme;
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: cs.primary));
        }
        final docs = snap.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                // Date range chips
                ...['ALL', 'TODAY', 'WEEK', 'MONTH'].map((f) {
                  final isSelected = _priceFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(f,
                          style: TextStyle(
                              color: isSelected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.54),
                              fontSize: 11)),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _priceFilter = f),
                      selectedColor: cs.primary,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.05),
                      checkmarkColor: cs.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
                const Spacer(),
                Text('${docs.length} changes',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 8),
            // Chart
            if (docs.isNotEmpty)
              SizedBox(
                height: 180,
                child: _buildPriceChart(docs, cs),
              ),
            const SizedBox(height: 12),
            // Table
            if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: Text('No price history yet',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)))),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: [
                    DataColumn(
                        label: Text('Date',
                            style: TextStyle(color: cs.onSurface))),
                    DataColumn(
                        label: Text('Fuel Type',
                            style: TextStyle(color: cs.onSurface))),
                    DataColumn(
                        label: Text('Old Price',
                            style: TextStyle(color: cs.onSurface))),
                    DataColumn(
                        label: Text('New Price',
                            style: TextStyle(color: cs.onSurface))),
                    DataColumn(
                        label: Text('Change',
                            style: TextStyle(color: cs.onSurface))),
                  ],
                  rows: docs.take(50).map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final date =
                        (d['changedAt'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                    final oldPrice =
                        (d['oldPrice'] as num?)?.toDouble() ?? 0;
                    final newPrice =
                        (d['newPrice'] as num?)?.toDouble() ?? 0;
                    final change = newPrice - oldPrice;
                    return DataRow(cells: [
                      DataCell(Text(
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              color: cs.onSurface, fontSize: 11))),
                      DataCell(Text(d['gasTypeId'] ?? '',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.54), fontSize: 11))),
                      DataCell(Text(oldPrice.toStringAsFixed(2),
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.54), fontSize: 11))),
                      DataCell(Text(newPrice.toStringAsFixed(2),
                          style: TextStyle(
                              color: cs.onSurface, fontSize: 11))),
                      DataCell(Text(
                          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: change >= 0
                                  ? cs.secondary
                                  : cs.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600))),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPriceChart(List<QueryDocumentSnapshot> docs, ColorScheme cs) {
    // Build simple line chart from price history
    final spots = <String, List<FlSpot>>{};
    final sorted = List.from(docs);
    sorted.sort((a, b) {
      final ta = (a.data() as Map<String, dynamic>)['changedAt'] as Timestamp?;
      final tb = (b.data() as Map<String, dynamic>)['changedAt'] as Timestamp?;
      return (ta?.toDate().millisecondsSinceEpoch ?? 0)
          .compareTo(tb?.toDate().millisecondsSinceEpoch ?? 0);
    });

    int x = 0;
    for (final doc in sorted) {
      final d = doc.data() as Map<String, dynamic>;
      final gasTypeId = d['gasTypeId'] as String? ?? 'unknown';
      final newPrice = (d['newPrice'] as num?)?.toDouble() ?? 0;
      spots.putIfAbsent(gasTypeId, () => []);
      spots[gasTypeId]!.add(FlSpot(x.toDouble(), newPrice));
      x++;
    }

    final colors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.error,
      cs.secondaryContainer,
    ];

    return Card(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: cs.onSurface.withValues(alpha: 0.05),
                strokeWidth: 1,
              ),
            ),
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: spots.entries.toList().asMap().entries.map((entry) {
              final color = colors[entry.key % colors.length];
              return LineChartBarData(
                spots: entry.value.value,
                isCurved: true,
                color: color,
                barWidth: 2,
                dotData: FlDotData(
                  show: entry.value.value.length < 30,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.1),
                ),
              );
            }).toList(),
            minY: 0,
          ),
        ),
      ),
    );
  }

  Color _parseColor(ColorScheme cs, String name) {
    switch (name) {
      case 'red':
        return cs.error;
      case 'green':
        return cs.secondary;
      case 'yellow':
        return cs.tertiary;
      case 'white':
        return cs.onSurface;
      default:
        return cs.primary;
    }
  }
}
