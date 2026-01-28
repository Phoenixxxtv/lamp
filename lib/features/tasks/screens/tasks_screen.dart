import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/router/router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/tasks_controller.dart';
import '../models/task.dart';
import '../models/task_assignment.dart';

/// Tasks screen - list of assigned tasks grouped by status
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(myTasksProvider);
    final authState = ref.watch(authControllerProvider);
    final canCreate = authState.profile?.role.canCreateContent ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasks),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks assigned',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canCreate
                        ? 'Create a task to get started'
                        : 'Your chaperone will assign tasks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          // Group tasks by status
          final pending = tasks.where((t) => t.status == TaskStatus.assigned).toList();
          final submitted = tasks.where((t) => t.status == TaskStatus.submitted).toList();
          final completed = tasks.where((t) => t.status == TaskStatus.verified).toList();
          final rejected = tasks.where((t) => t.status == TaskStatus.rejected).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myTasksProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Pending', pending.length, Colors.orange),
                  ...pending.map((t) => _TaskCard(assignment: t)),
                  const SizedBox(height: 16),
                ],
                if (rejected.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Needs Revision', rejected.length, Colors.red),
                  ...rejected.map((t) => _TaskCard(assignment: t)),
                  const SizedBox(height: 16),
                ],
                if (submitted.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Submitted', submitted.length, Colors.blue),
                  ...submitted.map((t) => _TaskCard(assignment: t)),
                  const SizedBox(height: 16),
                ],
                if (completed.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Completed', completed.length, Colors.green),
                  ...completed.map((t) => _TaskCard(assignment: t)),
                ],
              ],
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
              const Text('Failed to load tasks'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(myTasksProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.createTask),
              icon: const Icon(Icons.add),
              label: const Text('Create Task'),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskAssignment assignment;

  const _TaskCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final task = assignment.task;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.tasks}/${assignment.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task?.title ?? 'Unknown Task',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildStatusChip(context, assignment.status),
                ],
              ),
              if (task?.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  task!.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (task?.deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: task!.isOverdue
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.deadlineFormatted,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: task.isOverdue
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.outline,
                            fontWeight: task.isOverdue ? FontWeight.bold : null,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, TaskStatus status) {
    Color color;
    switch (status) {
      case TaskStatus.assigned:
        color = Colors.orange;
        break;
      case TaskStatus.submitted:
        color = Colors.blue;
        break;
      case TaskStatus.verified:
        color = Colors.green;
        break;
      case TaskStatus.rejected:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
