import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/firestore/firestore_provider.dart';
import '../../../domain/entities/gas_type.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/enums/sale_type.dart';
import '../widgets/pos_cart_item.dart';
import '../widgets/pos_cart_panel.dart';
import '../widgets/pos_item_selection_panel.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<PosCartItem> _cart = [];
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
      setState(() => _selectedShiftId = snap.docs.first.id);
    }
  }

  void _addFuelItem(GasType gasType, double volume, String driver, String plate) {
    setState(() {
      _cart.add(PosCartItem(
        saleType: SaleType.fuel,
        gasTypeId: gasType.id,
        label: '${gasType.name} — ${volume.toStringAsFixed(1)}L',
        unitPrice: gasType.priceOut,
        volume: volume,
        driverName: driver.isNotEmpty ? driver : null,
        vehiclePlate: plate.isNotEmpty ? plate : null,
      ));
      _selectedGasTypeId = null;
      _volumeController.clear();
      _driverNameController.clear();
      _vehiclePlateController.clear();
    });
  }

  void _addProductItem(Product product, double qty) {
    setState(() {
      _cart.add(PosCartItem(
        saleType: product.category == 'service' ? SaleType.service : SaleType.product,
        productId: product.id,
        label: '${product.name} x${qty.toStringAsFixed(0)}',
        unitPrice: product.price,
        quantity: qty,
      ));
      _selectedProductId = null;
      _quantityController.text = '1';
    });
  }

  void _removeCartItem(int index) => setState(() => _cart.removeAt(index));

  Future<void> _submitSale() async {
    if (_cart.isEmpty) return;
    if (_selectedPaymentTypeId == null) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Select a payment method'),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final totalPrice = _cart.fold<double>(0, (t, i) => t + i.lineTotal);
      final saleId = firestore.collection('sales').doc().id;

      await firestore.collection('sales').doc(saleId).set({
        'id': saleId,
        'shiftId': _selectedShiftId,
        'clientId': _selectedClientId,
        'workerId': null,
        'paymentTypeId': _selectedPaymentTypeId,
        'totalPrice': totalPrice,
        'notes': null,
        'timestamp': Timestamp.fromDate(now),
        'isDeleted': false,
        'createdAt': Timestamp.fromDate(now),
      });

      final batch = firestore.batch();
      for (final item in _cart) {
        final itemId = firestore.collection('sale_items').doc().id;
        batch.set(firestore.collection('sale_items').doc(itemId), {
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

      for (final item in _cart.where((i) => i.saleType == SaleType.fuel && i.gasTypeId != null)) {
        final pitsSnap = await firestore
            .collection('pits')
            .where('gasTypeId', isEqualTo: item.gasTypeId)
            .where('isDeleted', isEqualTo: false)
            .limit(1)
            .get();
        for (final pitDoc in pitsSnap.docs) {
          final currentVol = (pitDoc.data()['currentVolume'] as num?)?.toDouble() ?? 0;
          batch.update(pitDoc.reference, {
            'currentVolume': (currentVol - item.volume).clamp(0, double.infinity)
          });
        }
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _cart.clear();
          _selectedPaymentTypeId = null;
          _selectedClientId = null;
        });
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale recorded: ${totalPrice.toStringAsFixed(2)} DA'),
            backgroundColor: cs.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record sale: $e'),
            backgroundColor: cs.error,
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
        Expanded(flex: 3, child: _buildSelectionPanel()),
        const SizedBox(width: 16),
        SizedBox(width: 380, child: _buildCartPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(flex: 3, child: _buildSelectionPanel()),
        Divider(color: cs.onSurface.withValues(alpha: 0.12)),
        Expanded(flex: 2, child: _buildCartPanel()),
      ],
    );
  }

  Widget _buildSelectionPanel() {
    return PosItemSelectionPanel(
      tabController: _tabController,
      selectedShiftId: _selectedShiftId,
      selectedGasTypeId: _selectedGasTypeId,
      volumeController: _volumeController,
      driverNameController: _driverNameController,
      vehiclePlateController: _vehiclePlateController,
      selectedProductId: _selectedProductId,
      quantityController: _quantityController,
      onGasTypeChanged: (val) => setState(() => _selectedGasTypeId = val),
      onFuelChanged: () => setState(() {}),
      onAddFuelToCart: _addFuelItem,
      onProductSelected: (val) => setState(() => _selectedProductId = val),
      onProductChanged: () => setState(() {}),
      onAddProductToCart: _addProductItem,
    );
  }

  Widget _buildCartPanel() {
    return PosCartPanel(
      cart: _cart,
      selectedPaymentTypeId: _selectedPaymentTypeId,
      selectedClientId: _selectedClientId,
      isSubmitting: _isSubmitting,
      onRemoveItem: _removeCartItem,
      onPaymentTypeChanged: (val) => setState(() => _selectedPaymentTypeId = val),
      onClientChanged: (val) => setState(() => _selectedClientId = val),
      onSubmit: _submitSale,
    );
  }
}
