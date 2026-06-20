import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ss_fluttered/domain/entities/sale.dart';
import 'package:ss_fluttered/domain/entities/work_shift.dart';
import 'package:ss_fluttered/domain/entities/pit.dart';
import 'package:ss_fluttered/domain/entities/pump.dart';
import 'package:ss_fluttered/domain/entities/product.dart';
import 'package:ss_fluttered/domain/enums/sale_type.dart';
import 'package:ss_fluttered/domain/enums/shift_status.dart';

void main() {
  group('Sale entity', () {
    test('fromMap creates Sale with correct values', () {
      final now = Timestamp.now();
      final map = <String, dynamic>{
        'id': 'sale_001',
        'saleType': 'FUEL',
        'totalPrice': 150.50,
        'paymentTypeId': 'cash',
        'clientId': 'client_001',
        'shiftId': 'shift_001',
        'notes': 'Test sale',
        'isDeleted': false,
        'timestamp': now,
        'createdAt': now,
      };

      final sale = Sale.fromMap(map);
      expect(sale.id, 'sale_001');
      expect(sale.totalPrice, 150.50);
      expect(sale.paymentTypeId, 'cash');
      expect(sale.clientId, 'client_001');
      expect(sale.isDeleted, false);
    });

    test('fromMap with empty map uses safe defaults', () {
      final map = <String, dynamic>{};
      final sale = Sale.fromMap(map);
      expect(sale.id, '');
      expect(sale.totalPrice, 0.0);
      expect(sale.paymentTypeId, null);
      expect(sale.isDeleted, false);
    });

    test('toMap preserves Sale fields', () {
      final now = DateTime.now();
      final sale = Sale(
        id: 'sale_002',
        saleType: SaleType.fuel,
        totalPrice: 200.0,
        timestamp: now,
        createdAt: now,
        shiftId: 'shift_002',
      );

      final map = sale.toMap();
      expect(map['id'], 'sale_002');
      expect(map['totalPrice'], 200.0);
      expect(map['saleType'], 'FUEL');
      expect(map['isDeleted'], false);
    });
  });

  group('WorkShift entity', () {
    test('fromMap creates WorkShift with correct values', () {
      final now = Timestamp.now();
      final map = <String, dynamic>{
        'id': 'shift_001',
        'workerId': 'worker_001',
        'status': 'OPEN',
        'startTime': now,
        'endTime': now,
        'expectedCash': 5000.0,
        'isDeleted': false,
      };

      final shift = WorkShift.fromMap(map);
      expect(shift.workerId, 'worker_001');
      expect(shift.status, ShiftStatus.open);
      expect(shift.expectedCash, 5000.0);
      expect(shift.isDeleted, false);
    });

    test('fromMap defaults status to CLOSED', () {
      final map = <String, dynamic>{};
      final shift = WorkShift.fromMap(map);
      expect(shift.status, ShiftStatus.closed);
    });
  });

  group('Pit entity', () {
    test('fromMap creates Pit with correct values', () {
      final map = <String, dynamic>{
        'id': 'pit_001',
        'name': 'Pit A',
        'capacity': 20000,
        'currentVolume': 15000,
        'gasTypeId': 'gas_001',
        'isDeleted': false,
      };

      final pit = Pit.fromMap(map);
      expect(pit.name, 'Pit A');
      expect(pit.capacity, 20000);
      expect(pit.currentVolume, 15000);
      expect(pit.gasTypeId, 'gas_001');
      expect(pit.isDeleted, false);
    });
  });

  group('Pump entity', () {
    test('fromMap creates Pump with correct values', () {
      final map = <String, dynamic>{
        'id': 'pump_001',
        'name': 'Pump 1',
        'pitId': 'pit_001',
        'isDeleted': false,
      };

      final pump = Pump.fromMap(map);
      expect(pump.name, 'Pump 1');
      expect(pump.pitId, 'pit_001');
    });
  });

  group('Product entity', () {
    test('fromMap creates Product with correct values', () {
      final map = <String, dynamic>{
        'id': 'prod_001',
        'name': 'Engine Oil',
        'price': 45.00,
        'stockQuantity': 100.0,
        'category': 'product',
        'isActive': true,
        'isDeleted': false,
      };

      final product = Product.fromMap(map);
      expect(product.name, 'Engine Oil');
      expect(product.price, 45.00);
      expect(product.stockQuantity, 100.0);
      expect(product.category, 'product');
    });
  });
}
