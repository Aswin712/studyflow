import 'package:flutter/material.dart';

class Task {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime deadline;
  final TimeOfDay? deadlineTime;
  final int priority;
  final bool isDone;
  final String?
      imagePath; // path file foto di storage lokal, null = tidak ada foto

  const Task({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.deadline,
    this.deadlineTime,
    required this.priority,
    required this.isDone,
    this.imagePath,
  });

  DateTime get deadlineDateTime {
    if (deadlineTime == null) {
      return DateTime(deadline.year, deadline.month, deadline.day, 23, 59);
    }
    return DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
      deadlineTime!.hour,
      deadlineTime!.minute,
    );
  }

  bool get hasSpecificTime => deadlineTime != null;
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  Task copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    DateTime? deadline,
    Object? deadlineTime = _sentinel,
    int? priority,
    bool? isDone,
    Object? imagePath =
        _sentinel, // pakai sentinel agar bisa set null eksplisit
  }) {
    return Task(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      deadlineTime: deadlineTime == _sentinel
          ? this.deadlineTime
          : deadlineTime as TimeOfDay?,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      imagePath: imagePath == _sentinel ? this.imagePath : imagePath as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'description': description,
        'deadline': deadline.toIso8601String(),
        'deadlineHour': deadlineTime?.hour,
        'deadlineMinute': deadlineTime?.minute,
        'priority': priority,
        'isDone': isDone,
        'imagePath': imagePath,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    final hour = json['deadlineHour'] as int?;
    final minute = json['deadlineMinute'] as int?;
    final time = (hour != null && minute != null)
        ? TimeOfDay(hour: hour, minute: minute)
        : null;
    return Task(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      deadline: DateTime.parse(json['deadline'] as String),
      deadlineTime: time,
      priority: json['priority'] as int,
      isDone: json['isDone'] as bool,
      imagePath: json['imagePath'] as String?, // null kalau data lama
    );
  }

  @override
  bool operator ==(Object other) => other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

const Object _sentinel = Object();
