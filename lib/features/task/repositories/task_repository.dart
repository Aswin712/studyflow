import '../../../core/models/task.dart';
import '../../../core/services/database_service.dart';

class TaskRepository {
  final DatabaseService _db;

  // In-memory cache
  List<Task>? _cache;

  TaskRepository(this._db);

  Future<List<Task>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await _db.queryAll('tasks');
    
    _cache = raw.map((map) {
      final m = Map<String, dynamic>.from(map);
      if (m['isDone'] is int) m['isDone'] = m['isDone'] == 1;
      return Task.fromJson(m);
    }).toList();
    
    return _cache!;
  }

  Future<List<Task>> getPending() async {
    final tasks = await getAll();
    return tasks.where((t) => !t.isDone).toList()
      ..sort((a, b) => a.deadlineDateTime.compareTo(b.deadlineDateTime));
  }

  Future<List<Task>> getByCourse(String courseId) async {
    final tasks = await getAll();
    return tasks.where((t) => t.courseId == courseId).toList();
  }

  Future<void> save(Task task) async {
    final list = _cache != null ? List<Task>.from(_cache!) : await getAll();
    final index = list.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      list[index] = task;
    } else {
      list.add(task);
    }
    
    final map = task.toJson();
    map['isDone'] = task.isDone ? 1 : 0;
    
    await _db.insert('tasks', map);
    invalidate();
  }

  Future<void> delete(String id) async {
    if (_cache != null) {
      _cache!.removeWhere((t) => t.id == id);
    }
    await _db.delete('tasks', 'id', id);
    invalidate();
  }

  Future<void> deleteByCourse(String courseId) async {
    if (_cache != null) {
      _cache!.removeWhere((t) => t.courseId == courseId);
    }
    await _db.deleteByCourse('tasks', courseId);
    invalidate();
  }

  Future<void> toggleDone(String id) async {
    final list = _cache != null ? List<Task>.from(_cache!) : await getAll();
    final index = list.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final task = list[index].copyWith(isDone: !list[index].isDone);
      list[index] = task;
      
      final map = task.toJson();
      map['isDone'] = task.isDone ? 1 : 0;
      await _db.insert('tasks', map);
    }
    invalidate();
  }

  /// Hapus cache agar data dibaca ulang dari storage.
  /// Dipanggil oleh provider saat restore/import data.
  void invalidate() {
    _cache = null;
  }
}
