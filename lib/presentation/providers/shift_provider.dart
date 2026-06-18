import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firestore/firestore_provider.dart';
import '../../domain/entities/work_shift.dart';

final activeShiftsProvider = StreamProvider<List<WorkShift>>((ref) {
  return firestore.collection('work_shifts').where('status', isEqualTo: 'OPEN').snapshots().map(
    (snap) => snap.docs.map((d) => WorkShift.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});

final allShiftsProvider = StreamProvider<List<WorkShift>>((ref) {
  return firestore.collection('work_shifts').orderBy('startTime', descending: true).snapshots().map(
    (snap) => snap.docs.map((d) => WorkShift.fromMap(d.data()..putIfAbsent('id', () => d.id))).toList(),
  );
});
