import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

/// Pits management page with 3 accordion sections:
/// Pits List, Refill History, Fuel Suppliers.
class PitsPage extends StatefulWidget {
  const PitsPage({super.key});

  @override
  State<PitsPage> createState() => _PitsPageState();
}

class _PitsPageState extends State<PitsPage> {
  // ─── Pits ────────────────────────────────────────────────────
  void _showPitDialog({Map<String, dynamic>? pit, String? docId}) {
    final nameCtrl = TextEditingController(text: pit?['name'] ?? '');
    final capacityCtrl = TextEditingController(text: pit?['capacity']?.toString() ?? '');
    final volumeCtrl = TextEditingController(text: pit?['currentVolume']?.toString() ?? '');
    String? selectedGasTypeId = pit?['gasTypeId'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: Text(docId == null ? 'Add Pit' : 'Edit Pit',
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
                controller: capacityCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Capacity (L)',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: volumeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Current Volume (L)',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('gas_types')
                    .where('isDeleted', isEqualTo: false)
                    .snapshots(),
                builder: (ctx, snap) {
                  final docs = snap.data?.docs ?? [];
                  return DropdownButtonFormField<String>(
                    value: selectedGasTypeId,
                    dropdownColor: const Color(0xFF1A2332),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Gas Type',
                        labelStyle: TextStyle(color: Colors.white54)),
                    items: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                          value: d.id, child: Text(data['name'] ?? ''));
                    }).toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedGasTypeId = v),
                  );
                },
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC)),
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
              child: Text(docId == null ? 'Add' : 'Save',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Refills ──────────────────────────────────────────────────
  void _showRefillDialog({Map<String, dynamic>? refill, String? docId}) {
    final pitIdCtrl = TextEditingController(text: refill?['pitId'] ?? '');
    final volumeCtrl = TextEditingController(
        text: refill?['volumeAdded']?.toString() ?? '');
    final costPerLiterCtrl = TextEditingController(
        text: refill?['costPerLiter']?.toString() ?? '');
    final totalCostCtrl = TextEditingController(
        text: refill?['totalCost']?.toString() ?? '');
    final supplierCtrl = TextEditingController(text: refill?['supplier'] ?? '');
    final driverCtrl = TextEditingController(text: refill?['driverName'] ?? '');
    final plateCtrl = TextEditingController(text: refill?['vehiclePlate'] ?? '');
    final notesCtrl = TextEditingController(text: refill?['notes'] ?? '');

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
                          labelStyle: TextStyle(color: Colors.white54)),
                      items: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                            value: d.id, child: Text(data['name'] ?? ''));
                      }).toList(),
                      onChanged: (v) => pitIdCtrl.text = v ?? '',
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: volumeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Volume Added (L)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costPerLiterCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Cost per Liter (DA)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalCostCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Total Cost (DA)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: supplierCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Supplier',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: driverCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Driver Name',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: plateCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Vehicle Plate',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24))),
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
                          borderSide: BorderSide(color: Colors.white24))),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC)),
              onPressed: () async {
                final data = {
                  'pitId': pitIdCtrl.text,
                  'volumeAdded': double.tryParse(volumeCtrl.text) ?? 0,
                  'costPerLiter': double.tryParse(costPerLiterCtrl.text) ?? 0,
                  'totalCost': double.tryParse(totalCostCtrl.text) ?? 0,
                  'supplier': supplierCtrl.text,
                  'driverName': driverCtrl.text,
                  'vehiclePlate': plateCtrl.text,
                  'notes': notesCtrl.text,
                  'date': Timestamp.now(),
                  'isDeleted': false,
                };
                if (docId == null) {
                  final id = firestore.collection('pitRefills').doc().id;
                  await firestore.collection('pitRefills').doc(id).set({...data, 'id': id});
                } else {
                  await firestore.collection('pitRefills').doc(docId).update(data);
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

  // ─── Fuel Suppliers ───────────────────────────────────────────
  void _showSupplierDialog({Map<String, dynamic>? supplier, String? docId}) {
    final nameCtrl = TextEditingController(text: supplier?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: supplier?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: supplier?['email'] ?? '');
    final addressCtrl = TextEditingController(text: supplier?['address'] ?? '');

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
                        borderSide: BorderSide(color: Colors.white24))),
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
                        borderSide: BorderSide(color: Colors.white24))),
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
                        borderSide: BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24))),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066CC)),
            onPressed: () async {
              final data = {
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
                'isDeleted': false,
              };
              if (docId == null) {
                final id = firestore.collection('fuelSuppliers').doc().id;
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

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.local_gas_station,
                    color: Color(0xFF0066CC), size: 28),
                const SizedBox(width: 12),
                const Text('Pit Management',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(height: 24),
            // ── Section 1: Pits List ──
            _buildSection(
              title: 'Pits List',
              icon: Icons.inventory_2,
              child: _buildPitsList(),
            ),
            const SizedBox(height: 16),
            // ── Section 2: Refill History ──
            _buildSection(
              title: 'Refill History',
              icon: Icons.history,
              trailing: ElevatedButton.icon(
                onPressed: () => _showRefillDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Refill'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12)),
              ),
              child: _buildRefillsTable(),
            ),
            const SizedBox(height: 16),
            // ── Section 3: Fuel Suppliers ──
            _buildSection(
              title: 'Fuel Suppliers',
              icon: Icons.business,
              trailing: ElevatedButton.icon(
                onPressed: () => _showSupplierDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Supplier'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12)),
              ),
              child: _buildSuppliersTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0066CC), size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
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

  // ─── Pits List (existing) ──────────────────────────────────────
  Widget _buildPitsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('pits')
          .where('isDeleted', isEqualTo: false)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No pits found',
                  style: TextStyle(color: Colors.white54)),
            ),
          );
        }
        return StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('gas_types')
              .where('isDeleted', isEqualTo: false)
              .snapshots(),
          builder: (ctx, gasSnap) {
            final gasDocs = gasSnap.data?.docs ?? [];
            final gasMap = <String, String>{};
            for (final d in gasDocs) {
              gasMap[d.id] = (d.data() as Map<String, dynamic>)['name'] ?? '';
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                      label: Text('Name',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Gas Type',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Capacity (L)',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Current (L)',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Status',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label: Text('Actions',
                          style: TextStyle(color: Colors.white))),
                ],
                rows: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final name = d['name'] ?? '';
                  final capacity =
                      (d['capacity'] as num?)?.toDouble() ?? 0;
                  final volume =
                      (d['currentVolume'] as num?)?.toDouble() ?? 0;
                  final gasTypeId = d['gasTypeId'] as String?;
                  final gasName =
                      gasTypeId != null ? (gasMap[gasTypeId] ?? '-') : '-';
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
                    DataCell(Text(name,
                        style: const TextStyle(color: Colors.white))),
                    DataCell(Text(gasName,
                        style: const TextStyle(color: Colors.white54))),
                    DataCell(Text(capacity.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white54))),
                    DataCell(Text(volume.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white54))),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(statusText,
                          style: TextStyle(color: statusColor)),
                    ])),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 18, color: Color(0xFF0066CC)),
                        onPressed: () =>
                            _showPitDialog(pit: d, docId: id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 18, color: Colors.red),
                        onPressed: () async {
                          await firestore
                              .collection('pits')
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

  // ─── Refills Table ─────────────────────────────────────────────
  Widget _buildRefillsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('pitRefills')
          .where('isDeleted', isEqualTo: false)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
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
        // Load pit names
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
                  final date = (d['date'] as Timestamp?)?.toDate() ?? DateTime.now();
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12))),
                    DataCell(Text(pitMap[pitId] ?? pitId,
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12))),
                    DataCell(Text(volume.toStringAsFixed(1),
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12))),
                    DataCell(Text(costPerLiter.toStringAsFixed(2),
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12))),
                    DataCell(Text(total.toStringAsFixed(2),
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12))),
                    DataCell(Text(supplier,
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12))),
                    DataCell(Text(driver,
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12))),
                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 16, color: Color(0xFF0066CC)),
                        onPressed: () =>
                            _showRefillDialog(refill: d, docId: id),
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

  // ─── Suppliers Table ───────────────────────────────────────────
  Widget _buildSuppliersTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('fuelSuppliers')
          .where('isDeleted', isEqualTo: false)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
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
                    style: const TextStyle(color: Colors.white54))),
                DataCell(Text(d['email'] ?? '--',
                    style: const TextStyle(color: Colors.white54))),
                DataCell(Text(d['address'] ?? '--',
                    style: const TextStyle(color: Colors.white54))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        size: 18, color: Color(0xFF0066CC)),
                    onPressed: () =>
                        _showSupplierDialog(supplier: d, docId: id),
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
