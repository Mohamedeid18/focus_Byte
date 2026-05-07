import 'package:focus_byte/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:focus_byte/models/task_model.dart';

DateTime _normalizeDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

List<Task> filterTasksByDate(List<Task> tasks, DateTime date) {
  final target = _normalizeDate(date);
  return tasks.where((task) => _normalizeDate(task.date) == target).toList();
}

List<Task> filterTasksThisWeek(List<Task> tasks) {
  final today = _normalizeDate(DateTime.now());
  final weekEnd = today.add(const Duration(days: 6));
  return tasks.where((task) {
    final taskDate = _normalizeDate(task.date);
    return !taskDate.isBefore(today) && !taskDate.isAfter(weekEnd);
  }).toList();
}

/// State notifier for managing the list of tasks.
/// Handles CRUD operations: Create, Read, Update, Delete, and Reset.
/// Also manages per-task countdown timers.
class TaskNotifier extends StateNotifier<List<Task>> {
  final Ref ref;

  TaskNotifier(this.ref) : super([]) {
    _loadTasks();
  }

  // Timer management
  Timer? _taskTimer;
  String? _activeTaskTimerId; // ID of the task whose timer is running
  bool _isTimerRunning = false;

  /// Load tasks from SharedPreferences.
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        state = decoded
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final task in state) {
          if (task.reminder != null) {
            await NotificationService.instance.scheduleTaskReminder(task);
          }
        }
      } catch (e) {
        print('Error loading tasks: $e');
      }
    }
  }

  /// Save tasks to SharedPreferences.
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(state.map((t) => t.toJson()).toList());
    await prefs.setString('tasks', tasksJson);
  }

  /// Add a new task to the list.
  Future<void> addTask(Task task) async {
    state = [task, ...state];
    await _saveTasks();
    await NotificationService.instance.scheduleTaskReminder(task);
  }

  /// Update an existing task.
  Future<void> updateTask(Task updatedTask) async {
    await NotificationService.instance.cancelTaskReminder(updatedTask.id);
    state = state.map((t) => t.id == updatedTask.id ? updatedTask : t).toList();
    await _saveTasks();
    await NotificationService.instance.scheduleTaskReminder(updatedTask);
  }

  /// Delete a task by its ID.
  Future<void> deleteTask(String taskId) async {
    await NotificationService.instance.cancelTaskReminder(taskId);
    state = state.where((t) => t.id != taskId).toList();
    await _saveTasks();
  }

  /// Reset a task's completion status back to false.
  Future<void> resetTask(String taskId) async {
    state = state.map((t) {
      if (t.id == taskId) {
        return t.copyWith(isCompleted: false);
      }
      return t;
    }).toList();
    await _saveTasks();
  }

  /// Toggle a task's completion status.
  Future<void> toggleTaskCompletion(String taskId) async {
    state = state.map((t) {
      if (t.id == taskId) {
        return t.copyWith(isCompleted: !t.isCompleted);
      }
      return t;
    }).toList();
    await _saveTasks();
  }

  /// Get a task by its ID.
  Task? getTaskById(String taskId) {
    try {
      return state.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }

  /// Get all tasks.
  List<Task> getAllTasks() => state;

  /// Get completed tasks only.
  List<Task> getCompletedTasks() => state.where((t) => t.isCompleted).toList();

  /// Get incomplete tasks only.
  List<Task> getIncompleteTasks() =>
      state.where((t) => !t.isCompleted).toList();

  /// Get tasks scheduled for today.
  List<Task> getTodayTasks() => filterTasksByDate(state, DateTime.now());

  /// Get tasks scheduled for tomorrow.
  List<Task> getTomorrowTasks() =>
      filterTasksByDate(state, DateTime.now().add(const Duration(days: 1)));

  /// Get tasks scheduled for the next 7 days, including today.
  List<Task> getThisWeekTasks() => filterTasksThisWeek(state);

  /// Start the countdown timer for a specific task.
  /// Only one task can have an active timer at a time.
  Task? get activeTask =>
      _activeTaskTimerId == null ? null : getTaskById(_activeTaskTimerId!);

  bool get isTimerRunning => _isTimerRunning;

  void startTaskTimer(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) return;
    if (task.remainingTime == Duration.zero) return;

    // Pause any active timer
    if (_activeTaskTimerId != null && _activeTaskTimerId != taskId) {
      pauseTaskTimer(_activeTaskTimerId!);
    }

    _activeTaskTimerId = taskId;
    ref.read(activeTaskIdProvider.notifier).state = taskId;
    _isTimerRunning = true;
    ref.read(isGlobalWorkTimerRunningProvider.notifier).state = true;

    // Cancel existing timer if any
    _taskTimer?.cancel();

    // Start new timer that ticks every second
    _taskTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickTaskTimer();
    });
  }

  /// Pause the global work timer.
  void pauseTaskTimer(String taskId) {
    if (_activeTaskTimerId != taskId) return;
    _taskTimer?.cancel();
    _isTimerRunning = false;
    ref.read(isGlobalWorkTimerRunningProvider.notifier).state = false;
  }

  /// Resume the global work timer.
  void resumeTaskTimer(String taskId) {
    if (_activeTaskTimerId != taskId) return;
    if (_isTimerRunning) return; // Already running
    if (getTaskById(taskId)?.remainingTime == Duration.zero) return;

    _isTimerRunning = true;
    ref.read(isGlobalWorkTimerRunningProvider.notifier).state = true;
    _taskTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickTaskTimer();
    });
  }

  /// Reset the active task timer to its allocated duration and stop it.
  Future<void> resetTaskTimer() async {
    final activeId = _activeTaskTimerId;
    if (activeId == null) return;

    _taskTimer?.cancel();
    _isTimerRunning = false;
    ref.read(isGlobalWorkTimerRunningProvider.notifier).state = false;

    state = state.map((t) {
      if (t.id == activeId) {
        return t.copyWith(remainingTime: t.allocatedDuration);
      }
      return t;
    }).toList();

    await _saveTasks();
  }

  /// Stop the active timer and clear the active task.
  void stopTaskTimer(String taskId) {
    if (_activeTaskTimerId != taskId) return;
    _taskTimer?.cancel();
    _activeTaskTimerId = null;
    _isTimerRunning = false;
    ref.read(activeTaskIdProvider.notifier).state = null;
    ref.read(isGlobalWorkTimerRunningProvider.notifier).state = false;
  }

  /// Reset a task's remaining time back to its allocated duration.
  Future<void> resetTaskRemainingTime(String taskId) async {
    state = state.map((t) {
      if (t.id == taskId) {
        return t.copyWith(remainingTime: t.allocatedDuration);
      }
      return t;
    }).toList();
    await _saveTasks();
  }

  /// Internal: Handle timer tick - decrement remaining time
  void _tickTaskTimer() {
    if (_activeTaskTimerId == null) return;

    var taskCompleted = false;
    Task? completedTask;

    state = state.map((t) {
      if (t.id == _activeTaskTimerId) {
        final newRemaining = t.remainingTime.inSeconds > 0
            ? Duration(seconds: t.remainingTime.inSeconds - 1)
            : Duration.zero;

        if (newRemaining == Duration.zero && t.remainingTime > Duration.zero) {
          taskCompleted = true;
          completedTask = t;
          return t.copyWith(
            remainingTime: Duration.zero,
            isCompleted: true,
          );
        }

        return t.copyWith(remainingTime: newRemaining);
      }
      return t;
    }).toList();

    if (taskCompleted) {
      _taskTimer?.cancel();
      _isTimerRunning = false;
      ref.read(isGlobalWorkTimerRunningProvider.notifier).state = false;
      _activeTaskTimerId = null;
      ref.read(activeTaskIdProvider.notifier).state = null;
      if (completedTask != null) {
        _taskTimerComplete(completedTask!);
      }
    }

    _saveTasks();
  }

  /// Internal: Called when a task's timer completes
  Future<void> _taskTimerComplete(Task task) async {
    // Show notification
    await NotificationService.instance.showNotification(
      title: 'Time\'s up!',
      body: 'Task "${task.title}" time has finished.',
    );
  }

  /// Check if a task's timer is currently running.
  bool isTaskTimerActive(String taskId) {
    return _activeTaskTimerId == taskId && _isTimerRunning;
  }

  /// Get the ID of the task with an active timer, or null.
  String? getActiveTaskTimerId() => _activeTaskTimerId;

  /// Cleanup on dispose
  @override
  void dispose() {
    _taskTimer?.cancel();
    super.dispose();
  }
}

/// Provider for task management using Riverpod (alternative to Provider).
/// You can switch to `flutter_riverpod` or use the standard `provider` package.
/// This example uses Riverpod for a more functional approach.
final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier(ref);
});

/// Provider to get completed tasks.
final completedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((t) => t.isCompleted).toList();
});

/// Provider to get incomplete tasks.
final incompleteTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((t) => !t.isCompleted).toList();
});

/// Provider to get a specific task by ID.
final taskByIdProvider = Provider.family<Task?, String>((ref, taskId) {
  final tasks = ref.watch(taskProvider);
  try {
    return tasks.firstWhere((t) => t.id == taskId);
  } catch (e) {
    return null;
  }
});

/// Provider to get today's tasks.
final todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  return filterTasksByDate(tasks, DateTime.now());
});

/// Provider to get tomorrow's tasks.
final tomorrowTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  return filterTasksByDate(tasks, DateTime.now().add(const Duration(days: 1)));
});

/// Provider to get tasks for the current week.
final thisWeekTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  return filterTasksThisWeek(tasks);
});

/// Provider to track which task is currently active for the global work timer.
final activeTaskIdProvider = StateProvider<String?>((ref) => null);

/// Provider to track whether the global work timer is currently running.
final isGlobalWorkTimerRunningProvider = StateProvider<bool>((ref) => false);
