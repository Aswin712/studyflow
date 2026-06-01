import '../../../core/models/schedule.dart';
import '../../../core/services/database_service.dart';

class ScheduleRepository {
  final DatabaseService _db;

  // In-memory cache
  List<Schedule>? _cache;

  ScheduleRepository(this._db);

  Future<List<Schedule>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await _db.queryAll('schedules');
    
    _cache = raw.map((map) {
      return Schedule.fromJson(Map<String, dynamic>.from(map));
    }).toList();
    
    return _cache!;
  }

  Future<List<Schedule>> getByDay(int day) async {
    final schedules = await getAll();
    return schedules.where((s) => s.day == day).toList()
      ..sort((a, b) =>
          (a.startTime.hour * 60 + a.startTime.minute)
              .compareTo(b.startTime.hour * 60 + b.startTime.minute));
  }

  Future<void> save(Schedule schedule) async {
    final list = _cache != null ? List<Schedule>.from(_cache!) : await getAll();
    final index = list.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      list[index] = schedule;
    } else {
      list.add(schedule);
    }
    
    await _db.insert('schedules', schedule.toJson());
    invalidate();
  }

  Future<void> delete(String id) async {
    if (_cache != null) {
      _cache!.removeWhere((s) => s.id == id);
    }
    await _db.delete('schedules', 'id', id);
    invalidate();
  }

  Future<void> deleteByCourse(String courseId) async {
    if (_cache != null) {
      _cache!.removeWhere((s) => s.courseId == courseId);
    }
    await _db.deleteByCourse('schedules', courseId);
    invalidate();
  }

  /// Hapus cache agar data dibaca ulang dari storage.
  /// Dipanggil oleh provider saat restore/import data.
  void invalidate() {
    _cache = null;
  }
}
