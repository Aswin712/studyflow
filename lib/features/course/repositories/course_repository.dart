import '../../../core/models/course.dart';
import '../../../core/services/database_service.dart';

class CourseRepository {
  final DatabaseService _db;

  // In-memory cache
  List<Course>? _cache;

  CourseRepository(this._db);

  Future<List<Course>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await _db.queryAll('courses');
    
    // SQLite stores color as integer, boolean as integer
    _cache = raw.map((map) {
      final m = Map<String, dynamic>.from(map);
      if (m['isCompleted'] is int) m['isCompleted'] = m['isCompleted'] == 1;
      return Course.fromJson(m);
    }).toList();
    
    return _cache!;
  }

  Future<void> save(Course course) async {
    final list = _cache != null ? List<Course>.from(_cache!) : await getAll();
    final index = list.indexWhere((c) => c.id == course.id);
    if (index >= 0) {
      list[index] = course;
    } else {
      list.add(course);
    }
    
    final map = course.toJson();
    map['isCompleted'] = course.isCompleted ? 1 : 0;
    
    await _db.insert('courses', map);
    invalidate();
  }

  Future<void> delete(String id) async {
    if (_cache != null) {
      _cache!.removeWhere((c) => c.id == id);
    }
    await _db.delete('courses', 'id', id);
    invalidate();
  }

  void invalidate() {
    _cache = null;
  }
}
