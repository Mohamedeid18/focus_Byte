import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_byte/models/task_model.dart';
import 'package:focus_byte/providers/task_provider.dart';

/// A tile widget representing a single task in the task list.
/// Displays task title, date/time, and action buttons (edit, complete, delete, reset, rest timer).
class TaskTile extends ConsumerWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onStartRest; // Callback to start rest timer for this task

  const TaskTile({
    Key? key,
    required this.task,
    required this.onEdit,
    required this.onStartRest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Watch the current task state to get updated remaining time
    final tasks = ref.watch(taskProvider);
    final activeTaskId = ref.watch(activeTaskIdProvider);
    final isGlobalRunning = ref.watch(isGlobalWorkTimerRunningProvider);
    final currentTask =
        tasks.firstWhere((t) => t.id == task.id, orElse: () => task);
    final isActiveTask = activeTaskId == task.id;
    final isTimerActive = isActiveTask && isGlobalRunning;

    // Calculate progress
    final allocatedSeconds = currentTask.allocatedDuration.inSeconds;
    final remainingSeconds = currentTask.remainingTime.inSeconds;
    final progress =
        allocatedSeconds > 0 ? remainingSeconds / allocatedSeconds : 0.0;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(taskProvider.notifier).deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(taskProvider.notifier).addTask(task);
              },
            ),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Checkbox(
            value: task.isCompleted,
            activeColor: colorScheme.primary,
            onChanged: (_) {
              ref.read(taskProvider.notifier).toggleTaskCompletion(task.id);
            },
          ),
          title: Text(
            task.title,
            style: textTheme.bodyLarge?.copyWith(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted
                  ? (isDarkMode ? Colors.white38 : Colors.black38)
                  : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDate(currentTask.date)} at ${currentTask.time.format(context)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
                if (currentTask.remainingTime.inSeconds > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(
                              progress > 0.2 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(currentTask.remainingTime),
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isTimerActive ? Colors.green : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isTimerActive
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: isActiveTask
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
                tooltip: isActiveTask
                    ? (isTimerActive ? 'Pause timer' : 'Resume timer')
                    : 'Start timer',
                onPressed: () {
                  if (isActiveTask) {
                    if (isTimerActive) {
                      ref.read(taskProvider.notifier).pauseTaskTimer(task.id);
                    } else {
                      ref.read(taskProvider.notifier).resumeTaskTimer(task.id);
                    }
                  } else {
                    ref.read(taskProvider.notifier).startTaskTimer(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Timer started for: ${task.title}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'rest') {
                    onStartRest();
                  } else if (value == 'start_timer') {
                    ref.read(taskProvider.notifier).startTaskTimer(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Timer started for: ${task.title}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else if (value == 'pause_timer') {
                    ref.read(taskProvider.notifier).pauseTaskTimer(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Timer paused'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (value == 'resume_timer') {
                    ref.read(taskProvider.notifier).resumeTaskTimer(task.id);
                  } else if (value == 'reset_timer') {
                    await ref
                        .read(taskProvider.notifier)
                        .resetTaskRemainingTime(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Timer reset'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (value == 'stop_timer') {
                    ref.read(taskProvider.notifier).stopTaskTimer(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Timer stopped'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (value == 'reset') {
                    ref.read(taskProvider.notifier).resetTask(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task reset to incomplete')),
                    );
                  } else if (value == 'delete') {
                    ref.read(taskProvider.notifier).deleteTask(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Task deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            ref.read(taskProvider.notifier).addTask(task);
                          },
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (context) {
                  final hasTimer = currentTask.remainingTime.inSeconds > 0;
                  final timerIsActive = isTimerActive;

                  return [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'rest', child: Text('Start Rest Timer')),
                    if (hasTimer) ...[
                      if (!timerIsActive)
                        const PopupMenuItem(
                            value: 'start_timer', child: Text('Start Timer')),
                      if (timerIsActive)
                        const PopupMenuItem(
                            value: 'pause_timer', child: Text('Pause Timer')),
                      if (!timerIsActive && isActiveTask)
                        const PopupMenuItem(
                            value: 'resume_timer', child: Text('Resume Timer')),
                      const PopupMenuItem(
                          value: 'reset_timer', child: Text('Reset Timer')),
                      const PopupMenuItem(
                          value: 'stop_timer', child: Text('Stop Timer')),
                    ],
                    if (task.isCompleted)
                      const PopupMenuItem(value: 'reset', child: Text('Reset')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ];
                },
                icon: const Icon(Icons.more_vert, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format duration to MM:SS string.
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format date to a readable string (e.g., "Today", "Tomorrow", "Dec 25").
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day} ${_monthName(date.month)}';
    }
  }

  /// Convert month number to short month name.
  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
