import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/work_shift.dart';
import '../../core/constants/firestore_paths.dart';

final activeShiftsProvider = StreamProvider<List<WorkShift>>((ref) {
  return firestore.collection(FirestorePaths.workShifts).where('status', isEqualTo: 'OPEN').snapshots().map(
    (snap) => snap.docs.map((d) => WorkShift.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

final allShiftsProvider = StreamProvider<List<WorkShift>>((ref) {
  return firestore.collection(FirestorePaths.workShifts).orderBy('startTime', descending: true).snapshots().map(
    (snap) => snap.docs.map((d) => WorkShift.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});
