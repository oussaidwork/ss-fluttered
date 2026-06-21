import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import 'section_card.dart';

class RefillHistorySection extends StatefulWidget {
  const RefillHistorySection({super.key});

  @override
  State<RefillHistorySection> createState() => _RefillHistorySectionState();
}

class _RefillHistorySectionState extends State<RefillHistorySection> {
  void _showRefillDialog({Map<String, dynamic>? refill, String? docId}) {
    final pitIdCtrl =
        TextEditingController(text: refill?['pitId'] ?? '');
    final volumeCtrl = TextEditingController(
        text: refill?['volumeAdded']?.toString() ?? '');
    final costPerLiterCtrl = TextEditingController(
        text: refill?['costPerLiter']?.toString() ?? '');
    final totalCostCtrl = TextEditingController(
        text: refill?['totalCost']?.toString() ?? '');
    final supplierCtrl =
        TextEditingController(text: refill?['supplier'] ?? '');
    final driverCtrl =
        TextEditingController(text: refill?['driverName'] ?? '');
    final plateCtrl =
        TextEditingController(text: refill?['vehiclePlate'] ?? '');
    final notesCtrl =
        TextEditingController(text: refill?['notes'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: Text(docId == null ? 'Add Refill' : 'Edit Refill',
              style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('pits')
                      .where('isDeleted', isEqualTo: false)
                      .snapshots(),
                  builder: (ctx, snap) {
                    final docs = snap.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      value: refill?['pitId'] as String?,
                      dropdownColor: const Color(0xFF1A2332),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Pit',
                          labelStyle:
                              TextStyle(color: Colors.white54)),
                      items: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                            value: d.id,
                            child: Text(data['name'] ?? ''));
                      }).toList(),
                      onChanged: (v) => pitIdCtrl.text = v ?? '',
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: volumeCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Volume Added (L)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costPerLiterCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Cost per Liter (DA)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalCostCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Total Cost (DA)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: supplierCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Supplier',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: driverCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Driver Name',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: plateCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Vehicle Plate',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Notes',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white24))),
                ),
              ]),
            ),
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
                final data = {
                  'pitId': pitIdCtrl.text,
                  'volumeAdded':
                      double.tryParse(volumeCtrl.text) ?? 0,
                  'costPerLiter':
                      double.tryParse(costPerLiterCtrl.text) ?? 0,
                  'totalCost':
                      double.tryParse(totalCostCtrl.text) ?? 0,
                  'supplier': supplierCtrl.text,
                  'driverName': driverCtrl.text,
                  'vehiclePlate': plateCtrl.text,
                  'notes': notesCtrl.text,
                  'date': Timestamp.now(),
                  'isDeleted': false,
                };
                if (docId == null) {
                  final id =
                      firestore.collection('pitRefills').doc().id;
                  await firestore
                      .collection('pitRefills')
                      .doc(id)
                      .set({...data, 'id': id});
                } else {
                  await firestore
                      .collection('pitRefills')
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

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Refill History',
      icon: Icons.history,
      trailing: ElevatedButton.icon(
        onPressed: () => _showRefillDialog(),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Refill'),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066CC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 12)),
      ),
      child: _buildRefillsTable(),
    );
  }

  Widget _buildRefillsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('pitRefills')
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF0066CC)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No refills recorded yet',
                  style: TextStyle(color: Colors.white54)),
            ),
          );
        }
        return FutureBuilder<QuerySnapshot>(
          future: firestore
              .collection('pits')
              .where('isDeleted', isEqualTo: false)
              .get(),
          builder: (ctx, pitSnap) {
            final pitMap = <String, String>{};
            for (final d in pitSnap.data?.docs ?? []) {
              pitMap[d.id] =
                  (d.data() as Map<String, dynamic>)['name'] ?? '';
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                      label: Text('Date',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Pit',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Volume (L)',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Cost/L',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Total',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Supplier',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Driver',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Actions',
                          style: TextStyle(color: Colors.white))),
                ],
                rows: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final date =
                      (d['date'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  final pitId = d['pitId'] as String? ?? '';
                  final volume =
                      (d['volumeAdded'] as num?)?.toDouble() ?? 0;
                  final costPerLiter =
                      (d['costPerLiter'] as num?)?.toDouble() ?? 0;
                  final total =
                      (d['totalCost'] as num?)?.toDouble() ?? 0;
                  final supplier = d['supplier'] ?? '';
                  final driver = d['driverName'] ?? '';
                  return DataRow(cells: [
                    DataCell(Text(
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12))),
                    DataCell(Text(pitMap[pitId] ?? pitId,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12))),
                    DataCell(Text(volume.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12))),
                    DataCell(Text(costPerLiter.toStringAsFixed(2),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12))),
                    DataCell(Text(total.toStringAsFixed(2),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12))),
                    DataCell(Text(supplier,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12))),
                    DataCell(Text(driver,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12))),
                    DataCell(
                        Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 16,
                            color: Color(0xFF0066CC)),
                        onPressed: () => _showRefillDialog(
                            refill: d, docId: id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 16, color: Colors.red),
                        onPressed: () async {
                          await firestore
                              .collection('pitRefills')
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
      },
    );
  }
}
