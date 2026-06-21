import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/gas_type.dart';

class PosFuelTab extends StatelessWidget {
  final String? selectedGasTypeId;
  final TextEditingController volumeController;
  final TextEditingController driverNameController;
  final TextEditingController vehiclePlateController;
  final ValueChanged<String?> onGasTypeChanged;
  final VoidCallback onChanged;
  final void Function(GasType gasType, double volume, String driver, String plate) onAddToCart;

  const PosFuelTab({
    super.key,
    required this.selectedGasTypeId,
    required this.volumeController,
    required this.driverNameController,
    required this.vehiclePlateController,
    required this.onGasTypeChanged,
    required this.onChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('gas_types')
          .where('isDeleted', isEqualTo: false)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final gasTypes = snap.data!.docs
            .map((d) => GasType.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        final selectedGasType =
            gasTypes.where((g) => g.id == selectedGasTypeId).firstOrNull;
        final volume = double.tryParse(volumeController.text) ?? 0;
        final computedPrice =
            selectedGasType != null ? volume * selectedGasType.priceOut : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fuel Type',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedGasTypeId,
                dropdownColor: const Color(0xFF0B1220),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0B1220),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                hint: const Text('Select fuel type',
                    style: TextStyle(color: Colors.white38)),
                items: gasTypes.map((g) {
                  return DropdownMenuItem(
                    value: g.id,
                    child: Text(
                        '${g.name} — ${g.priceOut.toStringAsFixed(2)} DA/L'),
                  );
                }).toList(),
                onChanged: onGasTypeChanged,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: volumeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'))
                      ],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Volume (Liters)',
                        labelStyle:
                            const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0B1220),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1220),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Text(
                            '${computedPrice.toStringAsFixed(2)} DA',
                            style: const TextStyle(
                                color: Color(0xFF84CC16),
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: driverNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Driver Name (optional)',
                        labelStyle:
                            const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0B1220),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: vehiclePlateController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Vehicle Plate (optional)',
                        labelStyle:
                            const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0B1220),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (selectedGasType != null && volume > 0)
                      ? () => onAddToCart(
                            selectedGasType,
                            volume,
                            driverNameController.text,
                            vehiclePlateController.text,
                          )
                      : null,
                  icon: const Icon(Icons.add_shopping_cart, size: 20),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
