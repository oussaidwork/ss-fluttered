import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

class PumpsPage extends StatefulWidget {
  const PumpsPage({super.key});

  @override
  State<PumpsPage> createState() => _PumpsPageState();
}

class _PumpsPageState extends State<PumpsPage> {
  void _showDialog({Map<String, dynamic>? pump, String? docId}) {
    final nameCtrl = TextEditingController(text: pump?['name'] ?? '');
    final counterCtrl = TextEditingController(text: pump?['initialAnalogCounter']?.toString() ?? '');
    String? selectedGroupId = pump?['groupId'] ?? 'Block A';
    String? selectedPitId = pump?['pitId'];
    bool isActive = pump?['isActive'] ?? true;
    String selectedColor = pump?['color'] ?? 'red';

    final blockOptions = ['Block A', 'Block B', 'Block C', 'Block D'];
    final colorOptions = ['red', 'blue', 'green', 'yellow', 'white'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
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
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
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
                      items: blockOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setDialogState(() => selectedGroupId = v),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore.collection('pits').where('isDeleted', isEqualTo: false).snapshots(),
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
                            return DropdownMenuItem(value: d.id, child: Text(data['name'] ?? ''));
                          }).toList(),
                          onChanged: (v) => setDialogState(() => selectedPitId = v),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: counterCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Initial Counter',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      title: const Text('Active', style: TextStyle(color: Colors.white)),
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
                      items: colorOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setDialogState(() => selectedColor = v ?? 'red'),
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
                      await firestore.collection('pumps').doc(id).set({...data, 'id': id});
                    } else {
                      await firestore.collection('pumps').doc(docId).update(data);
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
        stream: firestore.collection('pumps').where('isDeleted', isEqualTo: false).snapshots(),
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
                  Icon(Icons.local_gas_station, size: 64, color: Color(0xFF0066CC)),
                  SizedBox(height: 16),
                  Text('No pumps', style: TextStyle(color: Colors.white54, fontSize: 18)),
                ],
              ),
            );
          }
          return StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('pits').where('isDeleted', isEqualTo: false).snapshots(),
            builder: (ctx, pitSnap) {
              final pitDocs = pitSnap.data?.docs ?? [];
              final pitMap = <String, String>{};
              for (final d in pitDocs) {
                pitMap[d.id] = (d.data() as Map<String, dynamic>)['name'] ?? '';
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Block', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Pit', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Counter', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Active', style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                    ],
                    rows: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final id = doc.id;
                      final name = d['name'] ?? '';
                      final groupId = d['groupId'] ?? '';
                      final pitId = d['pitId'] ?? '';
                      final counter = (d['initialAnalogCounter'] as num?)?.toDouble() ?? 0;
                      final active = d['isActive'] ?? false;
                      final pitName = pitMap[pitId] ?? '-';
                      return DataRow(cells: [
                        DataCell(Text(name, style: const TextStyle(color: Colors.white))),
                        DataCell(Text(groupId, style: const TextStyle(color: Colors.white54))),
                        DataCell(Text(pitName, style: const TextStyle(color: Colors.white54))),
                        DataCell(Text(counter.toStringAsFixed(1), style: const TextStyle(color: Colors.white54))),
                        DataCell(Icon(
                          active ? Icons.check_circle : Icons.cancel,
                          color: active ? const Color(0xFF84CC16) : Colors.red,
                          size: 20,
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Color(0xFF0066CC)),
                              onPressed: () => _showDialog(pump: d, docId: id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () async {
                                await firestore.collection('pumps').doc(id).update({'isDeleted': true});
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
