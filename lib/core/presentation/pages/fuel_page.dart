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
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: Text(docId == null ? 'Add Fuel Type' : 'Edit Fuel Type',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceInCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Price In (MAD/L)',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceOutCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Price Out (MAD/L)',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedColor,
                dropdownColor: const Color(0xFF1A2332),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Color',
                    labelStyle: TextStyle(color: Colors.white54)),
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
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC)),
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
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick Price Modal ────────────────────────────────────────
  void _showQuickPriceModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 22),
          SizedBox(width: 8),
          Text('Quick Price Update',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('gas_types')
              .where('isDeleted', isEqualTo: false)
              .snapshots(),
          builder: (ctx, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('No fuel types available',
                  style: TextStyle(color: Colors.white54));
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
                        color: const Color(0xFF0B1220),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: _parseColor(d['color'] ?? 'blue'),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(d['name'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
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
                                    const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Price Out',
                                  labelStyle: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                        color: Colors.white24),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.check,
                                  size: 18,
                                  color: Color(0xFF84CC16)),
                              onPressed: () async {
                                final newPrice =
                                    double.tryParse(priceOutCtrl.text);
                                if (newPrice == null) return;
                                // Update gas type
                                await firestore
                                    .collection('gas_types')
                                    .doc(doc.id)
                                    .update({
                                  'priceOut': newPrice,
                                  'updatedAt': Timestamp.now(),
                                });
                                // Log price history
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
                                            const Color(0xFF84CC16)),
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
            child: const Text('Done',
                style: TextStyle(color: Color(0xFF0066CC))),
          ),
        ],
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
        onPressed: () => _showGasTypeDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              const Icon(Icons.water_drop,
                  color: Color(0xFF0066CC), size: 28),
              const SizedBox(width: 12),
              const Text('Fuel Management',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showQuickPriceModal,
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('Quick Price Update'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
              ),
            ]),
            const SizedBox(height: 24),
            // ── Fuel Types ──
            _buildCard('Fuel Types', Icons.list, _buildGasTypesTable()),
            const SizedBox(height: 16),
            // ── Price History ──
            _buildCard('Price History', Icons.trending_up, _buildPriceHistory()),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Widget child) {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Icon(icon, color: const Color(0xFF0066CC), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
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
  Widget _buildGasTypesTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('gas_types')
          .where('isDeleted', isEqualTo: false)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066CC)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: Text('No fuel types',
                    style: TextStyle(color: Colors.white54))),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(
                  label: Text('Name',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Price In (MAD/L)',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Price Out (MAD/L)',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Margin',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Color',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Actions',
                      style: TextStyle(color: Colors.white))),
            ],
            rows: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final name = d['name'] ?? '';
              final priceIn = (d['priceIn'] as num?)?.toDouble() ?? 0;
              final priceOut = (d['priceOut'] as num?)?.toDouble() ?? 0;
              final margin = priceOut - priceIn;
              final colorName = d['color'] ?? 'blue';
              final chipColor = _parseColor(colorName);
              return DataRow(cells: [
                DataCell(Text(name,
                    style: const TextStyle(color: Colors.white))),
                DataCell(Text(priceIn.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white54))),
                DataCell(Text(priceOut.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white54))),
                DataCell(Text(margin.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white54))),
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(colorName,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                )),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        size: 18, color: Color(0xFF0066CC)),
                    onPressed: () =>
                        _showGasTypeDialog(gasType: d, docId: id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        size: 18, color: Colors.red),
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

  Widget _buildPriceHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('fuelPriceHistory')
          .where('isDeleted', isEqualTo: false)
          .orderBy('changedAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066CC)));
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
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 11)),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _priceFilter = f),
                      selectedColor: const Color(0xFF0066CC),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
                const Spacer(),
                Text('${docs.length} changes',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 8),
            // Chart
            if (docs.isNotEmpty)
              SizedBox(
                height: 180,
                child: _buildPriceChart(docs),
              ),
            const SizedBox(height: 12),
            // Table
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: Text('No price history yet',
                        style: TextStyle(color: Colors.white54))),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(
                        label: Text('Date',
                            style: TextStyle(color: Colors.white))),
                    DataColumn(
                        label: Text('Fuel Type',
                            style: TextStyle(color: Colors.white))),
                    DataColumn(
                        label: Text('Old Price',
                            style: TextStyle(color: Colors.white))),
                    DataColumn(
                        label: Text('New Price',
                            style: TextStyle(color: Colors.white))),
                    DataColumn(
                        label: Text('Change',
                            style: TextStyle(color: Colors.white))),
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
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11))),
                      DataCell(Text(d['gasTypeId'] ?? '',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11))),
                      DataCell(Text(oldPrice.toStringAsFixed(2),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11))),
                      DataCell(Text(newPrice.toStringAsFixed(2),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11))),
                      DataCell(Text(
                          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: change >= 0
                                  ? const Color(0xFF84CC16)
                                  : const Color(0xFFEF4444),
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

  Widget _buildPriceChart(List<QueryDocumentSnapshot> docs) {
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
      const Color(0xFF0066CC),
      const Color(0xFF84CC16),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];

    return Card(
      color: const Color(0xFF0B1220),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.white.withValues(alpha: 0.05),
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

  Color _parseColor(String name) {
    switch (name) {
      case 'red':
        return Colors.red;
      case 'green':
        return const Color(0xFF84CC16);
      case 'yellow':
        return Colors.yellow;
      case 'white':
        return Colors.white;
      default:
        return Colors.blue;
    }
  }
}
