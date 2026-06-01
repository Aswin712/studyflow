import '../../../core/models/exam.dart';
import '../../../core/services/database_service.dart';

class ExamRepository {
  final DatabaseService _db;

  // In-memory cache
  List<Exam>? _cache;

  ExamRepository(this._db);

  Future<List<Exam>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await _db.queryAll('exams');
    
    _cache = raw.map((map) {
      return Exam.fromJson(Map<String, dynamic>.from(map));
    }).toList();
    
    return _cache!;
  }

  Future<List<Exam>> getUpcoming() async {
    final now = DateTime.now();
    final exams = await getAll();
    return exams
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<Exam>> getByCourse(String courseId) async {
    final exams = await getAll();
    return exams.where((e) => e.courseId == courseId).toList();
  }

  Future<void> save(Exam exam) async {
    final list = _cache != null ? List<Exam>.from(_cache!) : await getAll();
    final index = list.indexWhere((e) => e.id == exam.id);
    if (index >= 0) {
      list[index] = exam;
    } else {
      list.add(exam);
    }
    
    await _db.insert('exams', exam.toJson());
    invalidate();
  }

  Future<void> delete(String id) async {
    if (_cache != null) {
      _cache!.removeWhere((e) => e.id == id);
    }
    await _db.delete('exams', 'id', id);
    invalidate();
  }

  Future<void> deleteByCourse(String courseId) async {
    if (_cache != null) {
      _cache!.removeWhere((e) => e.courseId == courseId);
    }
    await _db.deleteByCourse('exams', courseId);
    invalidate();
  }

  /// Hapus cache agar data dibaca ulang dari storage.
  /// Dipanggil oleh provider saat restore/import data.
  void invalidate() {
    _cache = null;
  }
}
