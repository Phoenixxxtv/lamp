/// Habit completion record for a specific day
class HabitCompletion {
  final String id;
  final String habitAssignmentId;
  final DateTime completedDate;
  final String? notes;
  final DateTime createdAt;

  const HabitCompletion({
    required this.id,
    required this.habitAssignmentId,
    required this.completedDate,
    this.notes,
    required this.createdAt,
  });

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      id: json['id'] as String,
      habitAssignmentId: json['habit_assignment_id'] as String,
      completedDate: DateTime.parse(json['completed_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habit_assignment_id': habitAssignmentId,
      'completed_date': completedDate.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }
}
