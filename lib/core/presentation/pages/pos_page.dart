import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/gas_type.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/payment_type.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/enums/sale_type.dart';

/// A line item in the POS cart.
class _CartItem {
  SaleType saleType;
  String? gasTypeId;
  String? productId;
  String label;
  double unitPrice;
  double quantity;
  double volume;
  String? driverName;
  String? vehiclePlate;

  _CartItem({
    required this.saleType,
    this.gasTypeId,
    this.productId,
    required this.label,
    required this.unitPrice,
    this.quantity = 1.0,
    this.volume = 0.0,
    this.driverName,
    this.vehiclePlate,
  });

  double get lineTotal {
    if (saleType == SaleType.fuel) return volume * unitPrice;
    return quantity * unitPrice;
  }
}

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<_CartItem> _cart = [];
  String? _selectedPaymentTypeId;
  String? _selectedClientId;
  String? _selectedShiftId;
  bool _isSubmitting = false;

  // Fuel form fields
  String? _selectedGasTypeId;
  final _volumeController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _vehiclePlateController = TextEditingController();

  // Product/Service form fields
  String? _selectedProductId;
  final _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOpenShift();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _volumeController.dispose();
    _driverNameController.dispose();
    _vehiclePlateController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadOpenShift() async {
    final snap = await firestore
        .collection('work_shifts')
        .where('status', isEqualTo: 'OPEN')
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty && mounted) {
      setState(() {
        _selectedShiftId = snap.docs.first.id;
      });
    }
  }

  void _addFuelItem(GasType gasType, double volume, String? driver, String? plate) {
    setState(() {
      _cart.add(_CartItem(
        saleType: SaleType.fuel,
        gasTypeId: gasType.id,
        label: '${gasType.name} — ${volume.toStringAsFixed(1)}L',
        unitPrice: gasType.priceOut,
        volume: volume,
        driverName: driver?.isNotEmpty == true ? driver : null,
        vehiclePlate: plate?.isNotEmpty == true ? plate : null,
      ));
      _selectedGasTypeId = null;
      _volumeController.clear();
      _driverNameController.clear();
      _vehiclePlateController.clear();
    });
  }

  void _addProductItem(Product product, double qty) {
    setState(() {
      _cart.add(_CartItem(
        saleType: product.category == 'service' ? SaleType.service : SaleType.product,
        productId: product.id,
        label: '${product.name} x$qty',
        unitPrice: product.price,
        quantity: qty,
      ));
      _selectedProductId = null;
      _quantityController.text = '1';
    });
  }

  void _removeCartItem(int index) {
    setState(() => _cart.removeAt(index));
  }

  Future<void> _submitSale() async {
    if (_cart.isEmpty) return;
    if (_selectedPaymentTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a payment method'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final totalAmount =
          _cart.fold<double>(0, (total, item) => total + item.lineTotal);
      final saleId = firestore.collection('sales').doc().id;

      // Create Sale header
      await firestore.collection('sales').doc(saleId).set({
        'id': saleId,
        'shiftId': _selectedShiftId,
        'clientId': _selectedClientId,
        'workerId': null, // will be set to current user in future
        'paymentTypeId': _selectedPaymentTypeId,
        'totalAmount': totalAmount,
        'notes': null,
        'timestamp': Timestamp.fromDate(now),
        'isDeleted': false,
        'createdAt': Timestamp.fromDate(now),
      });

      // Create SaleItems in batch
      final batch = firestore.batch();
      for (final item in _cart) {
        final itemId = firestore.collection('sale_items').doc().id;
        final itemDoc = firestore.collection('sale_items').doc(itemId);
        batch.set(itemDoc, {
          'id': itemId,
          'saleId': saleId,
          'saleType': item.saleType.value,
          'gasTypeId': item.gasTypeId,
          'productId': item.productId,
          'volume': item.volume > 0 ? item.volume : null,
          'unitPrice': item.unitPrice,
          'lineTotal': item.lineTotal,
          'quantity': item.quantity,
          'driverName': item.driverName,
          'vehiclePlate': item.vehiclePlate,
          'notes': null,
          'timestamp': Timestamp.fromDate(now),
        });
      }

      // Update pit volumes for fuel sales
      for (final item in _cart.where((i) => i.saleType == SaleType.fuel && i.gasTypeId != null)) {
        // Find the pit linked to this gas type
        final pitsSnap = await firestore
            .collection('pits')
            .where('gasTypeId', isEqualTo: item.gasTypeId)
            .where('isDeleted', isEqualTo: false)
            .limit(1)
            .get();
        for (final pitDoc in pitsSnap.docs) {
          final currentVol =
              (pitDoc.data()['currentVolume'] as num?)?.toDouble() ?? 0;
          final newVol = (currentVol - item.volume).clamp(0, double.infinity);
          batch.update(pitDoc.reference, {'currentVolume': newVol});
        }
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _cart.clear();
          _selectedPaymentTypeId = null;
          _selectedClientId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale recorded: ${totalAmount.toStringAsFixed(2)} DA'),
            backgroundColor: const Color(0xFF84CC16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record sale: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Item Selection
        Expanded(
          flex: 3,
          child: _buildItemSelectionPanel(),
        ),
        const SizedBox(width: 16),
        // Right: Cart
        SizedBox(
          width: 380,
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _buildItemSelectionPanel(),
        ),
        const Divider(color: Colors.white12),
        Expanded(
          flex: 2,
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // ITEM SELECTION PANEL
  // ──────────────────────────────────────────────

  Widget _buildItemSelectionPanel() {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.point_of_sale, color: Color(0xFF0066CC), size: 24),
                const SizedBox(width: 8),
                const Text('Point of Sale',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                if (_selectedShiftId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84CC16).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF84CC16).withAlpha(60)),
                    ),
                    child: Text('Shift: ${_selectedShiftId!.substring(0, 6).toUpperCase()}',
                        style: const TextStyle(color: Color(0xFF84CC16), fontSize: 11)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
                    ),
                    child: const Text('No open shift',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
                  ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
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
              controller: _tabController,
              children: [
                _buildFuelTab(),
                _buildProductTab(false),
                _buildProductTab(true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // FUEL TAB
  // ──────────────────────────────────────────────

  Widget _buildFuelTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('gas_types').where('isDeleted', isEqualTo: false).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final gasTypes = snap.data!.docs
            .map((d) => GasType.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        final selectedGasType = gasTypes.where((g) => g.id == _selectedGasTypeId).firstOrNull;
        final volume = double.tryParse(_volumeController.text) ?? 0;
        final computedPrice = selectedGasType != null ? volume * selectedGasType.priceOut : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fuel Type', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGasTypeId,
                dropdownColor: const Color(0xFF0B1220),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0B1220),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                hint: const Text('Select fuel type', style: TextStyle(color: Colors.white38)),
                items: gasTypes.map((g) {
                  return DropdownMenuItem(
                    value: g.id,
                    child: Text('${g.name} — ${g.priceOut.toStringAsFixed(2)} DA/L'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedGasTypeId = val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _volumeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Volume (Liters)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0B1220),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
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
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('${computedPrice.toStringAsFixed(2)} DA',
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
                      controller: _driverNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Driver Name (optional)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0B1220),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _vehiclePlateController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Vehicle Plate (optional)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0B1220),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
                  onPressed: (_selectedGasTypeId != null && volume > 0)
                      ? () => _addFuelItem(
                            selectedGasType!,
                            volume,
                            _driverNameController.text,
                            _vehiclePlateController.text,
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

  // ──────────────────────────────────────────────
  // PRODUCTS / SERVICES TAB
  // ──────────────────────────────────────────────

  Widget _buildProductTab(bool isService) {
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0066CC)));
        }
        final products = snap.data!.docs
            .map((d) => Product.fromMap(d.data() as Map<String, dynamic>))
            .where((p) => isService ? p.category == 'service' : (p.category == null || p.category != 'service'))
            .where((p) => p.isActive)
            .toList();

        final selectedProduct = products.where((p) => p.id == _selectedProductId).firstOrNull;
        final qty = double.tryParse(_quantityController.text) ?? 1;
        final computedPrice = selectedProduct != null ? qty * selectedProduct.price : 0.0;

        return Column(
          children: [
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isService ? Icons.design_services : Icons.inventory_2,
                              size: 48, color: Colors.white24),
                          const SizedBox(height: 8),
                          Text(isService ? 'No services configured' : 'No products found',
                              style: const TextStyle(color: Colors.white38)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (ctx, idx) {
                        final p = products[idx];
                        final isSelected = _selectedProductId == p.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedProductId = p.id;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0066CC).withAlpha(30) : const Color(0xFF0B1220),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0066CC) : Colors.white12,
                              ),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.name,
                                    style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${p.price.toStringAsFixed(2)} DA',
                                    style: TextStyle(
                                        color: isSelected ? const Color(0xFF84CC16) : Colors.white54,
                                        fontSize: 12)),
                                if (p.stockQuantity > 0)
                                  Text('Stock: ${p.stockQuantity.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    Text('${selectedProduct.name}: ',
                        style: const TextStyle(color: Colors.white70)),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Qty',
                          labelStyle: TextStyle(color: Colors.white54),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('= ${computedPrice.toStringAsFixed(2)} DA',
                        style: const TextStyle(
                            color: Color(0xFF84CC16), fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _addProductItem(selectedProduct, qty),
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

  // ──────────────────────────────────────────────
  // CART PANEL
  // ──────────────────────────────────────────────

  Widget _buildCartPanel() {
    final subtotal = _cart.fold<double>(0, (total, item) => total + item.lineTotal);

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
                Text('Cart (${_cart.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: _cart.isEmpty
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
                    itemCount: _cart.length,
                    itemBuilder: (ctx, idx) {
                      final item = _cart[idx];
                      return Dismissible(
                        key: ValueKey('${item.saleType.value}_$idx'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: const Color(0xFFEF4444),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeCartItem(idx),
                        child: Card(
                          color: const Color(0xFF0B1220),
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              item.saleType == SaleType.fuel
                                  ? Icons.local_gas_station
                                  : item.saleType == SaleType.service
                                      ? Icons.build
                                      : Icons.inventory_2,
                              size: 20,
                              color: item.saleType == SaleType.fuel
                                  ? const Color(0xFF84CC16)
                                  : const Color(0xFF0066CC),
                            ),
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
                        value: _selectedClientId,
                        dropdownColor: const Color(0xFF0B1220),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Client (optional)',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        onChanged: (val) => setState(() => _selectedClientId = val),
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
                        value: _selectedPaymentTypeId,
                        dropdownColor: const Color(0xFF0B1220),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Payment Method *',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                        ),
                        items: types.map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name, style: const TextStyle(fontSize: 13)),
                            )).toList(),
                        onChanged: (val) => setState(() => _selectedPaymentTypeId = val),
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
                        const Text('Total', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                        onPressed: (_cart.isNotEmpty && _selectedPaymentTypeId != null && !_isSubmitting)
                            ? _submitSale
                            : null,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.payment, size: 18),
                        label: Text(_isSubmitting ? 'Saving...' : 'Pay ${subtotal.toStringAsFixed(2)} DA'),
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
