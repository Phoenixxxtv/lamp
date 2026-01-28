/// Notification type enum
enum NotificationType {
  habitReminder,
  taskAssigned,
  deadlineReminder,
  taskVerified,
  taskRejected,
  general;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'habit_reminder':
        return NotificationType.habitReminder;
      case 'task_assigned':
        return NotificationType.taskAssigned;
      case 'deadline_reminder':
        return NotificationType.deadlineReminder;
      case 'task_verified':
        return NotificationType.taskVerified;
      case 'task_rejected':
        return NotificationType.taskRejected;
      case 'general':
      default:
        return NotificationType.general;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.habitReminder:
        return 'Habit Reminder';
      case NotificationType.taskAssigned:
        return 'Task Assigned';
      case NotificationType.deadlineReminder:
        return 'Deadline Reminder';
      case NotificationType.taskVerified:
        return 'Task Verified';
      case NotificationType.taskRejected:
        return 'Task Rejected';
      case NotificationType.general:
        return 'Notification';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.habitReminder:
        return 'repeat';
      case NotificationType.taskAssigned:
        return 'assignment';
      case NotificationType.deadlineReminder:
        return 'schedule';
      case NotificationType.taskVerified:
        return 'check_circle';
      case NotificationType.taskRejected:
        return 'cancel';
      case NotificationType.general:
        return 'notifications';
    }
  }
}

/// App notification model
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String? body;
  final String? relatedId; // Habit or task assignment ID
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String? ?? 'general'),
      title: json['title'] as String,
      body: json['body'] as String?,
      relatedId: json['related_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'related_id': relatedId,
      'is_read': isRead,
    };
  }

  /// Get relative time string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
