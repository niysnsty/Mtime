import 'package:hive/hive.dart';

part 'cycle_model.g.dart';

@HiveType(typeId: 1)
class CycleModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final DateTime startDate;
  
  @HiveField(3)
  final DateTime? endDate;
  
  @HiveField(4)
  final int duration; // In days

  @HiveField(5)
  final String status; // 'Haid', 'Masa Subur', 'Normal'

  CycleModel({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.duration = 28,
    this.status = 'Normal',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'duration': duration,
      'status': status,
    };
  }

  factory CycleModel.fromMap(Map<String, dynamic> map) {
    return CycleModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      duration: map['duration'] ?? 28,
      status: map['status'] ?? 'Normal',
    );
  }
}
