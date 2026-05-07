import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_byte/models/task_model.dart';
import 'package:focus_byte/providers/task_provider.dart';
import 'package:focus_byte/services/notification_service.dart';
import 'package:focus_byte/widgets/global_work_timer_card.dart';
import 'package:focus_byte/widgets/task_form_sheet.dart';
import 'package:focus_byte/widgets/task_tile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const FocusByteApp());
}

class FocusByteApp extends StatelessWidget {
  const FocusByteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: _FocusByteAppView(),
    );
  }
}

class _FocusByteAppView extends StatelessWidget {
  const _FocusByteAppView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusByte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1724),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF60A5FA),
          secondary: Color(0xFF94A3B8),
          surface: Color(0xFF1A2847),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A2847),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF60A5FA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const FocusHome(),
    );
  }
}

class FocusHome extends StatefulWidget {
  const FocusHome({super.key});

  @override
  State<FocusHome> createState() => _FocusHomeState();
}

class _FocusHomeState extends State<FocusHome> {
  static const int _defaultRestSeconds = 5 * 60;

  final TextEditingController _quickTaskController = TextEditingController();

  Timer? _workTimer;
  Timer? _restTimer;
  int _restSecondsRemaining = _defaultRestSeconds;
  bool _isRestRunning = false;
  Task? _activeRestTask;

  @override
  void dispose() {
    _workTimer?.cancel();
    _restTimer?.cancel();
    _quickTaskController.dispose();
    super.dispose();
  }

  void _startRestTimer(Task task) {
    _workTimer?.cancel();
    _restTimer?.cancel();

    setState(() {
      _activeRestTask = task;
      _isRestRunning = true;
      _restSecondsRemaining = task.pomodoroRestMinutes * 60;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_restSecondsRemaining <= 1) {
        _completeRestTimer();
      } else {
        setState(() => _restSecondsRemaining -= 1);
      }
    });
  }

  void _pauseRestTimer() {
    _restTimer?.cancel();
    setState(() => _isRestRunning = false);
  }

  void _resumeRestTimer() {
    if (_activeRestTask == null || _isRestRunning) {
      return;
    }

    setState(() => _isRestRunning = true);

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_restSecondsRemaining <= 1) {
        _completeRestTimer();
      } else {
        setState(() => _restSecondsRemaining -= 1);
      }
    });
  }

  Future<void> _completeRestTimer() async {
    final completedTask = _activeRestTask;
    _restTimer?.cancel();

    setState(() {
      _isRestRunning = false;
      _activeRestTask = null;
      _restSecondsRemaining = _defaultRestSeconds;
    });

    if (completedTask != null) {
      await NotificationService.instance.showRestCompleteNotification(
        completedTask,
      );
    }
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isRestRunning = false;
      _activeRestTask = null;
      _restSecondsRemaining = _defaultRestSeconds;
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Task _createQuickTask(String title) {
    final now = DateTime.now();
    return Task(
      title: title,
      date: now,
      time: TimeOfDay.fromDateTime(now),
    );
  }

  void _addQuickTask(WidgetRef ref) {
    final title = _quickTaskController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    ref.read(taskProvider.notifier).addTask(_createQuickTask(title));
    _quickTaskController.clear();
  }

  void _openTaskForm(Task? task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormSheet(initialTask: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.height < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FocusByte',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1724),
              Color(0xFF17213A),
              Color(0xFF1A2847),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            child: Column(
              children: [
                Expanded(
                  flex: isSmall ? 4 : 5,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _activeRestTask != null
                          ? _buildRestTimerCard(context, isSmall)
                          : const GlobalWorkTimerCard(),
                    ),
                  ),
                ),
                Expanded(
                  flex: isSmall ? 6 : 7,
                  child: Consumer(
                    builder: (context, ref, _) {
                      return _buildTasksSection(context, ref, isSmall);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestTimerCard(BuildContext context, bool isSmall) {
    final restTotal = (_activeRestTask?.pomodoroRestMinutes ?? 5) * 60;
    final progress = _restSecondsRemaining / restTotal;
    final activeTask = _activeRestTask;

    return _buildTimerCard(
      context: context,
      isSmall: isSmall,
      progress: progress,
      accentColor: const Color(0xFF10B981),
      label: 'Rest Timer',
      description: activeTask == null
          ? 'Rest in progress'
          : 'Break for ${activeTask.title}',
      timeText: _formatTime(_restSecondsRemaining),
      actionButtons: [
        _buildAnimatedButton(
          icon: Icon(
            _isRestRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
            size: isSmall ? 32 : 36,
          ),
          onPressed: () =>
              _isRestRunning ? _pauseRestTimer() : _resumeRestTimer(),
          color: const Color(0xFF10B981),
        ),
        SizedBox(width: isSmall ? 8 : 10),
        _buildAnimatedButton(
          icon: Icon(Icons.stop_circle_outlined, size: isSmall ? 28 : 32),
          onPressed: _stopRestTimer,
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildTimerCard({
    required BuildContext context,
    required bool isSmall,
    required double progress,
    required Color accentColor,
    required String label,
    required String description,
    required String timeText,
    required List<Widget> actionButtons,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: isSmall ? 190 : 230,
                height: isSmall ? 190 : 230,
                child: CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: isSmall ? 32 : 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmall ? 11 : 12,
                      color: accentColor.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: isSmall ? 10 : 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isSmall ? 14 : 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: actionButtons,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context, WidgetRef ref, bool isSmall) {
    final todayTasks = ref.watch(todayTasksProvider);
    final tomorrowTasks = ref.watch(tomorrowTasksProvider);
    final weekTasks = ref.watch(thisWeekTasksProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: isSmall ? 18 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openTaskForm(null),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Detailed task'),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 10 : 12),
            _buildQuickAddBar(ref),
            SizedBox(height: isSmall ? 10 : 12),
            TabBar(
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'Tomorrow'),
                Tab(text: 'This Week'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTaskList(context, ref, todayTasks, isSmall),
                  _buildTaskList(context, ref, tomorrowTasks, isSmall),
                  _buildTaskList(context, ref, weekTasks, isSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
    bool isSmall,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks in this category yet',
          style: TextStyle(
            color: Colors.white38,
            fontSize: isSmall ? 13 : 14,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskTile(
          task: task,
          onEdit: () => _openTaskForm(task),
          onStartRest: () {
            _startRestTimer(task);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rest timer started for ${task.title}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAddBar(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: _quickTaskController,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _addQuickTask(ref),
        decoration: InputDecoration(
          hintText: 'Quick add a task',
          border: InputBorder.none,
          isDense: true,
          suffixIcon: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addQuickTask(ref),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required Widget icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: icon,
        ),
      ),
    );
  }
}
