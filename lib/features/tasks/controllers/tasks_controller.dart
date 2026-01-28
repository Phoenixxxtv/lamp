import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../habits/controllers/habits_controller.dart';
import '../models/task.dart';
import '../models/task_assignment.dart';

// =============================================================================
// TASKS PROVIDERS
// =============================================================================

/// Fetch assigned tasks for current user (protégé view)
final myTasksProvider = FutureProvider<List<TaskAssignment>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return [];

  try {
    final response = await SupabaseService.client
        .from('task_assignments')
        .select('''
          *,
          tasks:task_id(*)
        ''')
        .eq('protege_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => TaskAssignment.fromJson(json))
        .toList();
  } catch (e) {
    throw Exception('Failed to load tasks: $e');
  }
});

/// Fetch tasks assigned by current user (chaperone/admin view)
final assignedByMeTasksProvider = FutureProvider<List<TaskAssignment>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return [];

  try {
    final response = await SupabaseService.client
        .from('task_assignments')
        .select('''
          *,
          tasks:task_id(*),
          protege:protege_id(id, name, email)
        ''')
        .eq('assigned_by', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => TaskAssignment.fromJson(json))
        .toList();
  } catch (e) {
    throw Exception('Failed to load tasks: $e');
  }
});

/// Fetch all tasks (admin view)
final allTasksProvider = FutureProvider<List<Task>>((ref) async {
  try {
    final response = await SupabaseService.client
        .from('tasks')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Task.fromJson(json))
        .toList();
  } catch (e) {
    throw Exception('Failed to load tasks: $e');
  }
});

/// Fetch single task assignment detail
final taskDetailProvider = FutureProvider.family<TaskAssignment?, String>((ref, assignmentId) async {
  try {
    final response = await SupabaseService.client
        .from('task_assignments')
        .select('''
          *,
          tasks:task_id(*),
          protege:protege_id(id, name, email)
        ''')
        .eq('id', assignmentId)
        .single();

    return TaskAssignment.fromJson(response);
  } catch (e) {
    return null;
  }
});

// =============================================================================
// TASKS CONTROLLER
// =============================================================================

class TasksController {
  /// Create a new task
  static Future<Task?> createTask({
    required String title,
    String? description,
    DateTime? deadline,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response = await SupabaseService.client
          .from('tasks')
          .insert({
            'title': title,
            'description': description,
            'deadline': deadline?.toIso8601String(),
            'created_by': userId,
          })
          .select()
          .single();

      return Task.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Assign task to protégé
  static Future<TaskAssignment?> assignTask({
    required String taskId,
    required String protegeId,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response = await SupabaseService.client
          .from('task_assignments')
          .insert({
            'task_id': taskId,
            'protege_id': protegeId,
            'assigned_by': userId,
            'status': 'assigned',
          })
          .select()
          .single();

      return TaskAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to assign task: $e');
    }
  }

  /// Submit task (by protégé)
  static Future<bool> submitTask({
    required String assignmentId,
    String? notes,
  }) async {
    try {
      await SupabaseService.client
          .from('task_assignments')
          .update({
            'status': 'submitted',
            'submission_notes': notes,
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId);

      return true;
    } catch (e) {
      throw Exception('Failed to submit task: $e');
    }
  }

  /// Verify task (by chaperone/admin)
  static Future<bool> verifyTask({
    required String assignmentId,
    required bool approved,
    String? notes,
  }) async {
    try {
      await SupabaseService.client
          .from('task_assignments')
          .update({
            'status': approved ? 'verified' : 'rejected',
            'verification_notes': notes,
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId);

      return true;
    } catch (e) {
      throw Exception('Failed to verify task: $e');
    }
  }
}

// =============================================================================
// STATE NOTIFIER
// =============================================================================

class TasksNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  TasksNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createTaskWithAssignment({
    required String title,
    String? description,
    DateTime? deadline,
    required List<String> protegeIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final task = await TasksController.createTask(
        title: title,
        description: description,
        deadline: deadline,
      );

      if (task != null) {
        for (final protegeId in protegeIds) {
          await TasksController.assignTask(
            taskId: task.id,
            protegeId: protegeId,
          );
        }
      }

      ref.invalidate(myTasksProvider);
      ref.invalidate(assignedByMeTasksProvider);
      ref.invalidate(allTasksProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> submitTask(String assignmentId, {String? notes}) async {
    state = const AsyncValue.loading();
    try {
      await TasksController.submitTask(assignmentId: assignmentId, notes: notes);
      ref.invalidate(myTasksProvider);
      ref.invalidate(taskDetailProvider(assignmentId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> verifyTask(String assignmentId, {required bool approved, String? notes}) async {
    state = const AsyncValue.loading();
    try {
      await TasksController.verifyTask(
        assignmentId: assignmentId,
        approved: approved,
        notes: notes,
      );
      ref.invalidate(assignedByMeTasksProvider);
      ref.invalidate(taskDetailProvider(assignmentId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<void>>((ref) {
  return TasksNotifier(ref);
});

/// Check if current user can verify a task
final canVerifyTaskProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.profile?.role.canCreateContent ?? false;
});

/// Re-export protegesProvider from habits for task assignment
final taskProtegesProvider = protegesProvider;
