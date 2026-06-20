import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import '../../data/firestore/firestore_provider.dart';

class ImportService {
  /// Imports data from Excel bytes into Firestore.
  /// Returns a summary of the import results.
  Future<Map<String, int>> importExcel(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final Map<String, int> results = {};
    
    // Process sheets in order of dependencies
    await _importUsers(excel, results);
    await _importClients(excel, results);
    await _importGasTypes(excel, results);
    await _importPumps(excel, results);
    await _importPits(excel, results);
    await _importShifts(excel, results);
    await _importShiftPumps(excel, results);
    await _importSales(excel, results);
    await _importPayments(excel, results);
    await _importExpenses(excel, results);
    
    return results;
  }

  Future<void> _importUsers(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['Workers'];
    if (sheet == null) return;
    
    int count = 0;
    final rows = sheet.rows.skip(1); // Skip header
    for (final row in rows) {
      final data = row.map((c) => c?.value).toList();
      if (data.length < 11) continue;
      
      final id = data[4]?.toString() ?? '';
      if (id.isEmpty) continue;
      
      await firestore.collection('users').doc(id).set({
        'id': id,
        'fullName': data[2]?.toString() ?? '',
        'role': data[7]?.toString() ?? 'Worker',
        'is_active': data[4]?.toString() == 'TRUE',
        'monthly_salary': (data[5] as num?)?.toDouble() ?? 0.0,
        'createdAt': Timestamp.fromDate(DateTime.parse(data[9]?.toString() ?? DateTime.now().toString())),
        'updated': Timestamp.fromDate(DateTime.parse(data[8]?.toString() ?? DateTime.now().toString())),
      }, SetOptions(merge: true));
      count++;
    }
    results['users'] = count;
  }

  Future<void> _importClients(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['Clients'];
    if (sheet == null) return;
    
    int count = 0;
    for (final row in sheet.rows.skip(1)) {
      final data = row.map((c) => c?.value).toList();
      if (data.length < 9) continue;
      
      final id = data[4]?.toString() ?? '';
      if (id.isEmpty) continue;
      
      await firestore.collection('clients').doc(id).set({
        'id': id,
        'name': data[6]?.toString() ?? '',
        'address': data[0]?.toString() ?? '',
        'phone': data[7]?.toString() ?? '',
        'currentBalance': (data[2] as num?)?.toDouble() ?? 0.0,
        'creditLimit': (data[1] as num?)?.toDouble() ?? 0.0,
        'is_deleted': data[5]?.toString() == 'TRUE',
      }, SetOptions(merge: true));
      count++;
    }
    results['clients'] = count;
  }

  Future<void> _importGasTypes(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['Fuel Types'];
    if (sheet == null) return;
    
    int count = 0;
    for (final row in sheet.rows.skip(1)) {
      final data = row.map((c) => c?.value).toList();
      if (data.length < 10) continue;
      
      final id = data[4]?.toString() ?? '';
      if (id.isEmpty) continue;
      
      await firestore.collection('gas_types').doc(id).set({
        'id': id,
        'name': data[5]?.toString() ?? '',
        'priceIn': (data[6] as num?)?.toDouble() ?? 0.0,
        'priceOut': (data[7] as num?)?.toDouble() ?? 0.0,
        'color': data[8]?.toString() ?? '#3b82f6',
        'is_deleted': data[9]?.toString() == 'TRUE',
        'createdAt': Timestamp.fromDate(DateTime.parse(data[10]?.toString() ?? DateTime.now().toString())),
        'updatedAt': Timestamp.fromDate(DateTime.parse(data[11]?.toString() ?? DateTime.now().toString())),
      }, SetOptions(merge: true));
      count++;
    }
    results['gas_types'] = count;
  }

  Future<void> _importPumps(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['Pumps'];
    if (sheet == null) return;
    
    int count = 0;
    for (final row in sheet.rows.skip(1)) {
      final data = row.map((c) => c?.value).toList();
      if (data.length < 14) continue;
      
      final id = data[6]?.toString() ?? '';
      if (id.isEmpty) continue;
      
      await firestore.collection('pumps').doc(id).set({
        'id': id,
        'name': data[10]?.toString() ?? '',
        'isActive': data[8]?.toString() == 'TRUE',
        'initialAnalogCounter': (data[7] as num?)?.toDouble() ?? 0.0,
        'groupId': data[5]?.toString(),
        'subgroup': data[12]?.toString(),
        'color': data[2]?.toString() ?? '#22c55e',
        'pitId': data[11]?.toString() ?? '',
        'is_deleted': data[9]?.toString() == 'TRUE',
      }, SetOptions(merge: true));
      count++;
    }
    results['pumps'] = count;
  }

  Future<void> _importPits(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['Pits'];
    if (sheet == null) return;
    
    int count = 0;
    for (final row in sheet.rows.skip(1)) {
      final data = row.map((c) => c?.value).toList();
      if (data.length < 11) continue;
      
      final id = data[7]?.toString() ?? '';
      if (id.isEmpty) continue;
      
      await firestore.collection('pits').doc(id).set({
        'id': id,
        'name': data[9]?.toString() ?? '',
        'capacity': (data[0] as num?)?.toDouble() ?? 0.0,
        'currentVolume': (data[4] as num?)?.toDouble() ?? 0.0,
        'gasTypeId': data[6]?.toString(),
        'is_deleted': data[8]?.toString() == 'TRUE',
      }, SetOptions(merge: true));
      count++;
    }
    results['pits'] = count;
  }

  Future<void> _importShifts(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['Shifts'];
    if (sheet == null) return;
    
    int count = 0;
    for (final row in sheet.rows.skip(1)) {
      final data = row.map((c) => c?.value).toList();
      if (data.length < 11) continue;
      
      final id = data[6]?.toString() ?? '';
      if (id.isEmpty) continue;
      
      await firestore.collection('work_shifts').doc(id).set({
        'id': id,
        'workerId': data[9]?.toString() ?? '',
        'startTime': Timestamp.fromDate(DateTime.parse(data[3]?.toString() ?? DateTime.now().toString())),
        'endTime': data[4] != null ? Timestamp.fromDate(DateTime.parse(data[4].toString())) : null,
        'status': data[7]?.toString() ?? 'CLOSED',
        'actualCash': (data[0] as num?)?.toDouble(),
        'expectedCash': null,
        'createdAt': Timestamp.fromDate(DateTime.parse(data[3]?.toString() ?? DateTime.now().toString())),
        'isDeleted': false,
      }, SetOptions(merge: true));
      count++;
    }
    results['work_shifts'] = count;
  }

  Future<void> _importShiftPumps(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['shift_pumps'];
    if (sheet == null) return;
    
    final rows = sheet.rows;
    if (rows.isEmpty) return;
    
    final header = rows.first.map((c) => c?.value?.toString()).toList();
    
    int count = 0;
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final pumpName = row[0]?.value?.toString() ?? '';
      if (pumpName.isEmpty) continue;
      
      // Map pump name to pumpId
      final pumpSnap = await firestore.collection('pumps').where('name', isEqualTo: pumpName).limit(1).get();
      if (pumpSnap.docs.isEmpty) continue;
      final pumpId = pumpSnap.docs.first.id;
      
      for (var j = 1; j < row.length; j++) {
        final shiftId = header[j]?.toString();
        if (shiftId == null) continue;
        
        final val = row[j]?.value;
        if (val == null) continue;
        final counter = (val as num?)?.toDouble() ?? 0.0;
        
        // In this matrix, values are analog counters. 
        // We need to determine if it's start or end.
        // Simplified logic: use the value as startAnalogCounter for this shift.
        // In a real import, we'd check the shift's time vs the counter's time.
        // Since the data is a matrix, we'll just write it.
        
        final spId = firestore.collection('shift_pumps').doc().id;
        await firestore.collection('shift_pumps').doc(spId).set({
          'id': spId,
          'shiftId': shiftId,
          'pumpId': pumpId,
          'startAnalogCounter': counter,
          'endAnalogCounter': null,
          'volume': 0,
          'revenue': 0,
        });
        count++;
      }
    }
    results['shift_pumps'] = count;
  }

  Future<void> _importSales(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['Sales'];
    if (sheet == null) return;
    
    int count = 0;
    final rows = sheet.rows.skip(1);
    for (final row in rows) {
      final data = row.map((c) => c?.value).toList();
      if (data.length < 22) continue;
      
      final saleId = data[8]?.toString() ?? '';
      if (saleId.isEmpty) continue;
      
      // 1. Sale Header
      await firestore.collection('sales').doc(saleId).set({
        'id': saleId,
        'clientId': data[0]?.toString(),
        'workerId': data[21]?.toString(),
        'paymentTypeId': data[10]?.toString(),
        'totalAmount': (data[16] as num?)?.toDouble() ?? 0.0,
        'notes': data[9]?.toString(),
        'timestamp': Timestamp.fromDate(DateTime.parse(data[15]?.toString() ?? DateTime.now().toString())),
        'isDeleted': false,
        'createdAt': Timestamp.fromDate(DateTime.parse(data[3]?.toString() ?? DateTime.now().toString())),
      }, SetOptions(merge: true));
      
      // 2. Sale Item
      final spId = firestore.collection('sale_items').doc().id;
      await firestore.collection('sale_items').doc(spId).set({
        'id': spId,
        'saleId': saleId,
        'saleType': (data[12]?.toString() == 'FUEL') ? 'FUEL' : 'PRODUCT',
        'gasTypeId': data[7]?.toString(),
        'productId': data[11]?.toString(),
        'volume': (data[20] as num?)?.toDouble(),
        'unitPrice': (data[17] as num?)?.toDouble() ?? 0.0,
        'lineTotal': (data[16] as num?)?.toDouble() ?? 0.0,
        'quantity': (data[20] as num?)?.toDouble() ?? 1.0,
        'driverName': data[4]?.toString(),
        'vehiclePlate': data[19]?.toString(),
        'notes': data[9]?.toString(),
        'timestamp': Timestamp.fromDate(DateTime.parse(data[15]?.toString() ?? DateTime.now().toString())),
      });
      count++;
    }
    results['sales'] = count;
  }

  Future<void> _importPayments(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['Payments'];
    if (sheet == null) return;
    
    int count = 0;
    for (final row in sheet.rows.skip(1)) {
      final data = row.map((c) => c?.value).toList();
      if (data.length < 18) continue;
      
      final id = data[10]?.toString() ?? '';
      if (id.isEmpty) continue;
      
      await firestore.collection('payments').doc(id).set({
        'id': id,
        'amount': (data[0] as num?)?.toDouble() ?? 0.0,
        'clientId': data[4]?.toString() ?? '',
        'paymentTypeId': data[13]?.toString() ?? '',
        'saleId': data[15]?.toString(),
        'status': data[16]?.toString() ?? 'COMPLETED',
        'notes': data[12]?.toString() ?? '',
        'createdAt': Timestamp.fromDate(DateTime.parse(data[7]?.toString() ?? DateTime.now().toString())),
      }, SetOptions(merge: true));
      count++;
    }
    results['payments'] = count;
  }

  Future<void> _importExpenses(Excel excel, Map<String, int> results) async {
    final sheet = excel.tables['Expenses'];
    if (sheet == null) return;
    
    int count = 0;
    for (final row in sheet.rows.skip(1)) {
      final data = row.map((c) => c?.value).toList();
      if (data.length < 12) continue;
      
      final id = data[7]?.toString() ?? '';
      if (id.isEmpty) continue;
      
      await firestore.collection('expenses').doc(id).set({
        'id': id,
        'amount': (data[0] as num?)?.toDouble() ?? 0.0,
        'category': data[1]?.toString() ?? '',
        'description': data[5]?.toString() ?? '',
        'recordedBy': data[9]?.toString() ?? '',
        'timestamp': Timestamp.fromDate(DateTime.parse(data[10]?.toString() ?? DateTime.now().toString())),
      }, SetOptions(merge: true));
      count++;
    }
    results['expenses'] = count;
  }
}
