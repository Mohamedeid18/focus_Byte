import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:focus_byte/models/task_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _taskReminderChannelId = 'task_reminders';
  static const String _restCompleteChannelId = 'rest_complete';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));
    } catch (_) {
      // Fall back to the default location if the platform cannot provide a timezone.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const windows = WindowsInitializationSettings(
      appName: 'FocusByte',
      appUserModelId: 'FocusByte.FocusByte',
      guid: '7f2a8d8c-3f1e-4b4c-9f7d-3c4c2c87d5a1',
      iconPath: null,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
        windows: windows,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _requestPermissions();
    await _createAndroidChannels();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final darwin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await darwin?.requestPermissions(alert: true, badge: true, sound: true);

    final macOS = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await macOS?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _taskReminderChannelId,
        'Task reminders',
        description: 'Notifications for task reminders',
        importance: Importance.high,
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _restCompleteChannelId,
        'Rest complete',
        description: 'Notifications when a Pomodoro rest ends',
        importance: Importance.high,
      ),
    );
  }

  Future<void> scheduleTaskReminder(Task task) async {
    final reminder = task.reminder;
    if (reminder == null) {
      return;
    }

    final now = DateTime.now();
    if (!reminder.isAfter(now)) {
      return;
    }

    await _plugin.zonedSchedule(
      id: _taskReminderNotificationId(task.id),
      title: 'Task reminder',
      body: task.title,
      scheduledDate: tz.TZDateTime.from(reminder, tz.local),
      notificationDetails: _notificationDetails(
        channelId: _taskReminderChannelId,
        channelName: 'Task reminders',
        channelDescription: 'Notifications for task reminders',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(id: _taskReminderNotificationId(taskId));
  }

  Future<void> showRestCompleteNotification(Task task) async {
    await _plugin.show(
      id: _restCompleteNotificationId(task.id),
      title: 'Rest complete',
      body: 'Time to return to ${task.title}',
      notificationDetails: _notificationDetails(
        channelId: _restCompleteChannelId,
        channelName: 'Rest complete',
        channelDescription: 'Notifications when a Pomodoro rest ends',
      ),
      payload: task.id,
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(
        channelId: _taskReminderChannelId,
        channelName: 'Task reminders',
        channelDescription: 'Notifications for task reminders',
      ),
      payload: payload,
    );
  }

  NotificationDetails _notificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      linux: const LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.normal,
      ),
      windows: const WindowsNotificationDetails(),
    );
  }

  int _taskReminderNotificationId(String taskId) {
    return _stableNotificationId(taskId);
  }

  int _restCompleteNotificationId(String taskId) {
    return _stableNotificationId(taskId) + 1;
  }

  int _stableNotificationId(String taskId) {
    final normalized = taskId.replaceAll('-', '');
    final prefix = normalized.length >= 8
        ? normalized.substring(0, 8)
        : normalized.padRight(8, '0');
    return int.parse(prefix, radix: 16) & 0x7fffffff;
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${response.payload}');
    }
  }
}
