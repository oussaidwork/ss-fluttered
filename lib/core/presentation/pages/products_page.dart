import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  void _showDialog({Map<String, dynamic>? product, String? docId}) {
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final priceCtrl = TextEditingController(text: product?['price']?.toString() ?? '');
    final priceInCtrl = TextEditingController(text: product?['priceIn']?.toString() ?? '');
    final priceOutCtrl = TextEditingController(text: product?['priceOut']?.toString() ?? '');
    final unitCtrl = TextEditingController(text: product?['unit'] ?? '');
    final stockCtrl = TextEditingController(text: product?['stockQuantity']?.toString() ?? '');
    final categoryCtrl = TextEditingController(text: product?['category'] ?? '');
    bool isActive = product?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A2332),
              title: Text(
                docId == null ? 'Add Product' : 'Edit Product',
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
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Price (MAD)',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      title: const Text('Active', style: TextStyle(color: Colors.white)),
                      activeColor: const Color(0xFF84CC16),
                      contentPadding: EdgeInsets.zero,
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
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    final priceIn = double.tryParse(priceInCtrl.text);
                    final priceOut = double.tryParse(priceOutCtrl.text);
                    final unit = unitCtrl.text.trim();
                    final stock = double.tryParse(stockCtrl.text) ?? 0;
                    final category = categoryCtrl.text.trim();
                    if (name.isEmpty) return;

                    final data = {
                      'name': name,
                      'price': price,
                      'priceIn': priceIn,
                      'priceOut': priceOut,
                      'unit': unit.isEmpty ? null : unit,
                      'stockQuantity': stock,
                      'category': category.isEmpty ? null : category,
                      'isActive': isActive,
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
        stream: firestore.collection('products').where('isDeleted', isEqualTo: false).snapshots(),
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
                  Icon(Icons.inventory_2, size: 64, color: Color(0xFF0066CC)),
                  SizedBox(height: 16),
                  Text('No products', style: TextStyle(color: Colors.white54, fontSize: 18)),
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
                  DataColumn(label: Text('Price (MAD)', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Stock', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Category', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Active', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                ],
                rows: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final name = d['name'] ?? '';
                  final price = (d['price'] as num?)?.toDouble() ?? 0;
                  final stock = (d['stockQuantity'] as num?)?.toDouble() ?? 0;
                  final category = d['category'] ?? '-';
                  final active = d['isActive'] ?? false;
                  return DataRow(cells: [
                    DataCell(Text(name, style: const TextStyle(color: Colors.white))),
                    DataCell(Text(price.toStringAsFixed(2), style: const TextStyle(color: Colors.white54))),
                    DataCell(Text(stock.toStringAsFixed(0), style: const TextStyle(color: Colors.white54))),
                    DataCell(Text(category, style: const TextStyle(color: Colors.white54))),
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
                          onPressed: () => _showDialog(product: d, docId: id),
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
