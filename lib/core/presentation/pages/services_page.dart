import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  void _showDialog({Map<String, dynamic>? service, String? docId}) {
    final nameCtrl = TextEditingController(text: service?['name'] ?? '');
    final priceInCtrl = TextEditingController(text: service?['priceIn']?.toString() ?? '');
    final priceOutCtrl = TextEditingController(text: service?['price']?.toString() ?? service?['priceOut']?.toString() ?? '');
    final unitCtrl = TextEditingController(text: service?['unit'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A2332),
              title: Text(
                docId == null ? 'Add Service' : 'Edit Service',
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
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Price In (MAD)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceOutCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Price Out (MAD)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
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
                    final priceIn = double.tryParse(priceInCtrl.text);
                    final priceOut = double.tryParse(priceOutCtrl.text) ?? 0;
                    final unit = unitCtrl.text.trim();
                    if (name.isEmpty) return;

                    final data = {
                      'name': name,
                      'price': priceOut,
                      'priceIn': priceIn,
                      'priceOut': priceOut,
                      'unit': unit.isEmpty ? null : unit,
                      'category': 'service',
                      'stockQuantity': 0,
                      'isActive': true,
                      'isDeleted': false,
                    };

                    if (docId == null) {
                      final id = firestore.collection('products').doc().id;
                      await firestore.collection('products').doc(id).set({...data, 'id': id});
                    } else {
                      await firestore.collection('products').doc(docId).update(data);
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
        stream: firestore
            .collection('products')
            .where('category', isEqualTo: 'service')
            .where('isDeleted', isEqualTo: false)
            .snapshots(),
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
                  Icon(Icons.design_services, size: 64, color: Color(0xFF0066CC)),
                  SizedBox(height: 16),
                  Text('No services', style: TextStyle(color: Colors.white54, fontSize: 18)),
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
                  DataColumn(label: Text('Price Out (MAD)', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Unit', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                ],
                rows: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final name = d['name'] ?? '';
                  final priceOut = (d['price'] as num?)?.toDouble() ?? (d['priceOut'] as num?)?.toDouble() ?? 0;
                  final unit = d['unit'] ?? '-';
                  return DataRow(cells: [
                    DataCell(Text(name, style: const TextStyle(color: Colors.white))),
                    DataCell(Text(priceOut.toStringAsFixed(2), style: const TextStyle(color: Colors.white54))),
                    DataCell(Text(unit, style: const TextStyle(color: Colors.white54))),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Color(0xFF0066CC)),
                          onPressed: () => _showDialog(service: d, docId: id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () async {
                            await firestore.collection('products').doc(id).update({'isDeleted': true});
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
