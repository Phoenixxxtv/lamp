/// Task status enum
enum TaskStatus {
  assigned,
  submitted,
  verified,
  rejected;

  static TaskStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'submitted':
        return TaskStatus.submitted;
      case 'verified':
        return TaskStatus.verified;
      case 'rejected':
        return TaskStatus.rejected;
      case 'assigned':
      default:
        return TaskStatus.assigned;
    }
  }

  String get displayName {
    switch (this) {
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.submitted:
        return 'Submitted';
      case TaskStatus.verified:
        return 'Verified';
      case TaskStatus.rejected:
        return 'Rejected';
    }
  }

  /// Get color for status badge
  String get colorHex {
    switch (this) {
      case TaskStatus.assigned:
        return '#FF9800'; // Orange
      case TaskStatus.submitted:
        return '#2196F3'; // Blue
      case TaskStatus.verified:
        return '#4CAF50'; // Green
      case TaskStatus.rejected:
        return '#F44336'; // Red
    }
  }
}

/// Task model
class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? deadline;
  final String? createdBy;
  final bool isActive;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.createdBy,
    this.isActive = true,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline'] as String) 
          : null,
      createdBy: json['created_by'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Check if deadline is past
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Get formatted deadline
  String get deadlineFormatted {
    if (deadline == null) return 'No deadline';
    final now = DateTime.now();
    final diff = deadline!.difference(now);
    
    if (diff.isNegative) {
      return 'Overdue';
    } else if (diff.inDays == 0) {
      return 'Due today';
    } else if (diff.inDays == 1) {
      return 'Due tomorrow';
    } else if (diff.inDays < 7) {
      return 'Due in ${diff.inDays} days';
    } else {
      return 'Due ${deadline!.day}/${deadline!.month}/${deadline!.year}';
    }
  }
}
