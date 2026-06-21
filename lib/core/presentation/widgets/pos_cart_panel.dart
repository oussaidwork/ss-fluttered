import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/payment_type.dart';
import '../../../domain/enums/sale_type.dart';
import 'pos_cart_item.dart';

/// Displays the cart contents, client/payment selection, and submit button.
class PosCartPanel extends StatelessWidget {
  final List<PosCartItem> cart;
  final String? selectedPaymentTypeId;
  final String? selectedClientId;
  final bool isSubmitting;
  final ValueChanged<int> onRemoveItem;
  final ValueChanged<String?> onPaymentTypeChanged;
  final ValueChanged<String?> onClientChanged;
  final VoidCallback onSubmit;

  const PosCartPanel({
    super.key,
    required this.cart,
    required this.selectedPaymentTypeId,
    required this.selectedClientId,
    required this.isSubmitting,
    required this.onRemoveItem,
    required this.onPaymentTypeChanged,
    required this.onClientChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.fold<double>(0, (total, item) => total + item.lineTotal);

    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Color(0xFF0066CC), size: 20),
                const SizedBox(width: 8),
                Text('Cart (${cart.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 48, color: Colors.white24),
                        SizedBox(height: 8),
                        Text('Cart is empty', style: TextStyle(color: Colors.white38)),
                        SizedBox(height: 4),
                        Text('Add items from the left panel',
                            style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cart.length,
                    itemBuilder: (ctx, idx) {
                      final item = cart[idx];
                      final icon = item.saleType == SaleType.fuel
                          ? Icons.local_gas_station
                          : item.saleType == SaleType.service
                              ? Icons.build
                              : Icons.inventory_2;
                      final iconColor = item.saleType == SaleType.fuel
                          ? const Color(0xFF84CC16)
                          : const Color(0xFF0066CC);
                      return Dismissible(
                        key: ValueKey('${item.saleType.value}_$idx'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: const Color(0xFFEF4444),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => onRemoveItem(idx),
                        child: Card(
                          color: const Color(0xFF0B1220),
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            leading: Icon(icon, size: 20, color: iconColor),
                            title: Text(item.label,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                            trailing: Text('${item.lineTotal.toStringAsFixed(2)} DA',
                                style: const TextStyle(
                                    color: Color(0xFF84CC16),
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Payment & Client section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client selection
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('clients')
                      .where('isDeleted', isEqualTo: false)
                      .snapshots(),
                  builder: (ctx, snap) {
                    final clients = snap.hasData
                        ? snap.data!.docs
                            .map((d) => Client.fromMap(d.data() as Map<String, dynamic>))
                            .toList()
                        : <Client>[];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DropdownButtonFormField<String>(
                        value: selectedClientId,
                        dropdownColor: const Color(0xFF0B1220),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Client (optional)',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Walk-in Customer',
                                style: TextStyle(color: Colors.white38, fontSize: 13)),
                          ),
                          ...clients.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name, style: const TextStyle(fontSize: 13)),
                              )),
                        ],
                        onChanged: onClientChanged,
                      ),
                    );
                  },
                ),
                // Payment method
                StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('payment_types').snapshots(),
                  builder: (ctx, snap) {
                    final types = snap.hasData
                        ? snap.data!.docs
                            .map((d) =>
                                PaymentType.fromMap(d.data() as Map<String, dynamic>))
                            .toList()
                        : <PaymentType>[];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DropdownButtonFormField<String>(
                        value: selectedPaymentTypeId,
                        dropdownColor: const Color(0xFF0B1220),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Payment Method *',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                        ),
                        items: types
                            .map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.name, style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: onPaymentTypeChanged,
                      ),
                    );
                  },
                ),
                // Total & Submit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total',
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('${subtotal.toStringAsFixed(2)} DA',
                            style: const TextStyle(
                                color: Color(0xFF84CC16),
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: (cart.isNotEmpty &&
                                selectedPaymentTypeId != null &&
                                !isSubmitting)
                            ? onSubmit
                            : null,
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.payment, size: 18),
                        label: Text(isSubmitting
                            ? 'Saving...'
                            : 'Pay ${subtotal.toStringAsFixed(2)} DA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF84CC16),
                          foregroundColor: const Color(0xFF0B1220),
                          disabledBackgroundColor: Colors.white12,
                          disabledForegroundColor: Colors.white24,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
