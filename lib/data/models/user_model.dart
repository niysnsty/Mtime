import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final int averageCycleLength;
  
  @HiveField(4)
  final DateTime? lastPeriodDate;
  
  @HiveField(5)
  final bool notificationsEnabled;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.averageCycleLength = 28,
    this.lastPeriodDate,
    this.notificationsEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'averageCycleLength': averageCycleLength,
      'lastPeriodDate': lastPeriodDate?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['uid'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      averageCycleLength: map['averageCycleLength'] ?? 28,
      lastPeriodDate: map['lastPeriodDate'] != null ? DateTime.parse(map['lastPeriodDate']) : null,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }
}
