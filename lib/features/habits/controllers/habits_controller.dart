import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/habit.dart';
import '../models/habit_assignment.dart';
import '../models/habit_completion.dart';

// =============================================================================
// HABITS PROVIDERS
// =============================================================================

/// Fetch assigned habits for current user (protégé view)
final myHabitsProvider = FutureProvider<List<HabitAssignment>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return [];

  try {
    final response = await SupabaseService.client
        .from('habit_assignments')
        .select('''
          *,
          habits:habit_id(*)
        ''')
        .eq('protege_id', userId)
        .eq('is_active', true);

    return (response as List)
        .map((json) => HabitAssignment.fromJson(json))
        .toList();
  } catch (e) {
    throw Exception('Failed to load habits: $e');
  }
});

/// Fetch all habits (admin/chaperone view)
final allHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  try {
    final response = await SupabaseService.client
        .from('habits')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Habit.fromJson(json))
        .toList();
  } catch (e) {
    throw Exception('Failed to load habits: $e');
  }
});

/// Fetch completions for today
final todayCompletionsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return {};

  final today = DateTime.now().toIso8601String().split('T')[0];

  try {
    // Get user's habit assignments
    final assignments = await ref.watch(myHabitsProvider.future);
    final assignmentIds = assignments.map((a) => a.id).toList();
    
    if (assignmentIds.isEmpty) return {};

    final response = await SupabaseService.client
        .from('habit_completions')
        .select('habit_assignment_id')
        .inFilter('habit_assignment_id', assignmentIds)
        .eq('completed_date', today);

    return (response as List)
        .map((json) => json['habit_assignment_id'] as String)
        .toSet();
  } catch (e) {
    return {};
  }
});

/// Fetch completion history for a habit assignment
final habitHistoryProvider = FutureProvider.family<List<HabitCompletion>, String>((ref, assignmentId) async {
  try {
    final response = await SupabaseService.client
        .from('habit_completions')
        .select()
        .eq('habit_assignment_id', assignmentId)
        .order('completed_date', ascending: false)
        .limit(30);

    return (response as List)
        .map((json) => HabitCompletion.fromJson(json))
        .toList();
  } catch (e) {
    throw Exception('Failed to load history: $e');
  }
});

/// Fetch protégés for assignment (chaperone/admin)
final protegesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final currentUser = authState.profile;
  
  if (currentUser == null) return [];

  try {
    if (currentUser.role.canAssignToAnyone) {
      // Admin: get all protégés
      final response = await SupabaseService.client
          .from('profiles')
          .select('id, name, email')
          .eq('role', 'protege')
          .eq('is_active', true);
      return List<Map<String, dynamic>>.from(response);
    } else if (currentUser.role.canCreateContent) {
      // Chaperone: get assigned protégés
      final response = await SupabaseService.client
          .from('profiles')
          .select('id, name, email')
          .eq('chaperone_id', currentUser.id)
          .eq('is_active', true);
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  } catch (e) {
    return [];
  }
});

// =============================================================================
// HABITS CONTROLLER
// =============================================================================

class HabitsController {
  /// Create a new habit
  static Future<Habit?> createHabit({
    required String title,
    String? description,
    HabitFrequency frequency = HabitFrequency.daily,
    String? reminderTime,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response = await SupabaseService.client
          .from('habits')
          .insert({
            'title': title,
            'description': description,
            'frequency': frequency.name,
            'reminder_time': reminderTime,
            'created_by': userId,
          })
          .select()
          .single();

      return Habit.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }

  /// Assign habit to protégé
  static Future<HabitAssignment?> assignHabit({
    required String habitId,
    required String protegeId,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response = await SupabaseService.client
          .from('habit_assignments')
          .insert({
            'habit_id': habitId,
            'protege_id': protegeId,
            'assigned_by': userId,
          })
          .select()
          .single();

      return HabitAssignment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to assign habit: $e');
    }
  }

  /// Mark habit as complete for today
  static Future<HabitCompletion?> markComplete({
    required String assignmentId,
    String? notes,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await SupabaseService.client
          .from('habit_completions')
          .insert({
            'habit_assignment_id': assignmentId,
            'completed_date': today,
            'notes': notes,
          })
          .select()
          .single();

      return HabitCompletion.fromJson(response);
    } catch (e) {
      throw Exception('Failed to mark complete: $e');
    }
  }

  /// Unmark habit completion for today
  static Future<bool> unmarkComplete(String assignmentId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      await SupabaseService.client
          .from('habit_completions')
          .delete()
          .eq('habit_assignment_id', assignmentId)
          .eq('completed_date', today);

      return true;
    } catch (e) {
      throw Exception('Failed to unmark: $e');
    }
  }
}

// =============================================================================
// STATE NOTIFIER
// =============================================================================

class HabitsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  HabitsNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createHabitWithAssignment({
    required String title,
    String? description,
    HabitFrequency frequency = HabitFrequency.daily,
    String? reminderTime,
    required List<String> protegeIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final habit = await HabitsController.createHabit(
        title: title,
        description: description,
        frequency: frequency,
        reminderTime: reminderTime,
      );

      if (habit != null) {
        for (final protegeId in protegeIds) {
          await HabitsController.assignHabit(
            habitId: habit.id,
            protegeId: protegeId,
          );
        }
      }

      ref.invalidate(myHabitsProvider);
      ref.invalidate(allHabitsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleCompletion(String assignmentId, bool isCompleted) async {
    state = const AsyncValue.loading();
    try {
      if (isCompleted) {
        await HabitsController.unmarkComplete(assignmentId);
      } else {
        await HabitsController.markComplete(assignmentId: assignmentId);
      }

      ref.invalidate(todayCompletionsProvider);
      ref.invalidate(habitHistoryProvider(assignmentId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final habitsNotifierProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<void>>((ref) {
  return HabitsNotifier(ref);
});
