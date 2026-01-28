import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/router/router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/habits_controller.dart';
import '../models/habit_assignment.dart';

/// Habits screen - list of assigned habits with completion toggle
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final habitsAsync = ref.watch(myHabitsProvider);
    final completionsAsync = ref.watch(todayCompletionsProvider);
    final authState = ref.watch(authControllerProvider);
    final canCreate = authState.profile?.role.canCreateContent ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.habits),
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No habits assigned',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canCreate
                        ? 'Create a habit to get started'
                        : 'Your chaperone will assign habits',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myHabitsProvider);
              ref.invalidate(todayCompletionsProvider);
            },
            child: completionsAsync.when(
              data: (completedIds) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final assignment = habits[index];
                    final isCompleted = completedIds.contains(assignment.id);
                    return _HabitCard(
                      assignment: assignment,
                      isCompleted: isCompleted,
                    );
                  },
                );
              },
              loading: () => _buildHabitList(context, habits, {}),
              error: (_, __) => _buildHabitList(context, habits, {}),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text('Failed to load habits'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(myHabitsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.createHabit),
              icon: const Icon(Icons.add),
              label: const Text('Create Habit'),
            )
          : null,
    );
  }

  Widget _buildHabitList(
    BuildContext context,
    List<HabitAssignment> habits,
    Set<String> completedIds,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final assignment = habits[index];
        return _HabitCard(
          assignment: assignment,
          isCompleted: completedIds.contains(assignment.id),
        );
      },
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final HabitAssignment assignment;
  final bool isCompleted;

  const _HabitCard({
    required this.assignment,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = assignment.habit;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.habits}/${assignment.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Completion checkbox
              GestureDetector(
                onTap: () async {
                  await ref.read(habitsNotifierProvider.notifier)
                      .toggleCompletion(assignment.id, isCompleted);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: isCompleted
                        ? null
                        : Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle_outlined,
                    color: isCompleted
                        ? Colors.white
                        : Theme.of(context).colorScheme.outline,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Habit info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit?.title ?? 'Unknown Habit',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    if (habit?.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit!.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          habit?.frequency.displayName ?? 'Daily',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
