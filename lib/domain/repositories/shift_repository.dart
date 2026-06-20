import '../entities/work_shift.dart';
import '../entities/shift_pump.dart';

abstract class ShiftRepository {
  Future<WorkShift> createShift(WorkShift shift);
  Future<void> closeShift({
    required String shiftId,
    required double actualCash,
    required Map<String, double> endAnalogCounters,
  });

  Stream<List<WorkShift>> watchActiveShifts();
  Stream<List<WorkShift>> watchAllShifts();

  Future<List<ShiftPump>> getShiftPumps(String shiftId);

  Future<Map<String, double>> deriveChainData(String shiftId);
  Future<bool> verifyChain(String shiftId);
}
