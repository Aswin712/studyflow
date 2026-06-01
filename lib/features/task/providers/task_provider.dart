import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/task.dart';
import '../../../core/services/notification_service.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo;
  final NotificationService _notif;
  List<Task> _tasks = [];
  bool _showDone = false;

  // Cache untuk pending — hindari filter+sort berulang
  List<Task>? _pendingCache;

  TaskProvider(this._repo, this._notif) {
    load();
  }

  UnmodifiableListView<Task> get all => UnmodifiableListView(_tasks);
  
  Task? getById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  bool get showDone => _showDone;

  List<Task> get pending {
    if (_pendingCache != null) return _pendingCache!;
    _pendingCache = _tasks.where((t) => !t.isDone).toList()
      ..sort((a, b) => a.deadlineDateTime.compareTo(b.deadlineDateTime));
    return _pendingCache!;
  }

  List<Task> get done => _tasks.where((t) => t.isDone).toList();

  List<Task> get visible => _showDone ? _tasks : pending;

  int get pendingCount => pending.length;

  void toggleShowDone() {
    _showDone = !_showDone;
    notifyListeners();
  }

  Future<void> load() async {
    _tasks = await _repo.getAll();
    _pendingCache = null; // invalidate cache
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
    required String description,
    required DateTime deadline,
    TimeOfDay? deadlineTime,
    required int priority,
    required String courseName,
    String? imagePath,
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      courseId: courseId,
      title: title,
      description: description,
      deadline: deadline,
      deadlineTime: deadlineTime,
      priority: priority,
      isDone: false,
      imagePath: imagePath,
    );
    await _repo.save(task);
    await _notif.scheduleTaskReminder(task, courseName);
    load();
  }

  Future<void> update(Task task, String courseName) async {
    await _repo.save(task);
    await _notif.cancelTaskReminder(task.id);
    if (!task.isDone) {
      await _notif.scheduleTaskReminder(task, courseName);
    }
    load();
  }

  Future<void> toggleDone(String id) async {
    await _repo.toggleDone(id);
    final task = _tasks.firstWhere((t) => t.id == id);
    if (!task.isDone) {
      // Because toggleDone flipped it. Wait, the local `task` from `_tasks` might not be updated yet until `load()` finishes.
      // So let's just cancel reminder always when toggling, or re-schedule if it's not done.
      // Actually, if we toggle to DONE, we cancel. If we toggle to NOT DONE, we don't need to do anything since the reminder is lost unless we recreate it.
      await _notif.cancelTaskReminder(id);
    }
    await load();
  }

  Future<void> delete(String id) async {
    await _notif.cancelTaskReminder(id);
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final task = _tasks[idx];
      if (task.imagePath != null && task.imagePath!.isNotEmpty) {
        try {
          final file = File(task.imagePath!);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {} // ignore errors if file already deleted manually
      }
    }
    await _repo.delete(id);
    await load();
  }

  Future<void> deleteMultiple(Set<String> ids) async {
    for (final id in ids) {
      await _notif.cancelTaskReminder(id);
      final idx = _tasks.indexWhere((t) => t.id == id);
      if (idx != -1) {
        final task = _tasks[idx];
        if (task.imagePath != null && task.imagePath!.isNotEmpty) {
          try {
            final file = File(task.imagePath!);
            if (file.existsSync()) file.deleteSync();
          } catch (_) {}
        }
      }
      await _repo.delete(id);
    }
    await load();
  }

  Future<void> deleteByCourse(String courseId) async {
    final tasksToDelete = _tasks.where((t) => t.courseId == courseId).toList();
    for (final t in tasksToDelete) {
      await _notif.cancelTaskReminder(t.id);
      if (t.imagePath != null && t.imagePath!.isNotEmpty) {
        try {
          final file = File(t.imagePath!);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      }
    }
    await _repo.deleteByCourse(courseId);
    await load();
  }
}
