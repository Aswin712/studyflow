import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/schedule.dart';
import '../../../core/services/widget_service.dart';
import '../repositories/schedule_repository.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _repo;
  List<Schedule> _schedules = [];

  ScheduleProvider(this._repo) {
    load();
  }

  UnmodifiableListView<Schedule> get all => UnmodifiableListView(_schedules);

  List<Schedule> getByDay(int day) {
    return _schedules.where((s) => s.day == day).toList()
      ..sort((a, b) =>
          (a.startTime.hour * 60 + a.startTime.minute)
              .compareTo(b.startTime.hour * 60 + b.startTime.minute));
  }

  // Jadwal hari ini (0=Senin)
  List<Schedule> get today {
    final weekday = DateTime.now().weekday - 1; // DateTime: 1=Mon
    return getByDay(weekday);
  }

  Future<void> load() async {
    _schedules = await _repo.getAll();
    notifyListeners();
    WidgetService.updateWidgetData();
  }

  /// Force re-read dari storage (untuk restore/import)
  Future<void> reload() async {
    _repo.invalidate();
    await load();
  }

  Future<void> add({
    required String courseId,
    required int day,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String room,
  }) async {
    final schedule = Schedule(
      id: const Uuid().v4(),
      courseId: courseId,
      day: day,
      startTime: startTime,
      endTime: endTime,
      room: room,
    );
    await _repo.save(schedule);
    load();
  }

  Future<void> update(Schedule schedule) async {
    await _repo.save(schedule);
    load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    load();
  }

  Future<void> deleteByCourse(String courseId) async {
    await _repo.deleteByCourse(courseId);
    load();
  }
}
