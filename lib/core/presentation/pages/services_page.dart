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
            final cs = Theme.of(ctx).colorScheme;
            return AlertDialog(
              backgroundColor: cs.surfaceContainerHighest,
              title: Text(
                docId == null ? 'Add Service' : 'Edit Service',
                style: TextStyle(color: cs.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceInCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Price In (MAD)',
                        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceOutCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Price Out (MAD)',
                        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitCtrl,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24))),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
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
                  child: Text(docId == null ? 'Add' : 'Save', style: TextStyle(color: cs.onPrimary)),
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        onPressed: () => _showDialog(),
        child: Icon(Icons.add, color: cs.onPrimary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('products')
            .where('category', isEqualTo: 'service')
            .where('isDeleted', isEqualTo: false)
            .snapshots(),
        builder: (ctx, snap) {
          final cs = Theme.of(context).colorScheme;
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.design_services, size: 64, color: cs.primary),
                  const SizedBox(height: 16),
                  Text('No services', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 18)),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Name', style: TextStyle(color: cs.onSurface))),
                  DataColumn(label: Text('Price Out (MAD)', style: TextStyle(color: cs.onSurface))),
                  DataColumn(label: Text('Unit', style: TextStyle(color: cs.onSurface))),
                  DataColumn(label: Text('Actions', style: TextStyle(color: cs.onSurface))),
                ],
                rows: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final name = d['name'] ?? '';
                  final priceOut = (d['price'] as num?)?.toDouble() ?? (d['priceOut'] as num?)?.toDouble() ?? 0;
                  final unit = d['unit'] ?? '-';
                  return DataRow(cells: [
                    DataCell(Text(name, style: TextStyle(color: cs.onSurface))),
                    DataCell(Text(priceOut.toStringAsFixed(2), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)))),
                    DataCell(Text(unit, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)))),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 20, color: cs.primary),
                          onPressed: () => _showDialog(service: d, docId: id),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 20, color: cs.error),
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
