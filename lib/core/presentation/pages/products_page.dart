import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';

/// Retail Products management with grid/list view, stock health indicators,
/// category filter, and search.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _gridView = true;

  static const _categories = [
    'All',
    'Fuel Related',
    'Lubricants',
    'Convenience',
    'Services',
    'Other',
  ];

  static const _categoryIcons = {
    'Fuel Related': Icons.local_gas_station,
    'Lubricants': Icons.oil_barrel,
    'Convenience': Icons.store,
    'Services': Icons.build,
    'Other': Icons.inventory_2,
  };

  // ─── Add/Edit Dialog ──────────────────────────────────────────
  void _showDialog({Map<String, dynamic>? product, String? docId}) {
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final priceCtrl =
        TextEditingController(text: product?['price']?.toString() ?? '');
    final priceInCtrl =
        TextEditingController(text: product?['priceIn']?.toString() ?? '');
    final priceOutCtrl =
        TextEditingController(text: product?['priceOut']?.toString() ?? '');
    final unitCtrl = TextEditingController(text: product?['unit'] ?? '');
    final stockCtrl = TextEditingController(
        text: product?['stockQuantity']?.toString() ?? '');
    final categoryCtrl =
        TextEditingController(text: product?['category'] ?? '');
    bool isActive = product?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
          backgroundColor: cs.surfaceContainerHighest,
          title: Text(docId == null ? 'Add Product' : 'Edit Product',
              style: TextStyle(color: cs.onSurface)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                    labelText: 'Selling Price (MAD)',
                    labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)))),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: priceInCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                        labelText: 'Price In',
                        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceOutCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                        labelText: 'Price Out',
                        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontSize: 12),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)))),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                        labelText: 'Unit (pcs/L/kg)',
                        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: stockCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                        labelText: 'Stock Qty',
                        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.24)))),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categoryCtrl.text.isEmpty ? null : categoryCtrl.text,
                dropdownColor: cs.surfaceContainerHighest,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
                items: _categories
                    .where((c) => c != 'All')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => categoryCtrl.text = v ?? '',
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: isActive,
                onChanged: (v) => setDialogState(() => isActive = v),
                title:
                    Text('Active', style: TextStyle(color: cs.onSurface)),
                activeColor: cs.secondary,
                contentPadding: EdgeInsets.zero,
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final data = {
                  'name': name,
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                  'priceIn': double.tryParse(priceInCtrl.text),
                  'priceOut': double.tryParse(priceOutCtrl.text),
                  'unit': unitCtrl.text.isEmpty ? null : unitCtrl.text.trim(),
                  'stockQuantity':
                      double.tryParse(stockCtrl.text) ?? 0,
                  'category':
                      categoryCtrl.text.isEmpty ? null : categoryCtrl.text.trim(),
                  'isActive': isActive,
                  'isDeleted': false,
                };
                if (docId == null) {
                  final id = firestore.collection('products').doc().id;
                  await firestore
                      .collection('products')
                      .doc(id)
                      .set({...data, 'id': id});
                } else {
                  await firestore
                      .collection('products')
                      .doc(docId)
                      .update(data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(docId == null ? 'Add' : 'Save',
                  style: TextStyle(color: cs.onSurface)),
            ),
          ],
        );},
      ),
    );
  }

  // ─── Stock Health ─────────────────────────────────────────────
  Widget _stockRing(double qty) {
    final cs = Theme.of(context).colorScheme;
    Color color;
    String label;
    if (qty <= 0) {
      color = cs.error;
      label = 'OUT';
    } else if (qty < 5) {
      color = cs.error;
      label = 'CRIT';
    } else if (qty < 15) {
      color = Colors.orange;
      label = 'LOW';
    } else if (qty < 50) {
      color = cs.primary;
      label = 'OK';
    } else {
      color = cs.secondary;
      label = 'GOOD';
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 40,
        height: 40,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: qty < 50 ? qty / 50 : 1,
            strokeWidth: 3,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
          Text(qty.toStringAsFixed(0),
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              color: color, fontSize: 8, fontWeight: FontWeight.w600)),
    ]);
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        onPressed: () => _showDialog(),
        child: Icon(Icons.add, color: cs.onSurface),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('products')
            .where('isDeleted', isEqualTo: false)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: cs.primary));
          }
          final docs = snap.data?.docs ?? [];
          // Filter
          var filtered = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final name = (d['name'] as String?)?.toLowerCase() ?? '';
            final category = d['category'] as String? ?? '';
            if (_selectedCategory != 'All' &&
                category != _selectedCategory) return false;
            if (_searchQuery.isNotEmpty &&
                !name.contains(_searchQuery.toLowerCase())) return false;
            return true;
          }).toList();

          return Column(children: [
            // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(children: [
                  Icon(Icons.inventory_2,
                      color: cs.primary, size: 28),
                  const SizedBox(width: 12),
                  Text('Retail Stock',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface)),
                  const Spacer(),
                  // Search
                  SizedBox(
                    width: 200,
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style:
                          TextStyle(color: cs.onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.38), fontSize: 12),
                        prefixIcon: Icon(Icons.search,
                            color: cs.onSurface.withValues(alpha: 0.38), size: 18),
                        filled: true,
                        fillColor: cs.onSurface.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // View toggle
                  IconButton(
                    icon: Icon(
                        _gridView ? Icons.view_list : Icons.grid_view,
                        color: cs.onSurface.withValues(alpha: 0.54),
                        size: 20),
                    onPressed: () =>
                        setState(() => _gridView = !_gridView),
                  ),
                ]),
              ),
            // Category filter chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, idx) {
                  final cat = _categories[idx];
                  final selected = _selectedCategory == cat;
                  return FilterChip(
                    label: Text(cat,
                        style: TextStyle(
                            color:
                                selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.54),
                            fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(
                        () => _selectedCategory = cat),
                    selectedColor: cs.primary,
                    backgroundColor:
                        cs.onSurface.withValues(alpha: 0.05),
                    checkmarkColor: cs.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Content
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No products found',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))))
                  : _gridView
                      ? _buildGrid(cs, filtered)
                      : _buildList(cs, filtered),
            ),
          ]);
        },
      ),
    );
  }

  // ─── Grid View ────────────────────────────────────────────────
  Widget _buildGrid(ColorScheme cs, List<QueryDocumentSnapshot> docs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: docs.length,
        itemBuilder: (ctx, idx) => _buildProductCard(cs, docs[idx]),
      ),
    );
  }

  Widget _buildProductCard(ColorScheme cs, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    final name = d['name'] ?? '';
    final price = (d['price'] as num?)?.toDouble() ?? 0;
    final stock = (d['stockQuantity'] as num?)?.toDouble() ?? 0;
    final category = d['category'] as String? ?? 'Other';
    final catIcon = _categoryIcons[category] ?? Icons.inventory_2;

    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(catIcon, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 8),
              // Stock ring
              Center(child: _stockRing(stock)),
              const SizedBox(height: 8),
              Text('DA $price',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 4),
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(category,
                    style: TextStyle(
                        color: cs.primary, fontSize: 10)),
              ),
              const Spacer(),
              // Actions
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDialog(product: d, docId: id),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(color: cs.primary),
                        padding: const EdgeInsets.symmetric(vertical: 4)),
                    child: const Text('Edit', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await firestore
                          .collection('products')
                          .doc(id)
                          .update({'isDeleted': true});
                    },
                    style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error),
                        padding: const EdgeInsets.symmetric(vertical: 4)),
                    child: const Text('Delete', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ]),
            ]),
      ),
    );
  }

  // ─── List View (DataTable) ────────────────────────────────────
  Widget _buildList(ColorScheme cs, List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            DataColumn(label: Text('Name', style: TextStyle(color: cs.onSurface))),
            DataColumn(label: Text('Price', style: TextStyle(color: cs.onSurface))),
            DataColumn(label: Text('Stock', style: TextStyle(color: cs.onSurface))),
            DataColumn(label: Text('Category', style: TextStyle(color: cs.onSurface))),
            DataColumn(label: Text('Active', style: TextStyle(color: cs.onSurface))),
            DataColumn(label: Text('Actions', style: TextStyle(color: cs.onSurface))),
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
              DataCell(Text(name,
                  style: TextStyle(color: cs.onSurface))),
              DataCell(Text(price.toStringAsFixed(2),
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)))),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                _stockRing(stock),
                const SizedBox(width: 8),
                Text(stock.toStringAsFixed(0),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54))),
              ])),
              DataCell(Text(category,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54)))),
              DataCell(Icon(
                  active ? Icons.check_circle : Icons.cancel,
                  color: active ? cs.secondary : cs.error,
                  size: 20)),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: Icon(Icons.edit,
                        size: 20, color: cs.primary),
                    onPressed: () => _showDialog(product: d, docId: id)),
                IconButton(
                    icon: Icon(Icons.delete,
                        size: 20, color: cs.error),
                    onPressed: () async {
                      await firestore
                          .collection('products')
                          .doc(id)
                          .update({'isDeleted': true});
                    }),
              ])),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
