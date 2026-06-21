import '../../../domain/enums/sale_type.dart';

/// A line item in the POS cart (view model, not a domain entity).
class PosCartItem {
  SaleType saleType;
  String? gasTypeId;
  String? productId;
  String label;
  double unitPrice;
  double quantity;
  double volume;
  String? driverName;
  String? vehiclePlate;

  PosCartItem({
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
