import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/habits_controller.dart';
import '../models/habit_completion.dart';

/// Habit detail screen with completion history
class HabitDetailScreen extends ConsumerWidget {
  final String assignmentId;

  const HabitDetailScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(myHabitsProvider);
    final historyAsync = ref.watch(habitHistoryProvider(assignmentId));
    final completionsAsync = ref.watch(todayCompletionsProvider);

    return habitsAsync.when(
      data: (habits) {
        final assignment = habits.where((h) => h.id == assignmentId).firstOrNull;
        final habit = assignment?.habit;

        if (habit == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habit')),
            body: const Center(child: Text('Habit not found')),
          );
        }

        final isCompletedToday = completionsAsync.maybeWhen(
          data: (ids) => ids.contains(assignmentId),
          orElse: () => false,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(habit.title),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Habit info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            habit.frequency.displayName,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        habit.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      if (habit.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          habit.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Today's status
                _buildTodayStatus(context, ref, isCompletedToday),
                const SizedBox(height: 24),

                // Completion history
                Text(
                  'Recent Completions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                historyAsync.when(
                  data: (completions) {
                    if (completions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'No completions yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ),
                      );
                    }

                    return _buildCompletionCalendar(context, completions);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (_, __) => const Text('Failed to load history'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Habit')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Habit')),
        body: const Center(child: Text('Failed to load habit')),
      ),
    );
  }

  Widget _buildTodayStatus(BuildContext context, WidgetRef ref, bool isCompleted) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await ref.read(habitsNotifierProvider.notifier)
                  .toggleCompletion(assignmentId, isCompleted);
            },
            icon: Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
            ),
            label: Text(
              isCompleted ? 'Completed Today!' : 'Mark as Complete',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: isCompleted
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionCalendar(
    BuildContext context,
    List<HabitCompletion> completions,
  ) {
    // Build last 30 days grid
    final now = DateTime.now();
    final days = List.generate(30, (i) {
      return DateTime(now.year, now.month, now.day - (29 - i));
    });

    final completedDates = completions
        .map((c) => DateTime(
              c.completedDate.year,
              c.completedDate.month,
              c.completedDate.day,
            ))
        .toSet();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 30 Days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: days.map((day) {
              final isCompleted = completedDates.contains(day);
              final isToday = day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;

              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: isToday
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Completed',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Missed',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
