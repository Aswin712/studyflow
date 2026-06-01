import 'package:flutter/material.dart';

class Exam {
  final String id;
  final String courseId;
  final String title; // UTS / UAS / Kuis
  final DateTime date;
  final TimeOfDay time;
  final String room;
  final String notes;

  const Exam({
    required this.id,
    required this.courseId,
    required this.title,
    required this.date,
    required this.time,
    required this.room,
    required this.notes,
  });

  Exam copyWith({
    String? id,
    String? courseId,
    String? title,
    DateTime? date,
    TimeOfDay? time,
    String? room,
    String? notes,
  }) {
    return Exam(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      room: room ?? this.room,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'title': title,
    'date': date.toIso8601String(),
    'timeHour': time.hour,
    'timeMinute': time.minute,
    'room': room,
    'notes': notes,
  };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    time: TimeOfDay(
      hour: json['timeHour'] as int,
      minute: json['timeMinute'] as int,
    ),
    room: json['room'] as String,
    notes: json['notes'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) => other is Exam && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
