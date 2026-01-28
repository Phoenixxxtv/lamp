import '../../auth/models/user_profile.dart';
import 'habit.dart';

/// Habit assignment linking habit to protégé
class HabitAssignment {
  final String id;
  final String habitId;
  final String protegeId;
  final String? assignedBy;
  final bool isActive;
  final DateTime createdAt;
  
  // Joined data
  final Habit? habit;
  final UserProfile? protege;
  final UserProfile? assignedByUser;

  const HabitAssignment({
    required this.id,
    required this.habitId,
    required this.protegeId,
    this.assignedBy,
    this.isActive = true,
    required this.createdAt,
    this.habit,
    this.protege,
    this.assignedByUser,
  });

  factory HabitAssignment.fromJson(Map<String, dynamic> json) {
    Habit? habit;
    if (json['habit'] != null && json['habit'] is Map<String, dynamic>) {
      habit = Habit.fromJson(json['habit'] as Map<String, dynamic>);
    } else if (json['habits'] != null && json['habits'] is Map<String, dynamic>) {
      habit = Habit.fromJson(json['habits'] as Map<String, dynamic>);
    }

    UserProfile? protege;
    if (json['protege'] != null && json['protege'] is Map<String, dynamic>) {
      protege = UserProfile.fromJson(json['protege'] as Map<String, dynamic>);
    }

    return HabitAssignment(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      protegeId: json['protege_id'] as String,
      assignedBy: json['assigned_by'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      habit: habit,
      protege: protege,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habit_id': habitId,
      'protege_id': protegeId,
      'assigned_by': assignedBy,
      'is_active': isActive,
    };
  }
}
