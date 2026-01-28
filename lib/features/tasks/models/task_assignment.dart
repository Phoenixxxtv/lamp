import '../../auth/models/user_profile.dart';
import 'task.dart';

/// Task assignment linking task to protégé with status
class TaskAssignment {
  final String id;
  final String taskId;
  final String protegeId;
  final String? assignedBy;
  final TaskStatus status;
  final String? submissionNotes;
  final String? verificationNotes;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  
  // Joined data
  final Task? task;
  final UserProfile? protege;
  final UserProfile? assignedByUser;

  const TaskAssignment({
    required this.id,
    required this.taskId,
    required this.protegeId,
    this.assignedBy,
    this.status = TaskStatus.assigned,
    this.submissionNotes,
    this.verificationNotes,
    this.submittedAt,
    this.verifiedAt,
    required this.createdAt,
    this.task,
    this.protege,
    this.assignedByUser,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    Task? task;
    if (json['task'] != null && json['task'] is Map<String, dynamic>) {
      task = Task.fromJson(json['task'] as Map<String, dynamic>);
    } else if (json['tasks'] != null && json['tasks'] is Map<String, dynamic>) {
      task = Task.fromJson(json['tasks'] as Map<String, dynamic>);
    }

    UserProfile? protege;
    if (json['protege'] != null && json['protege'] is Map<String, dynamic>) {
      protege = UserProfile.fromJson(json['protege'] as Map<String, dynamic>);
    }

    return TaskAssignment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      protegeId: json['protege_id'] as String,
      assignedBy: json['assigned_by'] as String?,
      status: TaskStatus.fromString(json['status'] as String? ?? 'assigned'),
      submissionNotes: json['submission_notes'] as String?,
      verificationNotes: json['verification_notes'] as String?,
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at'] as String) 
          : null,
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      task: task,
      protege: protege,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'protege_id': protegeId,
      'assigned_by': assignedBy,
      'status': status.name,
      'submission_notes': submissionNotes,
      'verification_notes': verificationNotes,
    };
  }

  /// Check if task can be submitted (by protégé)
  bool get canSubmit => status == TaskStatus.assigned || status == TaskStatus.rejected;

  /// Check if task can be verified (by chaperone/admin)
  bool get canVerify => status == TaskStatus.submitted;

  /// Check if task is complete
  bool get isComplete => status == TaskStatus.verified;
}
