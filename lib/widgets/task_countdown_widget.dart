import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_byte/models/task_model.dart';
import 'package:focus_byte/providers/task_provider.dart';

/// Widget to display countdown timer for a task with progress indicator.
class TaskCountdownWidget extends ConsumerWidget {
  final Task task;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;
  final VoidCallback onStop;

  const TaskCountdownWidget({
    Key? key,
    required this.task,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
    required this.onStop,
  }) : super(key: key);

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final currentTask =
        tasks.firstWhere((t) => t.id == task.id, orElse: () => task);

    final allocatedSeconds = currentTask.allocatedDuration.inSeconds;
    final remainingSeconds = currentTask.remainingTime.inSeconds;
    final progress =
        allocatedSeconds > 0 ? remainingSeconds / allocatedSeconds : 0.0;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Task Title
          Text(
            currentTask.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Circular Progress Indicator
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(
                    progress > 0.2 ? Colors.green : Colors.red,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(currentTask.remainingTime),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'of ${_formatDuration(currentTask.allocatedDuration)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Start/Pause Button
              FloatingActionButton.small(
                heroTag: '${task.id}_start_pause',
                backgroundColor: Colors.blue,
                onPressed: currentTask.remainingTime.inSeconds > 0
                    ? onPause
                    : (currentTask.remainingTime.inSeconds == 0
                        ? onStart
                        : onResume),
                child: Icon(
                  currentTask.remainingTime.inSeconds > 0
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
              const SizedBox(width: 12),

              // Reset Button
              FloatingActionButton.small(
                heroTag: '${task.id}_reset',
                backgroundColor: Colors.orange,
                onPressed: onReset,
                child: const Icon(Icons.restart_alt),
              ),
              const SizedBox(width: 12),

              // Stop Button
              FloatingActionButton.small(
                heroTag: '${task.id}_stop',
                backgroundColor: Colors.red,
                onPressed: onStop,
                child: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
