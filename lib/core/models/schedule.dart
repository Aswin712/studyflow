import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String courseId;
  final int day; // 0=Senin, 6=Minggu
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String room;

  const Schedule({
    required this.id,
    required this.courseId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  Schedule copyWith({
    String? id,
    String? courseId,
    int? day,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? room,
  }) {
    return Schedule(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'day': day,
    'startHour': startTime.hour,
    'startMinute': startTime.minute,
    'endHour': endTime.hour,
    'endMinute': endTime.minute,
    'room': room,
  };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    day: json['day'] as int,
    startTime: TimeOfDay(
      hour: json['startHour'] as int,
      minute: json['startMinute'] as int,
    ),
    endTime: TimeOfDay(
      hour: json['endHour'] as int,
      minute: json['endMinute'] as int,
    ),
    room: json['room'] as String,
  );

  @override
  bool operator ==(Object other) => other is Schedule && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
