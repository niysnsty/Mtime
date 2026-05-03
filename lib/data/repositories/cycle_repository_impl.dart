import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cycle_model.dart';
import '../models/daily_log_model.dart';
import 'cycle_repository.dart';

class FirestoreCycleRepositoryImpl implements CycleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<CycleModel>> getCycles(String userId) async {
    final snapshot = await _firestore
        .collection('cycles')
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => CycleModel.fromMap(doc.data())).toList();
  }

  @override
  Future<void> addCycle(CycleModel cycle) async {
    await _firestore.collection('cycles').doc(cycle.id).set(cycle.toMap());
  }

  @override
  Future<void> updateCycle(CycleModel cycle) async {
    await _firestore.collection('cycles').doc(cycle.id).update(cycle.toMap());
  }

  @override
  Future<void> deleteCycle(String cycleId) async {
    await _firestore.collection('cycles').doc(cycleId).delete();
  }

  @override
  Future<List<DailyLogModel>> getDailyLogs(String cycleId) async {
    final snapshot = await _firestore
        .collection('daily_logs')
        .where('cycleId', isEqualTo: cycleId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => DailyLogModel.fromMap(doc.data())).toList();
  }

  @override
  Future<void> addDailyLog(DailyLogModel log) async {
    await _firestore.collection('daily_logs').doc(log.id).set(log.toMap());
  }

  @override
  Future<void> updateDailyLog(DailyLogModel log) async {
    await _firestore.collection('daily_logs').doc(log.id).update(log.toMap());
  }
}

class MockCycleRepositoryImpl implements CycleRepository {
  final List<CycleModel> _mockCycles = [
    CycleModel(
      id: 'c1', 
      userId: '1', 
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      status: 'Haid'
    ),
  ];

  @override
  Future<List<CycleModel>> getCycles(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockCycles;
  }

  @override
  Future<void> addCycle(CycleModel cycle) async {
    _mockCycles.add(cycle);
  }

  @override
  Future<void> updateCycle(CycleModel cycle) async {}
  @override
  Future<void> deleteCycle(String cycleId) async {}

  @override
  Future<List<DailyLogModel>> getDailyLogs(String cycleId) async {
    return [];
  }

  @override
  Future<void> addDailyLog(DailyLogModel log) async {}
  @override
  Future<void> updateDailyLog(DailyLogModel log) async {}
}
