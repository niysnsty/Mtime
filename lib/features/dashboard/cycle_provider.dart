import 'package:flutter/material.dart';
import '../../core/logic/cycle_engine.dart';
import '../../data/models/cycle_model.dart';
import '../../data/models/daily_log_model.dart';
import '../../data/repositories/cycle_repository.dart';

class CycleProvider extends ChangeNotifier {
  final CycleRepository _cycleRepository;
  final String userId;

  List<CycleModel> _cycles = [];
  List<DailyLogModel> _currentCycleLogs = [];
  bool _isLoading = false;

  CycleProvider(this._cycleRepository, this.userId) {
    if (userId.isNotEmpty) {
      fetchData();
    }
  }

  List<CycleModel> get cycles => _cycles;
  List<DailyLogModel> get currentCycleLogs => _currentCycleLogs;
  bool get isLoading => _isLoading;

  CycleModel? get currentCycle {
    if (_cycles.isEmpty) return null;
    return _cycles.firstWhere((c) => c.endDate == null, orElse: () => _cycles.first);
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _cycles = await _cycleRepository.getCycles(userId);
      if (_cycles.isNotEmpty) {
        _currentCycleLogs = await _cycleRepository.getDailyLogs(_cycles.first.id);
      }
    } catch (e) {
      debugPrint('Error fetching cycle data: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> startNewCycle(DateTime startDate) async {
    final newCycle = CycleModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      startDate: startDate,
      status: 'Haid',
    );
    await _cycleRepository.addCycle(newCycle);
    await fetchData();
  }

  Future<void> addDailyLog(DailyLogModel log) async {
    await _cycleRepository.addDailyLog(log);
    await fetchData();
  }

  // Prediction Logic Helper
  Map<String, dynamic> getPrediction() {
    if (_cycles.isEmpty) {
      return {
        'status': 'No Data',
        'daysUntil': 0,
        'phase': 'Unknown',
      };
    }

    final lastCycle = _cycles.first;
    final avgLength = 28; // This should ideally come from UserModel or calculated from history
    
    final nextPeriod = CycleEngine.predictNextPeriod(lastCycle.startDate, avgLength);
    final daysUntil = CycleEngine.daysUntilNextPeriod(DateTime.now(), nextPeriod);
    final phase = CycleEngine.getCyclePhase(DateTime.now(), lastCycle.startDate, avgLength);

    return {
      'status': phase,
      'daysUntil': daysUntil,
      'phase': phase,
      'nextPeriod': nextPeriod,
    };
  }
}
