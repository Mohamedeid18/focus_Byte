import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Represents a task in the FocusByte app.
/// Each task has a title, scheduled date/time, reminder settings, completion status, and rest timer.
class Task {
  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay time;
  final DateTime? reminder;
  final bool isCompleted;
  final int pomodoroRestMinutes;
  final DateTime createdAt;
  final Duration allocatedDuration; // Total time allocated to this task (e.g., 25 min)
  final Duration remainingTime; // Time left for this task

  Task({
    String? id,
    required this.title,
    required this.date,
    required this.time,
    this.reminder,
    this.isCompleted = false,
    this.pomodoroRestMinutes = 5,
    DateTime? createdAt,
    this.allocatedDuration = const Duration(minutes: 25),
    Duration? remainingTime,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        remainingTime = remainingTime ?? const Duration(minutes: 25);

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    TimeOfDay? time,
    DateTime? reminder,
    bool? isCompleted,
    int? pomodoroRestMinutes,
    DateTime? createdAt,
    Duration? allocatedDuration,
    Duration? remainingTime,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      reminder: reminder ?? this.reminder,
      isCompleted: isCompleted ?? this.isCompleted,
      pomodoroRestMinutes: pomodoroRestMinutes ?? this.pomodoroRestMinutes,
      createdAt: createdAt ?? this.createdAt,
      allocatedDuration: allocatedDuration ?? this.allocatedDuration,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'time': '${time.hour}:${time.minute}',
        'reminder': reminder?.toIso8601String(),
        'isCompleted': isCompleted,
        'pomodoroRestMinutes': pomodoroRestMinutes,
        'createdAt': createdAt.toIso8601String(),
        'allocatedDurationMs': allocatedDuration.inMilliseconds,
        'remainingTimeMs': remainingTime.inMilliseconds,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String).split(':');
    final allocatedMs = json['allocatedDurationMs'] as int? ?? 25 * 60 * 1000;
    final remainingMs = json['remainingTimeMs'] as int? ?? allocatedMs;
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      reminder: json['reminder'] != null
          ? DateTime.parse(json['reminder'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      pomodoroRestMinutes: json['pomodoroRestMinutes'] as int? ?? 5,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      allocatedDuration: Duration(milliseconds: allocatedMs),
      remainingTime: Duration(milliseconds: remainingMs),
    );
  }
}
