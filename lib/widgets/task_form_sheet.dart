import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_byte/models/task_model.dart';
import 'package:focus_byte/providers/task_provider.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  final Task? initialTask;

  const TaskFormSheet({super.key, this.initialTask});

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  late final TextEditingController _titleController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  DateTime? _selectedReminder;
  late int _pomodoroRestMinutes;
  late int _allocatedMinutes; // Track task duration

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;

    _titleController = TextEditingController(text: initialTask?.title ?? '');
    _selectedDate = initialTask?.date ?? DateTime.now();
    _selectedTime = initialTask?.time ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedReminder = initialTask?.reminder;
    _pomodoroRestMinutes = initialTask?.pomodoroRestMinutes ?? 5;
    _allocatedMinutes = initialTask?.allocatedDuration.inMinutes ?? 25;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A2847) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialTask != null ? 'Edit Task' : 'Add New Task',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task Title',
                hintText: 'Enter task title',
                filled: true,
                fillColor: isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(context, colorScheme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimePicker(context, colorScheme),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildReminderPicker(context, colorScheme),
            const SizedBox(height: 16),
            _buildTaskDurationPicker(context, colorScheme),
            const SizedBox(height: 16),
            _buildRestDurationPicker(context, colorScheme),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _saveTask,
                  child: Text(
                    widget.initialTask != null ? 'Update' : 'Add',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, ColorScheme colorScheme) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateForDisplay(_selectedDate),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, ColorScheme colorScheme) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (picked != null) {
          setState(() => _selectedTime = picked);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedTime.format(context),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderPicker(BuildContext context, ColorScheme colorScheme) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedReminder ?? _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );

        if (pickedDate == null) {
          return;
        }

        final initialTime = _selectedReminder != null
            ? TimeOfDay.fromDateTime(_selectedReminder!)
            : _selectedTime;

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );

        if (pickedTime == null) {
          return;
        }

        setState(() {
          _selectedReminder = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedReminder != null
                      ? _formatReminderDisplay(context, _selectedReminder!)
                      : 'Not set',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (_selectedReminder != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(() => _selectedReminder = null),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDurationPicker(
      BuildContext context, ColorScheme colorScheme) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Duration (Work Time)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: _allocatedMinutes.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '$_allocatedMinutes min',
                  onChanged: (value) {
                    setState(() => _allocatedMinutes = value.round());
                  },
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  '$_allocatedMinutes min',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestDurationPicker(
      BuildContext context, ColorScheme colorScheme) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Break Duration',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  value: _pomodoroRestMinutes.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: '$_pomodoroRestMinutes min',
                  onChanged: (value) {
                    setState(() => _pomodoroRestMinutes = value.round());
                  },
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  '$_pomodoroRestMinutes min',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    }
    if (taskDate == tomorrow) {
      return 'Tomorrow';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatReminderDisplay(BuildContext context, DateTime reminder) {
    final formattedDate = _formatDateForDisplay(reminder);
    final formattedTime = TimeOfDay.fromDateTime(reminder).format(context);
    return '$formattedDate at $formattedTime';
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    if (widget.initialTask != null) {
      final updatedTask = widget.initialTask!.copyWith(
        title: title,
        date: _selectedDate,
        time: _selectedTime,
        reminder: _selectedReminder,
        pomodoroRestMinutes: _pomodoroRestMinutes,
        allocatedDuration: Duration(minutes: _allocatedMinutes),
        remainingTime: Duration(minutes: _allocatedMinutes),
      );
      ref.read(taskProvider.notifier).updateTask(updatedTask);
    } else {
      ref.read(taskProvider.notifier).addTask(
            Task(
              title: title,
              date: _selectedDate,
              time: _selectedTime,
              reminder: _selectedReminder,
              pomodoroRestMinutes: _pomodoroRestMinutes,
              allocatedDuration: Duration(minutes: _allocatedMinutes),
              remainingTime: Duration(minutes: _allocatedMinutes),
            ),
          );
    }

    Navigator.pop(context);
  }
}
