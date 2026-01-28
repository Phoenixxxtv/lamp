import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/habits_controller.dart';
import '../models/habit.dart';

/// Create habit screen with protégé assignment
class CreateHabitScreen extends ConsumerStatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  ConsumerState<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  HabitFrequency _frequency = HabitFrequency.daily;
  TimeOfDay? _reminderTime;
  final Set<String> _selectedProteges = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(() => _reminderTime = time);
    }
  }

  Future<void> _createHabit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProteges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one protégé')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? reminderTimeStr;
    if (_reminderTime != null) {
      reminderTimeStr = '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}';
    }

    final success = await ref.read(habitsNotifierProvider.notifier).createHabitWithAssignment(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          frequency: _frequency,
          reminderTime: reminderTimeStr,
          protegeIds: _selectedProteges.toList(),
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create habit')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final protegesAsync = ref.watch(protegesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Habit'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _createHabit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Habit Title *',
                  hintText: 'e.g., Morning Meditation',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add more details...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Frequency
              Text(
                'Frequency',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<HabitFrequency>(
                segments: HabitFrequency.values.map((f) {
                  return ButtonSegment(
                    value: f,
                    label: Text(f.displayName),
                  );
                }).toList(),
                selected: {_frequency},
                onSelectionChanged: (selected) {
                  setState(() => _frequency = selected.first);
                },
              ),
              const SizedBox(height: 24),

              // Reminder time
              Text(
                'Reminder Time (Optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickReminderTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _reminderTime != null
                      ? _reminderTime!.format(context)
                      : 'Set reminder time',
                ),
              ),
              if (_reminderTime != null)
                TextButton(
                  onPressed: () => setState(() => _reminderTime = null),
                  child: const Text('Clear reminder'),
                ),
              const SizedBox(height: 24),

              // Assign to protégés
              Text(
                'Assign to Protégés *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),

              protegesAsync.when(
                data: (proteges) {
                  if (proteges.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('No protégés available'),
                    );
                  }

                  return Column(
                    children: proteges.map((protege) {
                      final id = protege['id'] as String;
                      final name = protege['name'] as String;
                      final email = protege['email'] as String;
                      final isSelected = _selectedProteges.contains(id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedProteges.add(id);
                            } else {
                              _selectedProteges.remove(id);
                            }
                          });
                        },
                        title: Text(name),
                        subtitle: Text(email),
                        controlAffinity: ListTileControlAffinity.leading,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => const Text('Failed to load protégés'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
