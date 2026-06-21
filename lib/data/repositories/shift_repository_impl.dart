import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/datasource/database_datasource.dart';
import '../../domain/entities/work_shift.dart';
import '../../domain/entities/shift_pump.dart';
import '../../domain/repositories/shift_repository.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final DatabaseDataSource _ds;

  ShiftRepositoryImpl(this._ds);

  @override
  Future<WorkShift> createShift(WorkShift shift) async {
    await _ds.setDoc(FirestorePaths.workShifts, shift.id, shift.toMap());
    return shift;
  }

  @override
  Future<void> closeShift({
    required String shiftId,
    required double actualCash,
    required Map<String, double> endAnalogCounters,
  }) async {
    final batch = _ds.batch();

    final shiftRef = _ds.docRef(FirestorePaths.workShifts, shiftId);
    batch.update(shiftRef, {
      'status': 'CLOSED',
      'endTime': Timestamp.fromDate(DateTime.now()),
      'actualCash': actualCash,
    });

    final shiftPumpsSnap = await _ds.queryMulti(
      FirestorePaths.shiftPumps,
      filters: [QueryFilter(field: 'shiftId', value: shiftId)],
    );

    for (final doc in shiftPumpsSnap.docs) {
      final docData = doc.data() as Map<String, dynamic>;
      final pumpId = docData['pumpId'] as String? ?? '';
      final endCounter = endAnalogCounters[pumpId];
      if (endCounter != null) {
        batch.update(doc.reference, {'endAnalogCounter': endCounter});
      }
    }

    await batch.commit();
  }

  @override
  Stream<List<WorkShift>> watchActiveShifts() {
    return _ds.streamQueryMulti(
      FirestorePaths.workShifts,
      filters: [
        QueryFilter(field: 'status', value: 'OPEN'),
        QueryFilter(field: 'isDeleted', value: false),
      ],
    ).map(
      (snap) => snap.docs
          .map((d) =>
              WorkShift.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id)))
          .toList(),
    );
  }

  @override
  Stream<List<WorkShift>> watchAllShifts() {
    return _ds.streamQueryMulti(
      FirestorePaths.workShifts,
      filters: [QueryFilter(field: 'isDeleted', value: false)],
      orderByField: 'startTime',
      orderByDescending: true,
    ).map(
      (snap) => snap.docs
          .map((d) =>
              WorkShift.fromMap(d.data() as Map<String, dynamic>..putIfAbsent('id', () => d.id)))
          .toList(),
    );
  }

  @override
  Future<List<ShiftPump>> getShiftPumps(String shiftId) async {
    final snap = await _ds.queryMulti(
      FirestorePaths.shiftPumps,
      filters: [QueryFilter(field: 'shiftId', value: shiftId)],
    );
    return snap.docs
        .map((d) => ShiftPump.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, double>> deriveChainData(String shiftId) async {
    final shiftPumpsSnap = await _ds.queryMulti(
      FirestorePaths.shiftPumps,
      filters: [QueryFilter(field: 'shiftId', value: shiftId)],
    );

    final sorted = shiftPumpsSnap.docs
        .map((d) => ShiftPump.fromMap(d.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) {
        final cmp = a.pumpId.compareTo(b.pumpId);
        if (cmp != 0) return cmp;
        return a.startAnalogCounter.compareTo(b.startAnalogCounter);
      });

    final result = <String, double>{};

    for (final sp in sorted) {
      double previousEndAnalogCounter = 0;

      final prevShiftPumpsSnap = await _ds.queryMulti(
        FirestorePaths.shiftPumps,
        filters: [
          QueryFilter(field: 'pumpId', value: sp.pumpId),
          QueryFilter(field: 'shiftId', value: shiftId, operator: FilterOperator.isNotEqualTo),
        ],
        orderByField: 'shiftId',
      );

      if (prevShiftPumpsSnap.docs.isNotEmpty) {
        final lastDoc = prevShiftPumpsSnap.docs.last;
        final lastSp = ShiftPump.fromMap(lastDoc.data() as Map<String, dynamic>);
        previousEndAnalogCounter = lastSp.endAnalogCounter ?? 0;
      } else {
        final pumpDoc = await _ds.getDoc(FirestorePaths.pumps, sp.pumpId);
        if (pumpDoc.exists) {
          final pumpData = pumpDoc.data() as Map<String, dynamic>?;
          previousEndAnalogCounter =
              (pumpData?['initialAnalogCounter'] as num?)?.toDouble() ?? 0;
        }
      }

      final endCounter = sp.endAnalogCounter ?? sp.startAnalogCounter;
      final volume = (endCounter - previousEndAnalogCounter).clamp(0, 999999).toDouble();
      result[sp.pumpId] = volume;
    }

    return result;
  }

  @override
  Future<bool> verifyChain(String shiftId) async {
    final shiftPumpsSnap = await _ds.queryMulti(
      FirestorePaths.shiftPumps,
      filters: [QueryFilter(field: 'shiftId', value: shiftId)],
    );

    final shiftPumps = shiftPumpsSnap.docs
        .map((d) => ShiftPump.fromMap(d.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.pumpId.compareTo(b.pumpId));

    for (final sp in shiftPumps) {
      double previousEndAnalogCounter = 0;

      final prevSnap = await _ds.queryMulti(
        FirestorePaths.shiftPumps,
        filters: [
          QueryFilter(field: 'pumpId', value: sp.pumpId),
          QueryFilter(field: 'shiftId', value: shiftId, operator: FilterOperator.isNotEqualTo),
        ],
        orderByField: 'shiftId',
      );

      if (prevSnap.docs.isNotEmpty) {
        final lastSp = ShiftPump.fromMap(prevSnap.docs.last.data() as Map<String, dynamic>);
        previousEndAnalogCounter = lastSp.endAnalogCounter ?? 0;
      } else {
        final pumpDoc = await _ds.getDoc(FirestorePaths.pumps, sp.pumpId);
        if (pumpDoc.exists) {
          final pumpData = pumpDoc.data() as Map<String, dynamic>?;
          previousEndAnalogCounter =
              (pumpData?['initialAnalogCounter'] as num?)?.toDouble() ?? 0;
        }
      }

      final endCounter = sp.endAnalogCounter ?? sp.startAnalogCounter;
      if (endCounter < previousEndAnalogCounter) {
        return false;
      }

      if (sp.endAnalogCounter == null) {
        return false;
      }
    }

    return true;
  }
}
