import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
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
      final fileName = 'studyflow_backup_$dateStr.zip';

      final directory = await getTemporaryDirectory();
      final zipFilePath = '${directory.path}/$fileName';

      final archive = Archive();
      
      // Tambahkan data.json
      final jsonBytes = utf8.encode(jsonString);
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      // Kumpulkan foto dari tasks
      for (final t in tasks) {
        final path = t['imagePath'] as String?;
        if (path != null && path.isNotEmpty) {
          final file = File(path);
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            final name = p.basename(path);
            archive.addFile(ArchiveFile('photos/$name', bytes.length, bytes));
          }
        }
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData.isEmpty) return false;
      
      final file = File(zipFilePath);
      await file.writeAsBytes(zipData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup data StudyFlow ($dateStr)',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> restoreData(BuildContext context) async {
    Directory? tempDir;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return null; 
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      
      // Ekstrak ZIP
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Cari data.json
      final dataFile = archive.findFile('data.json');
      if (dataFile == null) {
        return 'File ZIP tidak memiliki data.json yang valid.';
      }

      final jsonString = utf8.decode(dataFile.content as List<int>);
      
      Map<String, dynamic> root;
      try {
        root = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (_) {
        return 'File data.json bukan format JSON yang valid.';
      }

      final db = await DatabaseService.getInstance();
      final storage = await LocalStorageService.getInstance();
      
      Map<String, dynamic> data = {};
      Map<String, dynamic> settings = {};
      
      if (root.containsKey('data')) {
        data = root['data'] as Map<String, dynamic>? ?? {};
        settings = root['settings'] as Map<String, dynamic>? ?? {};
      } else if (root.containsKey('courses') || root.containsKey('tasks')) {
        data = root;
        settings = root;
      } else {
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

      int photosCount = 0;
      final parsedTasks = rawTasks.map((e) => Map<String, dynamic>.from(e)).toList();
      for (final m in parsedTasks) { 
        if (m['isDone'] is bool) m['isDone'] = (m['isDone'] as bool) ? 1 : 0;
        Task.fromJson(m);
        final path = m['imagePath'] as String?;
        if (path != null && path.isNotEmpty) photosCount++;
      }

      final parsedExams = rawExams.map((e) => Map<String, dynamic>.from(e)).toList();
      for (final m in parsedExams) { Exam.fromJson(m); }

      // Tampilkan Konfirmasi UI
      if (!context.mounted) return null;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Konfirmasi Restore'),
          content: Text('Ditemukan ${parsedTasks.length} tugas dan $photosCount foto.\nData saat ini akan ditimpa sepenuhnya. Lanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (confirmed != true) return null;

      // 1. Ekstrak foto ke TEMP
      final appDir = await getTemporaryDirectory();
      tempDir = Directory('${appDir.path}/studyflow_temp_restore');
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      tempDir.createSync(recursive: true);

      // 2. Hapus fisik foto lama dari folder aplikasi
      final oldTasks = await db.queryAll('tasks');
      for (final t in oldTasks) {
        final oldPath = t['imagePath'] as String?;
        if (oldPath != null && oldPath.isNotEmpty) {
          final oldFile = File(oldPath);
          if (oldFile.existsSync()) oldFile.deleteSync();
        }
      }

      // 3. Salin foto baru dari Archive ke folder aplikasi
      final targetAppDir = await getApplicationDocumentsDirectory();
      final taskImagesDir = Directory(p.join(targetAppDir.path, 'task_images'));
      if (!taskImagesDir.existsSync()) {
        taskImagesDir.createSync(recursive: true);
      }

      for (final file in archive) {
        if (file.isFile && file.name.startsWith('photos/')) {
          final fileName = p.basename(file.name);
          final data = file.content as List<int>;
          final targetFile = File(p.join(taskImagesDir.path, fileName));
          targetFile.writeAsBytesSync(data);
        }
      }

      // Update imagePath di parsedTasks agar sesuai dengan targetAppDir
      for (final m in parsedTasks) {
        final oldPath = m['imagePath'] as String?;
        if (oldPath != null && oldPath.isNotEmpty) {
          final fileName = p.basename(oldPath);
          m['imagePath'] = p.join(taskImagesDir.path, fileName);
        }
      }

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

      // Cleanup TEMP
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }

      return 'SUCCESS';
    } catch (e) {
      if (tempDir != null && tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      return 'Terjadi kesalahan saat mengimpor data: ${e.toString()}';
    }
  }
}
