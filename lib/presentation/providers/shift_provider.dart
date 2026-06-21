import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/work_shift.dart';
import 'repository_providers.dart';

final activeShiftsProvider = StreamProvider<List<WorkShift>>((ref) {
  return ref.watch(shiftRepositoryProvider).watchActiveShifts();
});

final allShiftsProvider = StreamProvider<List<WorkShift>>((ref) {
  return ref.watch(shiftRepositoryProvider).watchAllShifts();
});
