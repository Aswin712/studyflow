import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class DatabaseService {
  static DatabaseService? _instance;
  late Database _db;

  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'studyflow.db');

    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS courses');
          await db.execute('DROP TABLE IF EXISTS tasks');
          await db.execute('DROP TABLE IF EXISTS schedules');
          await db.execute('DROP TABLE IF EXISTS exams');
          await _createTables(db);
        }
      },
    );

    // Lakukan migrasi data dari SharedPreferences jika perlu
    await _migrateFromSharedPreferences();
  }

  Future<void> _createTables(Database db) async {
    // Tabel Courses
    await db.execute('''
      CREATE TABLE courses(
        id TEXT PRIMARY KEY,
        name TEXT,
        sks INTEGER,
        lecturer TEXT,
        room TEXT,
        color INTEGER,
        grade TEXT,
        isCompleted INTEGER
      )
    ''');

    // Tabel Tasks
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        courseId TEXT,
        title TEXT,
        description TEXT,
        deadline TEXT,
        deadlineHour INTEGER,
        deadlineMinute INTEGER,
        priority INTEGER,
        isDone INTEGER,
        imagePath TEXT
      )
    ''');

    // Tabel Schedules
    await db.execute('''
      CREATE TABLE schedules(
        id TEXT PRIMARY KEY,
        courseId TEXT,
        day INTEGER,
        startHour INTEGER,
        startMinute INTEGER,
        endHour INTEGER,
        endMinute INTEGER,
        room TEXT
      )
    ''');

    // Tabel Exams
    await db.execute('''
      CREATE TABLE exams(
        id TEXT PRIMARY KEY,
        courseId TEXT,
        title TEXT,
        date TEXT,
        timeHour INTEGER,
        timeMinute INTEGER,
        room TEXT,
        notes TEXT
      )
    ''');
  }

  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Periksa apakah migrasi sudah pernah dilakukan
    final isMigrated = prefs.getBool('is_sqlite_migrated') ?? false;
    if (isMigrated) return; // Sudah migrasi, hentikan.

    // Migrasi Courses
    final coursesStr = prefs.getString(AppConstants.keyCourses);
    if (coursesStr != null) {
      final List<dynamic> list = jsonDecode(coursesStr);
      final batch = _db.batch();
      for (var item in list) {
        // Konversi boolean ke INTEGER (0/1) jika perlu
        final map = Map<String, dynamic>.from(item);
        if (map['isCompleted'] is bool) {
          map['isCompleted'] = (map['isCompleted'] as bool) ? 1 : 0;
        }
        batch.insert('courses', map, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }

    // Migrasi Tasks
    final tasksStr = prefs.getString(AppConstants.keyTasks);
    if (tasksStr != null) {
      final List<dynamic> list = jsonDecode(tasksStr);
      final batch = _db.batch();
      for (var item in list) {
        final map = Map<String, dynamic>.from(item);
        if (map['isDone'] is bool) {
          map['isDone'] = (map['isDone'] as bool) ? 1 : 0;
        }
        batch.insert('tasks', map, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }

    // Migrasi Schedules
    final schedulesStr = prefs.getString(AppConstants.keySchedules);
    if (schedulesStr != null) {
      final List<dynamic> list = jsonDecode(schedulesStr);
      final batch = _db.batch();
      for (var item in list) {
        batch.insert('schedules', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }

    // Migrasi Exams
    final examsStr = prefs.getString(AppConstants.keyExams);
    if (examsStr != null) {
      final List<dynamic> list = jsonDecode(examsStr);
      final batch = _db.batch();
      for (var item in list) {
        batch.insert('exams', Map<String, dynamic>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }

    // Tandai migrasi sukses
    await prefs.setBool('is_sqlite_migrated', true);
    
    // Hapus data mentah dari SharedPreferences untuk hemat space
    await prefs.remove(AppConstants.keyCourses);
    await prefs.remove(AppConstants.keyTasks);
    await prefs.remove(AppConstants.keySchedules);
    await prefs.remove(AppConstants.keyExams);
  }

  // --- Operasi CRUD Generik ---

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    return await _db.query(table);
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    await _db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<void> update(String table, Map<String, dynamic> data, String idColumn, String idValue) async {
    await _db.update(
      table,
      data,
      where: '$idColumn = ?',
      whereArgs: [idValue],
    );
  }

  Future<void> delete(String table, String idColumn, String idValue) async {
    await _db.delete(
      table,
      where: '$idColumn = ?',
      whereArgs: [idValue],
    );
  }
  
  Future<void> deleteByCourse(String table, String courseId) async {
    await _db.delete(
      table,
      where: 'courseId = ?',
      whereArgs: [courseId],
    );
  }

  // Khusus Backup / Restore
  Future<void> clearTable(String table) async {
    await _db.delete(table);
  }
  
  Future<void> insertBatch(String table, List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    for (var item in items) {
      batch.insert(table, item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
