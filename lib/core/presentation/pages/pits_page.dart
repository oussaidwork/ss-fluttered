import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

class PitsPage extends StatefulWidget {
  const PitsPage({super.key});

  @override
  State<PitsPage> createState() => _PitsPageState();
}

class _PitsPageState extends State<PitsPage> {
  void _showDialog({Map<String, dynamic>? pit, String? docId}) {
    final nameCtrl = TextEditingController(text: pit?['name'] ?? '');
    final capacityCtrl = TextEditingController(text: pit?['capacity']?.toString() ?? '');
    final volumeCtrl = TextEditingController(text: pit?['currentVolume']?.toString() ?? '');
    String? selectedGasTypeId = pit?['gasTypeId'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A2332),
              title: Text(
                docId == null ? 'Add Pit' : 'Edit Pit',
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
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: capacityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Capacity (L)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: volumeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Current Volume (L)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore.collection('gasTypes').where('isDeleted', isEqualTo: false).snapshots(),
                      builder: (ctx, snap) {
                        final docs = snap.data?.docs ?? [];
                        return DropdownButtonFormField<String>(
                          value: selectedGasTypeId,
                          dropdownColor: const Color(0xFF1A2332),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Gas Type',
                            labelStyle: TextStyle(color: Colors.white54),
                          ),
                          items: docs.map((d) {
                            final data = d.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: d.id,
                              child: Text(data['name'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (v) => setDialogState(() => selectedGasTypeId = v),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066CC)),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final capacity = double.tryParse(capacityCtrl.text) ?? 0;
                    final volume = double.tryParse(volumeCtrl.text) ?? 0;
                    if (name.isEmpty) return;

                    final data = {
                      'name': name,
                      'capacity': capacity,
                      'currentVolume': volume,
                      'gasTypeId': selectedGasTypeId,
                      'isDeleted': false,
                    };

                    if (docId == null) {
                      final id = firestore.collection('pits').doc().id;
                      await firestore.collection('pits').doc(id).set({...data, 'id': id});
                    } else {
                      await firestore.collection('pits').doc(docId).update(data);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(docId == null ? 'Add' : 'Save', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
        stream: firestore.collection('pits').where('isDeleted', isEqualTo: false).snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive, size: 64, color: Color(0xFF0066CC)),
                  SizedBox(height: 16),
                  Text('No pits', style: TextStyle(color: Colors.white54, fontSize: 18)),
                ],
              ),
            );
          }
          return StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('gasTypes').where('isDeleted', isEqualTo: false).snapshots(),
            builder: (ctx, gasSnap) {
              final gasDocs = gasSnap.data?.docs ?? [];
              final gasMap = <String, String>{};
              for (final d in gasDocs) {
                gasMap[d.id] = (d.data() as Map<String, dynamic>)['name'] ?? '';
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Gas Type', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Capacity (L)', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Current (L)', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                    ],
                    rows: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final id = doc.id;
                      final name = d['name'] ?? '';
                      final capacity = (d['capacity'] as num?)?.toDouble() ?? 0;
                      final volume = (d['currentVolume'] as num?)?.toDouble() ?? 0;
                      final gasTypeId = d['gasTypeId'] as String?;
                      final gasName = gasTypeId != null ? (gasMap[gasTypeId] ?? '-') : '-';
                      final pct = capacity > 0 ? volume / capacity : 0.0;
                      final Color statusColor;
                      final String statusText;
                      if (pct > 0.5) {
                        statusColor = const Color(0xFF84CC16);
                        statusText = 'Good';
                      } else if (pct >= 0.2) {
                        statusColor = Colors.orange;
                        statusText = 'Low';
                      } else {
                        statusColor = Colors.red;
                        statusText = 'Critical';
                      }
                      return DataRow(cells: [
                        DataCell(Text(name, style: const TextStyle(color: Colors.white))),
                        DataCell(Text(gasName, style: const TextStyle(color: Colors.white54))),
                        DataCell(Text(capacity.toStringAsFixed(1), style: const TextStyle(color: Colors.white54))),
                        DataCell(Text(volume.toStringAsFixed(1), style: const TextStyle(color: Colors.white54))),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(statusText, style: TextStyle(color: statusColor)),
                          ],
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Color(0xFF0066CC)),
                              onPressed: () => _showDialog(pit: d, docId: id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () async {
                                await firestore.collection('pits').doc(id).update({'isDeleted': true});
                              },
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
