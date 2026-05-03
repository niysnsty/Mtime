import '../models/cycle_model.dart';
import '../models/daily_log_model.dart';

abstract class CycleRepository {
  Future<List<CycleModel>> getCycles(String userId);
  Future<void> addCycle(CycleModel cycle);
  Future<void> updateCycle(CycleModel cycle);
  Future<void> deleteCycle(String cycleId);

  Future<List<DailyLogModel>> getDailyLogs(String cycleId);
  Future<void> addDailyLog(DailyLogModel log);
  Future<void> updateDailyLog(DailyLogModel log);
}
