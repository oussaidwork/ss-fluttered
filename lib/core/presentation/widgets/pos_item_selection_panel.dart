import 'package:flutter/material.dart';
import '../../../domain/entities/gas_type.dart';
import '../../../domain/entities/product.dart';
import 'pos_fuel_tab.dart';
import 'pos_product_tab.dart';

/// Left-side panel with POS header, shift badge, tabs, and tab content.
class PosItemSelectionPanel extends StatelessWidget {
  final TabController tabController;
  final String? selectedShiftId;
  final String? selectedGasTypeId;
  final TextEditingController volumeController;
  final TextEditingController driverNameController;
  final TextEditingController vehiclePlateController;
  final String? selectedProductId;
  final TextEditingController quantityController;
  final ValueChanged<String?> onGasTypeChanged;
  final VoidCallback onFuelChanged;
  final void Function(GasType gasType, double volume, String driver, String plate) onAddFuelToCart;
  final ValueChanged<String?> onProductSelected;
  final VoidCallback onProductChanged;
  final void Function(Product product, double qty) onAddProductToCart;

  const PosItemSelectionPanel({
    super.key,
    required this.tabController,
    required this.selectedShiftId,
    required this.selectedGasTypeId,
    required this.volumeController,
    required this.driverNameController,
    required this.vehiclePlateController,
    required this.selectedProductId,
    required this.quantityController,
    required this.onGasTypeChanged,
    required this.onFuelChanged,
    required this.onAddFuelToCart,
    required this.onProductSelected,
    required this.onProductChanged,
    required this.onAddProductToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with shift badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.point_of_sale, color: Color(0xFF0066CC), size: 24),
                const SizedBox(width: 8),
                const Text('Point of Sale',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                _buildShiftBadge(),
              ],
            ),
          ),
          TabBar(
            controller: tabController,
            indicatorColor: const Color(0xFF0066CC),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.local_gas_station, size: 18), text: 'Fuel'),
              Tab(icon: Icon(Icons.inventory_2, size: 18), text: 'Products'),
              Tab(icon: Icon(Icons.design_services, size: 18), text: 'Services'),
            ],
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                PosFuelTab(
                  selectedGasTypeId: selectedGasTypeId,
                  volumeController: volumeController,
                  driverNameController: driverNameController,
                  vehiclePlateController: vehiclePlateController,
                  onGasTypeChanged: onGasTypeChanged,
                  onChanged: onFuelChanged,
                  onAddToCart: onAddFuelToCart,
                ),
                PosProductTab(
                  isService: false,
                  selectedProductId: selectedProductId,
                  quantityController: quantityController,
                  onProductSelected: onProductSelected,
                  onChanged: onProductChanged,
                  onAddToCart: onAddProductToCart,
                ),
                PosProductTab(
                  isService: true,
                  selectedProductId: selectedProductId,
                  quantityController: quantityController,
                  onProductSelected: onProductSelected,
                  onChanged: onProductChanged,
                  onAddToCart: onAddProductToCart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftBadge() {
    if (selectedShiftId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF84CC16).withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF84CC16).withAlpha(60)),
        ),
        child: Text(
            'Shift: ${selectedShiftId!.substring(0, 6).toUpperCase()}',
            style: const TextStyle(color: Color(0xFF84CC16), fontSize: 11)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
      ),
      child: const Text('No open shift',
          style: TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
    );
  }
}
