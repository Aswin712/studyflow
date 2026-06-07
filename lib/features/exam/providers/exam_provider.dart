import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/exam.dart';
import '../../../core/services/notification_service.dart';
import '../repositories/exam_repository.dart';

class ExamProvider extends ChangeNotifier {
  final ExamRepository _repo;
  final NotificationService _notif;
  List<Exam> _exams = [];
  DateTime? _lastSyncAt; // debounce: min. 5 menit antar sync

  ExamProvider(this._repo, this._notif) {
    load();
  }

  UnmodifiableListView<Exam> get all => UnmodifiableListView(_exams);

  Exam? getById(String id) {
    try {
      return _exams.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Hitung upcoming dari _exams yang sudah di-cache,
  /// bukan dari _repo.getUpcoming() yang bypass cache.
  List<Exam> get upcoming {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return _exams
        .where((e) => !e.date.isBefore(yesterday))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Exam? get next => upcoming.isEmpty ? null : upcoming.first;

  Future<void> load() async {
    _exams = await _repo.getAll();
    notifyListeners();
  }

  /// Force re-read dari storage (untuk restore/import)
  Future<void> reload() async {
    _repo.invalidate();
    await load();
  }

  Future<void> add({
    required String courseId,
    required String title,
    required DateTime date,
    required TimeOfDay time,
    required String room,
    required String notes,
    required String courseName,
  }) async {
    final exam = Exam(
      id: const Uuid().v4(),
      courseId: courseId,
      title: title,
      date: date,
      time: time,
      room: room,
      notes: notes,
    );
    await _repo.save(exam);
    await _notif.scheduleExamReminder(exam, courseName);
    load();
  }

  Future<void> update(Exam exam, String courseName) async {
    await _repo.save(exam);
    await _notif.cancelExamReminder(exam.id);
    await _notif.scheduleExamReminder(exam, courseName);
    load();
  }

  Future<void> delete(String id) async {
    await _notif.cancelExamReminder(id);
    await _repo.delete(id);
    await load();
  }

  Future<void> deleteByCourse(String courseId) async {
    final examsToDelete = _exams.where((e) => e.courseId == courseId).toList();
    for (final e in examsToDelete) {
      await _notif.cancelExamReminder(e.id);
    }
    await _repo.deleteByCourse(courseId);
    await load();
  }

  Future<void> syncNotifications(String Function(String) getCourseName) async {
    final now = DateTime.now();
    if (_lastSyncAt != null &&
        now.difference(_lastSyncAt!).inMinutes < 5) {
      return;
    }
    _lastSyncAt = now;

    for (final exam in upcoming) {
      await _notif.cancelExamReminder(exam.id);
      await _notif.scheduleExamReminder(exam, getCourseName(exam.courseId));
    }
  }
}
