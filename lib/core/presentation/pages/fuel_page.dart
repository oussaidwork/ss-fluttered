import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

class FuelPage extends StatefulWidget {
  const FuelPage({super.key});

  @override
  State<FuelPage> createState() => _FuelPageState();
}

class _FuelPageState extends State<FuelPage> {
  void _showDialog({Map<String, dynamic>? gasType, String? docId}) {
    final nameCtrl = TextEditingController(text: gasType?['name'] ?? '');
    final priceInCtrl = TextEditingController(text: gasType?['priceIn']?.toString() ?? '');
    final priceOutCtrl = TextEditingController(text: gasType?['priceOut']?.toString() ?? '');
    String selectedColor = gasType?['color'] ?? 'blue';

    final colorOptions = ['red', 'blue', 'green', 'yellow', 'white'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A2332),
              title: Text(
                docId == null ? 'Add Fuel Type' : 'Edit Fuel Type',
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
                      controller: priceInCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Price In (MAD/L)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceOutCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Price Out (MAD/L)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedColor,
                      dropdownColor: const Color(0xFF1A2332),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                      items: colorOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setDialogState(() => selectedColor = v ?? 'blue'),
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
                      await firestore.collection('gas_types').doc(id).set({...data, 'id': id});
                    } else {
                      await firestore.collection('gas_types').doc(docId).update(data);
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
        stream: firestore.collection('gas_types').where('isDeleted', isEqualTo: false).snapshots(),
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
                  Icon(Icons.water_drop, size: 64, color: Color(0xFF0066CC)),
                  SizedBox(height: 16),
                  Text('No fuel types', style: TextStyle(color: Colors.white54, fontSize: 18)),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Price In (MAD/L)', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Price Out (MAD/L)', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Margin', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Color', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                ],
                rows: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final name = d['name'] ?? '';
                  final priceIn = (d['priceIn'] as num?)?.toDouble() ?? 0;
                  final priceOut = (d['priceOut'] as num?)?.toDouble() ?? 0;
                  final margin = priceOut - priceIn;
                  final colorName = d['color'] ?? 'blue';
                  final Color chipColor;
                  switch (colorName) {
                    case 'red':
                      chipColor = Colors.red;
                      break;
                    case 'green':
                      chipColor = const Color(0xFF84CC16);
                      break;
                    case 'yellow':
                      chipColor = Colors.yellow;
                      break;
                    case 'white':
                      chipColor = Colors.white;
                      break;
                    default:
                      chipColor = Colors.blue;
                  }
                  return DataRow(cells: [
                    DataCell(Text(name, style: const TextStyle(color: Colors.white))),
                    DataCell(Text(priceIn.toStringAsFixed(2), style: const TextStyle(color: Colors.white54))),
                    DataCell(Text(priceOut.toStringAsFixed(2), style: const TextStyle(color: Colors.white54))),
                    DataCell(Text(margin.toStringAsFixed(2), style: const TextStyle(color: Colors.white54))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(colorName, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Color(0xFF0066CC)),
                          onPressed: () => _showDialog(gasType: d, docId: id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () async {
                            await firestore.collection('gas_types').doc(id).update({'isDeleted': true});
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
      ),
    );
  }
}
