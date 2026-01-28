/// Habit frequency enum
enum HabitFrequency {
  daily,
  weekly,
  custom;

  static HabitFrequency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return HabitFrequency.weekly;
      case 'custom':
        return HabitFrequency.custom;
      case 'daily':
      default:
        return HabitFrequency.daily;
    }
  }

  String get displayName {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }
}

/// Habit model
class Habit {
  final String id;
  final String title;
  final String? description;
  final HabitFrequency frequency;
  final String? reminderTime; // Time in HH:mm format
  final String? createdBy;
  final bool isActive;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.title,
    this.description,
    this.frequency = HabitFrequency.daily,
    this.reminderTime,
    this.createdBy,
    this.isActive = true,
    required this.createdAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      frequency: HabitFrequency.fromString(json['frequency'] as String? ?? 'daily'),
      reminderTime: json['reminder_time'] as String?,
      createdBy: json['created_by'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'frequency': frequency.name,
      'reminder_time': reminderTime,
      'is_active': isActive,
    };
  }
}
