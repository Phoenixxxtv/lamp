import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/tasks_controller.dart';
import '../models/task.dart';

/// Task detail screen with submit/verify actions
class TaskDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const TaskDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    setState(() => _isSubmitting = true);

    final success = await ref.read(tasksNotifierProvider.notifier).submitTask(
          widget.assignmentId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task submitted successfully!')),
      );
      _notesController.clear();
    }
  }

  Future<void> _verifyTask(bool approved) async {
    setState(() => _isSubmitting = true);

    final success = await ref.read(tasksNotifierProvider.notifier).verifyTask(
          widget.assignmentId,
          approved: approved,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved ? 'Task verified!' : 'Task rejected'),
        ),
      );
      _notesController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(taskDetailProvider(widget.assignmentId));
    final canVerify = ref.watch(canVerifyTaskProvider);

    return detailAsync.when(
      data: (assignment) {
        if (assignment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task')),
            body: const Center(child: Text('Task not found')),
          );
        }

        final task = assignment.task;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task?.title ?? 'Task',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          _buildStatusChip(context, assignment.status),
                        ],
                      ),
                      if (task?.description != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          task!.description!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                      if (task?.deadline != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: task!.isOverdue
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 20,
                                color: task.isOverdue
                                    ? Theme.of(context).colorScheme.onErrorContainer
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                task.deadlineFormatted,
                                style: TextStyle(
                                  color: task.isOverdue
                                      ? Theme.of(context).colorScheme.onErrorContainer
                                      : Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status timeline
                _buildTimeline(context, assignment),
                const SizedBox(height: 24),

                // Submission notes (if submitted)
                if (assignment.submissionNotes != null) ...[
                  _buildNotesCard(
                    context,
                    'Submission Notes',
                    assignment.submissionNotes!,
                    Icons.note_outlined,
                  ),
                  const SizedBox(height: 16),
                ],

                // Verification notes (if verified/rejected)
                if (assignment.verificationNotes != null) ...[
                  _buildNotesCard(
                    context,
                    assignment.status == TaskStatus.verified
                        ? 'Verification Notes'
                        : 'Rejection Reason',
                    assignment.verificationNotes!,
                    assignment.status == TaskStatus.verified
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                  ),
                  const SizedBox(height: 16),
                ],

                // Action section
                if (assignment.canSubmit || (canVerify && assignment.canVerify)) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  if (assignment.canSubmit) ...[
                    Text(
                      'Submit Task',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add any notes for your submission...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitTask,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: const Text('Submit Task'),
                      ),
                    ),
                  ],

                  if (canVerify && assignment.canVerify) ...[
                    Text(
                      'Review Submission',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Feedback (optional)',
                        hintText: 'Add feedback for the protégé...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : () => _verifyTask(false),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : () => _verifyTask(true),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.check),
                            label: const Text('Verify'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load task'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(taskDetailProvider(widget.assignmentId)),
                child: const Text('Retry'),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, dynamic assignment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildTimelineItem(
          context,
          'Assigned',
          _formatDate(assignment.createdAt),
          true,
        ),
        if (assignment.submittedAt != null)
          _buildTimelineItem(
            context,
            'Submitted',
            _formatDate(assignment.submittedAt),
            true,
          ),
        if (assignment.verifiedAt != null)
          _buildTimelineItem(
            context,
            assignment.status == TaskStatus.verified ? 'Verified' : 'Rejected',
            _formatDate(assignment.verifiedAt),
            true,
            isLast: true,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    String date,
    bool completed, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: completed
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(
    BuildContext context,
    String title,
    String notes,
    IconData icon,
  ) {
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
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(notes),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
