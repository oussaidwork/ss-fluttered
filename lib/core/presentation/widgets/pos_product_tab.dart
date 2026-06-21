import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/product.dart';

/// Tab for selecting products or services in the POS.
class PosProductTab extends StatelessWidget {
  final bool isService;
  final String? selectedProductId;
  final TextEditingController quantityController;
  final ValueChanged<String?> onProductSelected;
  final VoidCallback onChanged;
  final void Function(Product product, double qty) onAddToCart;

  const PosProductTab({
    super.key,
    required this.isService,
    required this.selectedProductId,
    required this.quantityController,
    required this.onProductSelected,
    required this.onChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final categoryFilter = isService ? 'service' : null;

    return StreamBuilder<QuerySnapshot>(
      stream: categoryFilter != null
          ? firestore
              .collection('products')
              .where('category', isEqualTo: categoryFilter)
              .where('isDeleted', isEqualTo: false)
              .snapshots()
          : firestore
              .collection('products')
              .where('isDeleted', isEqualTo: false)
              .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066CC)));
        }
        final products = snap.data!.docs
            .map((d) => Product.fromMap(d.data() as Map<String, dynamic>))
            .where((p) =>
                isService
                    ? p.category == 'service'
                    : (p.category == null || p.category != 'service'))
            .where((p) => p.isActive)
            .toList();

        final selectedProduct =
            products.where((p) => p.id == selectedProductId).firstOrNull;
        final qty = double.tryParse(quantityController.text) ?? 1;
        final computedPrice =
            selectedProduct != null ? qty * selectedProduct.price : 0.0;

        return Column(
          children: [
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              isService
                                  ? Icons.design_services
                                  : Icons.inventory_2,
                              size: 48,
                              color: Colors.white24),
                          const SizedBox(height: 8),
                          Text(
                              isService
                                  ? 'No services configured'
                                  : 'No products found',
                              style: const TextStyle(color: Colors.white38)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (ctx, idx) {
                        final p = products[idx];
                        final isSelected = selectedProductId == p.id;
                        return GestureDetector(
                          onTap: () => onProductSelected(p.id),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0066CC).withAlpha(30)
                                  : const Color(0xFF0B1220),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0066CC)
                                    : Colors.white12,
                              ),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.name,
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${p.price.toStringAsFixed(2)} DA',
                                    style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF84CC16)
                                            : Colors.white54,
                                        fontSize: 12)),
                                if (p.stockQuantity > 0)
                                  Text(
                                      'Stock: ${p.stockQuantity.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (selectedProduct != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220),
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    Text('${selectedProduct.name}: ',
                        style: const TextStyle(color: Colors.white70)),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Qty',
                          labelStyle: TextStyle(color: Colors.white54),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('= ${computedPrice.toStringAsFixed(2)} DA',
                        style: const TextStyle(
                            color: Color(0xFF84CC16),
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () =>
                          onAddToCart(selectedProduct, qty),
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
