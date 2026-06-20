import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/work_shift.dart';
import '../../domain/entities/shift_pump.dart';
import '../../domain/repositories/shift_repository.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  ShiftRepositoryImpl._();
  static final _instance = ShiftRepositoryImpl._();
  factory ShiftRepositoryImpl() => _instance;

  @override
  Future<WorkShift> createShift(WorkShift shift) async {
    final ref =
        firestore.collection(FirestorePaths.workShifts).doc(shift.id);
    await ref.set(shift.toMap());
    return shift;
  }

  @override
  Future<void> closeShift({
    required String shiftId,
    required double actualCash,
    required Map<String, double> endAnalogCounters,
  }) async {
    final batch = firestore.batch();

    final shiftRef =
        firestore.collection(FirestorePaths.workShifts).doc(shiftId);
    batch.update(shiftRef, {
      'status': 'CLOSED',
      'endTime': Timestamp.fromDate(DateTime.now()),
      'actualCash': actualCash,
    });

    final shiftPumpsSnap = await firestore
        .collection(FirestorePaths.shiftPumps)
        .where('shiftId', isEqualTo: shiftId)
        .get();

    for (final doc in shiftPumpsSnap.docs) {
      final pumpId = doc.data()['pumpId'] as String? ?? '';
      final endCounter = endAnalogCounters[pumpId];
      if (endCounter != null) {
        batch.update(doc.reference, {'endAnalogCounter': endCounter});
      }
    }

    await batch.commit();
  }

  @override
  Stream<List<WorkShift>> watchActiveShifts() {
    return firestore
        .collection(FirestorePaths.workShifts)
        .where('status', isEqualTo: 'OPEN')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => WorkShift.fromMap(d.data())).toList(),
        );
  }

  @override
  Stream<List<WorkShift>> watchAllShifts() {
    return firestore
        .collection(FirestorePaths.workShifts)
        .where('isDeleted', isEqualTo: false)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => WorkShift.fromMap(d.data())).toList(),
        );
  }

  @override
  Future<List<ShiftPump>> getShiftPumps(String shiftId) async {
    final snap = await firestore
        .collection(FirestorePaths.shiftPumps)
        .where('shiftId', isEqualTo: shiftId)
        .get();
    return snap.docs.map((d) => ShiftPump.fromMap(d.data())).toList();
  }

  @override
  Future<Map<String, double>> deriveChainData(String shiftId) async {
    final shiftPumpsSnap = await firestore
        .collection(FirestorePaths.shiftPumps)
        .where('shiftId', isEqualTo: shiftId)
        .get();

    final sorted = shiftPumpsSnap.docs
        .map((d) => ShiftPump.fromMap(d.data()))
        .toList()
      ..sort((a, b) {
        final cmp = a.pumpId.compareTo(b.pumpId);
        if (cmp != 0) return cmp;
        return a.startAnalogCounter.compareTo(b.startAnalogCounter);
      });

    final result = <String, double>{};

    for (final sp in sorted) {
      double previousEndAnalogCounter = 0;

      final prevShiftPumpsSnap = await firestore
          .collection(FirestorePaths.shiftPumps)
          .where('pumpId', isEqualTo: sp.pumpId)
          .where('shiftId', isNotEqualTo: shiftId)
          .orderBy('shiftId')
          .get();

      if (prevShiftPumpsSnap.docs.isNotEmpty) {
        final lastDoc = prevShiftPumpsSnap.docs.last;
        final lastSp = ShiftPump.fromMap(lastDoc.data());
        previousEndAnalogCounter = lastSp.endAnalogCounter ?? 0;
      } else {
        final pumpDoc = await firestore
            .collection(FirestorePaths.pumps)
            .doc(sp.pumpId)
            .get();
        if (pumpDoc.exists) {
          previousEndAnalogCounter =
              (pumpDoc.data()?['initialAnalogCounter'] as num?)?.toDouble() ??
                  0;
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
    final shiftPumpsSnap = await firestore
        .collection(FirestorePaths.shiftPumps)
        .where('shiftId', isEqualTo: shiftId)
        .get();

    final shiftPumps = shiftPumpsSnap.docs
        .map((d) => ShiftPump.fromMap(d.data()))
        .toList()
      ..sort((a, b) => a.pumpId.compareTo(b.pumpId));

    for (final sp in shiftPumps) {
      double previousEndAnalogCounter = 0;

      final prevSnap = await firestore
          .collection(FirestorePaths.shiftPumps)
          .where('pumpId', isEqualTo: sp.pumpId)
          .where('shiftId', isNotEqualTo: shiftId)
          .orderBy('shiftId')
          .get();

      if (prevSnap.docs.isNotEmpty) {
        final lastSp = ShiftPump.fromMap(prevSnap.docs.last.data());
        previousEndAnalogCounter = lastSp.endAnalogCounter ?? 0;
      } else {
        final pumpDoc = await firestore
            .collection(FirestorePaths.pumps)
            .doc(sp.pumpId)
            .get();
        if (pumpDoc.exists) {
          previousEndAnalogCounter =
              (pumpDoc.data()?['initialAnalogCounter'] as num?)?.toDouble() ??
                  0;
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

final shiftRepository = ShiftRepositoryImpl();
