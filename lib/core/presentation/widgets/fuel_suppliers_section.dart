import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import 'section_card.dart';

class FuelSuppliersSection extends StatefulWidget {
  const FuelSuppliersSection({super.key});

  @override
  State<FuelSuppliersSection> createState() => _FuelSuppliersSectionState();
}

class _FuelSuppliersSectionState extends State<FuelSuppliersSection> {
  void _showSupplierDialog({Map<String, dynamic>? supplier, String? docId}) {
    final nameCtrl =
        TextEditingController(text: supplier?['name'] ?? '');
    final phoneCtrl =
        TextEditingController(text: supplier?['phone'] ?? '');
    final emailCtrl =
        TextEditingController(text: supplier?['email'] ?? '');
    final addressCtrl =
        TextEditingController(text: supplier?['address'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: Text(docId == null ? 'Add Supplier' : 'Edit Supplier',
            style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Phone',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Address',
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
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
                'isDeleted': false,
              };
              if (docId == null) {
                final id =
                    firestore.collection('fuelSuppliers').doc().id;
                await firestore
                    .collection('fuelSuppliers')
                    .doc(id)
                    .set({...data, 'id': id});
              } else {
                await firestore
                    .collection('fuelSuppliers')
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Fuel Suppliers',
      icon: Icons.business,
      trailing: ElevatedButton.icon(
        onPressed: () => _showSupplierDialog(),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Supplier'),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066CC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 12)),
      ),
      child: _buildSuppliersTable(),
    );
  }

  Widget _buildSuppliersTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('fuelSuppliers')
          .where('isDeleted', isEqualTo: false)
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
              child: Text('No suppliers yet',
                  style: TextStyle(color: Colors.white54)),
            ),
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
                  label: Text('Phone',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Email',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Address',
                      style: TextStyle(color: Colors.white))),
              DataColumn(
                  label: Text('Actions',
                      style: TextStyle(color: Colors.white))),
            ],
            rows: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              return DataRow(cells: [
                DataCell(Text(d['name'] ?? '',
                    style: const TextStyle(color: Colors.white))),
                DataCell(Text(d['phone'] ?? '--',
                    style:
                        const TextStyle(color: Colors.white54))),
                DataCell(Text(d['email'] ?? '--',
                    style:
                        const TextStyle(color: Colors.white54))),
                DataCell(Text(d['address'] ?? '--',
                    style:
                        const TextStyle(color: Colors.white54))),
                DataCell(
                    Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        size: 18, color: Color(0xFF0066CC)),
                    onPressed: () => _showSupplierDialog(
                        supplier: d, docId: id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        size: 18, color: Colors.red),
                    onPressed: () async {
                      await firestore
                          .collection('fuelSuppliers')
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
}
