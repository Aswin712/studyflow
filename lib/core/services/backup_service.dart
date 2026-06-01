import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/course.dart';
import '../models/schedule.dart';
import '../models/task.dart';
import '../models/exam.dart';
import 'database_service.dart';
import 'local_storage_service.dart';

class BackupService {
  static const int _backupVersion = 2; // Naik versi karena pindah ke SQLite
  static const String _appVersion = '3.4.0';

  static Future<bool> backupData() async {
    try {
      final db = await DatabaseService.getInstance();
      final storage = await LocalStorageService.getInstance();
      
      final courses = await db.queryAll('courses');
      final schedules = await db.queryAll('schedules');
      final tasks = await db.queryAll('tasks');
      final exams = await db.queryAll('exams');
      
      final settings = storage.exportSettings();

      final backup = {
        'version': _backupVersion,
        'appVersion': _appVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {
          'courses': courses,
          'schedules': schedules,
          'tasks': tasks,
          'exams': exams,
        },
        'settings': settings,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'studyflow_backup_$dateStr.json';

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup data StudyFlow ($dateStr)',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> restoreData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return null; 
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      
      Map<String, dynamic> root;
      try {
        root = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (_) {
        return 'File bukan format JSON yang valid.';
      }

      final db = await DatabaseService.getInstance();
      final storage = await LocalStorageService.getInstance();
      
      // 1. Simpan snapshot (hanya jika ingin support rollback, kita ambil semua data)
      final snapCourses = await db.queryAll('courses');
      final snapSchedules = await db.queryAll('schedules');
      final snapTasks = await db.queryAll('tasks');
      final snapExams = await db.queryAll('exams');
      final snapSettings = storage.exportSettings();

      try {
        Map<String, dynamic> data = {};
        Map<String, dynamic> settings = {};
        
        if (root.containsKey('data')) {
          data = root['data'] as Map<String, dynamic>? ?? {};
          settings = root['settings'] as Map<String, dynamic>? ?? {};
        } else if (root.containsKey('courses') || root.containsKey('tasks')) {
          data = root;
          settings = root;
        } else {
          // Format legacy tidak di-support lagi di SQLite, atau harus diparsing manual.
          return 'Format backup terlalu usang (V1).';
        }

        final List<dynamic> rawCourses = data['courses'] ?? [];
        final List<dynamic> rawSchedules = data['schedules'] ?? [];
        final List<dynamic> rawTasks = data['tasks'] ?? [];
        final List<dynamic> rawExams = data['exams'] ?? [];

        // Validasi format model 
        final parsedCourses = rawCourses.map((e) => Map<String, dynamic>.from(e)).toList();
        for (final m in parsedCourses) { 
          if (m['isCompleted'] is bool) m['isCompleted'] = (m['isCompleted'] as bool) ? 1 : 0;
          Course.fromJson(m); 
        }

        final parsedSchedules = rawSchedules.map((e) => Map<String, dynamic>.from(e)).toList();
        for (final m in parsedSchedules) { Schedule.fromJson(m); }

        final parsedTasks = rawTasks.map((e) => Map<String, dynamic>.from(e)).toList();
        for (final m in parsedTasks) { 
          if (m['isDone'] is bool) m['isDone'] = (m['isDone'] as bool) ? 1 : 0;
          Task.fromJson(m); 
        }

        final parsedExams = rawExams.map((e) => Map<String, dynamic>.from(e)).toList();
        for (final m in parsedExams) { Exam.fromJson(m); }

        // Kosongkan dan masukkan data baru
        await db.clearTable('courses');
        await db.clearTable('schedules');
        await db.clearTable('tasks');
        await db.clearTable('exams');

        await db.insertBatch('courses', parsedCourses);
        await db.insertBatch('schedules', parsedSchedules);
        await db.insertBatch('tasks', parsedTasks);
        await db.insertBatch('exams', parsedExams);

        await storage.importSettings(settings);

      } catch (e) {
        // Rollback
        await db.clearTable('courses');
        await db.clearTable('schedules');
        await db.clearTable('tasks');
        await db.clearTable('exams');

        await db.insertBatch('courses', snapCourses);
        await db.insertBatch('schedules', snapSchedules);
        await db.insertBatch('tasks', snapTasks);
        await db.insertBatch('exams', snapExams);
        await storage.importSettings(snapSettings);
        
        return 'Format file backup tidak valid atau data rusak.';
      }

      return 'SUCCESS';
    } catch (e) {
      return 'Terjadi kesalahan saat membaca file.';
    }
  }
}
