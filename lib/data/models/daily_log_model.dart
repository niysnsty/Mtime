import 'package:hive/hive.dart';

part 'daily_log_model.g.dart';

@HiveType(typeId: 2)
class DailyLogModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String cycleId;
  
  @HiveField(2)
  final DateTime date;
  
  @HiveField(3)
  final String mood;
  
  @HiveField(4)
  final List<String> physicalSymptoms;
  
  @HiveField(5)
  final String? notes;

  DailyLogModel({
    required this.id,
    required this.cycleId,
    required this.date,
    this.mood = 'Neutral',
    this.physicalSymptoms = const [],
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycleId': cycleId,
      'date': date.toIso8601String(),
      'mood': mood,
      'physicalSymptoms': physicalSymptoms,
      'notes': notes,
    };
  }

  factory DailyLogModel.fromMap(Map<String, dynamic> map) {
    return DailyLogModel(
      id: map['id'] ?? '',
      cycleId: map['cycleId'] ?? '',
      date: DateTime.parse(map['date']),
      mood: map['mood'] ?? 'Neutral',
      physicalSymptoms: List<String>.from(map['physicalSymptoms'] ?? []),
      notes: map['notes'],
    );
  }
}
