import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/course.dart';
import '../../../core/utils/constants.dart';
import '../repositories/course_repository.dart';

class CourseProvider extends ChangeNotifier {
  final CourseRepository _repo;
  List<Course> _courses = [];

  CourseProvider(this._repo) {
    load();
  }

  UnmodifiableListView<Course> get courses => UnmodifiableListView(_courses);

  Course? getById(String id) {
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  int get totalSks => _courses.fold(0, (sum, c) => sum + c.sks);

  int get completedSks => _courses.where((c) => c.isCompleted).fold(0, (sum, c) => sum + c.sks);

  double get currentIpk {
    int totalBobot = 0;
    int totalSksSelesai = 0;
    for (final c in _courses) {
      if (c.isCompleted && c.grade != null) {
        final bobot = _gradeToWeight(c.grade!);
        totalBobot += bobot * c.sks;
        totalSksSelesai += c.sks;
      }
    }
    if (totalSksSelesai == 0) return 0.0;
    return totalBobot / totalSksSelesai;
  }

  int _gradeToWeight(String grade) {
    switch (grade.toUpperCase()) {
      case 'A': return 4;
      case 'B': return 3;
      case 'C': return 2;
      case 'D': return 1;
      case 'E': return 0;
      default: return 0;
    }
  }

  Future<void> load() async {
    _courses = await _repo.getAll();
    notifyListeners();
  }

  /// Force re-read dari storage (untuk restore/import)
  Future<void> reload() async {
    _repo.invalidate();
    await load();
  }

  Future<void> add({
    required String name,
    required int sks,
    required String lecturer,
    required String room,
    required Color color,
    bool isCompleted = false,
    String? grade,
  }) async {
    final course = Course(
      id: const Uuid().v4(),
      name: name,
      sks: sks,
      lecturer: lecturer,
      room: room,
      color: color,
      isCompleted: isCompleted,
      grade: grade,
    );
    await _repo.save(course);
    load();
  }

  Future<void> update(Course course) async {
    await _repo.save(course);
    load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    load();
  }

  Color defaultColorFor(int index) {
    final hex = AppConstants
        .defaultCourseColors[index % AppConstants.defaultCourseColors.length];
    return Color(int.parse('FF$hex', radix: 16));
  }
}
