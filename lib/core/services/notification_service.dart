import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/exam.dart';
import '../models/task.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  /// Set true hanya saat debugging notifikasi — menghindari overhead
  /// string interpolation dan list iteration di production.
  static const bool _verbose = false;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Jumlah slot notifikasi per item (task/exam).
  /// Tinggi bisa sampai 7 hari + 1jam + 30menit + 15menit = 10 notif.
  /// Diberi buffer 12 agar tidak terpotong walau ada reminder yang lewat.
  static const int _slotsPerItem = 12;

  Future<void> init({
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
  }) async {
    tz.initializeTimeZones();
    _setLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Request notification permission (Android 13+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  void _setLocalTimezone() {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    String tzName;
    if (offsetHours >= 9) {
      tzName = 'Asia/Jayapura';
    } else if (offsetHours >= 8) {
      tzName = 'Asia/Makassar';
    } else {
      tzName = 'Asia/Jakarta';
    }

    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }
  }

  NotificationDetails _buildDetails({Importance importance = Importance.high}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelId,
          AppConstants.notifChannelName,
          channelDescription: AppConstants.notifChannelDesc,
          importance: importance,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  // ─── TASK NOTIFICATIONS ──────────────────────────────────────────

  /// Schedule notifikasi tugas berdasarkan prioritas:
  /// - Rendah (1): H-1
  /// - Sedang (2): H-3, H-2, H-1, H-0 (hari deadline)
  /// - Tinggi (3): H-6 sampai H-0 (setiap hari) + 1 jam, 30 menit,
  ///   dan 15 menit sebelum deadline
  Future<void> scheduleTaskReminder(Task task, String courseName) async {
    final deadlineDt = task.deadlineDateTime;
    final now = DateTime.now();
    final baseId = _taskBaseId(task.id);

    if (_verbose) {
      debugPrint('\n════════════════════════════════════════════');
      debugPrint('[Notif] SCHEDULING TASK: "${task.title}"');
      debugPrint('[Notif]   courseId   = ${task.courseId}');
      debugPrint('[Notif]   courseName = $courseName');
      debugPrint('[Notif]   priority   = ${task.priority} '
          '(${AppConstants.priorityLabels[task.priority] ?? "unknown"})');
      debugPrint('[Notif]   deadline (date)     = ${task.deadline}');
      debugPrint('[Notif]   deadlineTime        = ${task.deadlineTime}');
      debugPrint('[Notif]   hasSpecificTime     = ${task.hasSpecificTime}');
      debugPrint('[Notif]   deadlineDateTime    = $deadlineDt');
      debugPrint('[Notif]   now                 = $now');
      debugPrint('[Notif]   baseId              = $baseId');
      debugPrint('[Notif]   timezone            = ${tz.local}');
    }

    final timeLabel = task.hasSpecificTime
        ? ' · ${AppDateUtils.formatJam(task.deadlineTime!)}'
        : '';

    final reminders = _buildReminderTimes(
      deadline: deadlineDt,
      priority: task.priority,
    );

    if (_verbose) {
      debugPrint('[Notif]   total reminders built = ${reminders.length}');
    }

    int slot = 0;
    for (final reminder in reminders) {
      if (slot >= _slotsPerItem) {
        if (_verbose) {
          debugPrint('[Notif]   ⚠️ Max slot reached ($slot), stopping');
        }
        break;
      }

      // Skip waktu yang sudah lewat — TIDAK mengkonsumsi slot
      if (reminder.dateTime.isBefore(now)) {
        if (_verbose) {
          debugPrint('[Notif]   SKIP (no slot) — '
              '${reminder.dateTime} sudah lewat (${reminder.label})');
        }
        continue;
      }

      final id = baseId + slot;
      try {
        final tzTime = tz.TZDateTime.from(reminder.dateTime, tz.local);
        if (_verbose) {
          debugPrint('[Notif]   ✅ SCHEDULE slot $slot id=$id '
              'at $tzTime (${reminder.label})');
        }

        await _plugin.zonedSchedule(
          id,
          '${reminder.label}${task.title}',
          '$courseName$timeLabel',
          tzTime,
          _buildDetails(),
          payload: 'task|${task.id}',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        slot++;
      } catch (e) {
        if (_verbose) {
          debugPrint('[Notif]   ❌ ERROR slot $slot: $e');
        }
        slot++;
      }
    }

    if (_verbose) {
      debugPrint('[Notif]   RESULT: $slot notifications scheduled');
      debugPrint('════════════════════════════════════════════\n');

      // Verifikasi: list semua pending notifications
      await _logPendingNotifications();
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    final baseId = _taskBaseId(taskId);
    for (int i = 0; i < _slotsPerItem; i++) {
      await _plugin.cancel(baseId + i);
    }
    if (_verbose) {
      debugPrint('[Notif] CANCELLED all task notifications for $taskId');
    }
  }

  int _taskBaseId(String taskId) {
    // Gunakan modulo yang cukup besar agar minim collision.
    // Range: 20000..29999 (1000 items × 10 slots)
    return AppConstants.notifBaseTask + (taskId.hashCode.abs() % 1000) * _slotsPerItem;
  }

  // ─── EXAM NOTIFICATIONS ──────────────────────────────────────────

  /// Schedule notifikasi ujian: selalu H-1 sebelum ujian.
  Future<void> scheduleExamReminder(Exam exam, String courseName) async {
    final examDateTime = DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
      exam.time.hour,
      exam.time.minute,
    );
    final now = DateTime.now();
    final baseId = _examBaseId(exam.id);

    final timeStr = AppDateUtils.formatJam(exam.time);
    final roomStr = exam.room.isNotEmpty ? ' di ${exam.room}' : '';

    // Notif H-1 jam yang sama dengan ujian
    final reminderH1 = examDateTime.subtract(const Duration(days: 1));
    if (reminderH1.isAfter(now)) {
      try {
        final tzTime = tz.TZDateTime.from(reminderH1, tz.local);
        if (_verbose) {
          debugPrint('[Notif] SCHEDULE exam "${exam.title}" id=$baseId at $tzTime');
        }
        await _plugin.zonedSchedule(
          baseId,
          'Ujian besok: ${exam.title}',
          '$courseName — $timeStr$roomStr',
          tzTime,
          _buildDetails(),
          payload: 'exam|${exam.id}',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        if (_verbose) {
          debugPrint('[Notif] ERROR scheduling exam "${exam.title}": $e');
        }
      }
    }

    // Notif 1 jam sebelum ujian
    final reminder1h = examDateTime.subtract(const Duration(hours: 1));
    if (reminder1h.isAfter(now)) {
      try {
        final tzTime = tz.TZDateTime.from(reminder1h, tz.local);
        if (_verbose) {
          debugPrint('[Notif] SCHEDULE exam 1h "${exam.title}" id=${baseId + 1} at $tzTime');
        }
        await _plugin.zonedSchedule(
          baseId + 1,
          'Ujian 1 jam lagi: ${exam.title}',
          '$courseName — $timeStr$roomStr',
          tzTime,
          _buildDetails(),
          payload: 'exam|${exam.id}',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        if (_verbose) {
          debugPrint('[Notif] ERROR scheduling exam 1h "${exam.title}": $e');
        }
      }
    }
  }

  Future<void> cancelExamReminder(String examId) async {
    final baseId = _examBaseId(examId);
    for (int i = 0; i < _slotsPerItem; i++) {
      await _plugin.cancel(baseId + i);
    }
    if (_verbose) {
      debugPrint('[Notif] CANCELLED all exam notifications for $examId');
    }
  }

  int _examBaseId(String examId) {
    // Range: 10000..19999 (1000 items × 10 slots)
    return AppConstants.notifBaseExam + (examId.hashCode.abs() % 1000) * _slotsPerItem;
  }

  // ─── SHARED LOGIC ────────────────────────────────────────────────

  /// Log semua pending notifications untuk debugging
  Future<void> _logPendingNotifications() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('[Notif] 📋 PENDING NOTIFICATIONS: ${pending.length} total');
      for (final p in pending) {
        debugPrint('[Notif]   📌 id=${p.id} title="${p.title}" '
            'body="${p.body}"');
      }
    } catch (e) {
      debugPrint('[Notif] ERROR listing pending: $e');
    }
  }

  /// Build daftar waktu notifikasi berdasarkan priority.
  /// Semua reminder dijadwalkan pada jam 08:00 kecuali:
  /// - H-0 (hari deadline) tetap jam 08:00
  /// - Notif "1 jam sebelum" (Tinggi) pakai jam deadline - 1h
  /// - Notif "30 menit sebelum" (Tinggi) pakai jam deadline - 30min
  /// - Notif "15 menit sebelum" (Tinggi) pakai jam deadline - 15min
  List<_Reminder> _buildReminderTimes({
    required DateTime deadline,
    required int priority,
  }) {
    final results = <_Reminder>[];

    // Tanggal deadline tanpa jam (untuk hitung hari)
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

    if (_verbose) {
      debugPrint('[Notif]   _buildReminderTimes:');
      debugPrint('[Notif]     deadline     = $deadline');
      debugPrint('[Notif]     deadlineDate = $deadlineDate');
      debugPrint('[Notif]     priority     = $priority');
    }

    switch (priority) {
      case 1: // Rendah — H-1
        final h1 = DateTime(
          deadlineDate.year, deadlineDate.month, deadlineDate.day - 1,
          8, 0,
        );
        results.add(_Reminder(h1, 'Deadline besok: '));
        break;

      case 2: // Sedang — H-3, H-2, H-1, H-0
        for (int d = 3; d >= 0; d--) {
          final dt = DateTime(
            deadlineDate.year, deadlineDate.month, deadlineDate.day - d,
            8, 0,
          );
          final label = d == 0
              ? 'Deadline hari ini: '
              : d == 1
                  ? 'Deadline besok: '
                  : 'Deadline $d hari lagi: ';
          results.add(_Reminder(dt, label));
        }
        break;

      case 3: // Tinggi — H-6 s/d H-0 + 1 jam + 30 menit + 15 menit sebelum
        for (int d = 6; d >= 0; d--) {
          final dt = DateTime(
            deadlineDate.year, deadlineDate.month, deadlineDate.day - d,
            8, 0,
          );
          final label = d == 0
              ? '⚠️ Deadline hari ini: '
              : d == 1
                  ? '⚠️ Deadline besok: '
                  : '⚠️ Deadline $d hari lagi: ';
          results.add(_Reminder(dt, label));
        }
        // 1 jam sebelum deadline
        final oneHourBefore = deadline.subtract(const Duration(hours: 1));
        results.add(_Reminder(oneHourBefore, '🔴 Deadline 1 JAM lagi: '));
        // 30 menit sebelum deadline
        final thirtyMinBefore = deadline.subtract(const Duration(minutes: 30));
        results.add(_Reminder(thirtyMinBefore, '🔴 Deadline 30 MENIT lagi: '));
        // 15 menit sebelum deadline
        final fifteenMinBefore = deadline.subtract(const Duration(minutes: 15));
        results.add(_Reminder(fifteenMinBefore, '🔴 Deadline 15 MENIT lagi: '));
        break;

      default:
        // Fallback: H-1
        final h1 = DateTime(
          deadlineDate.year, deadlineDate.month, deadlineDate.day - 1,
          8, 0,
        );
        results.add(_Reminder(h1, 'Deadline besok: '));
    }

    // Log semua reminder yang dibangun
    if (_verbose) {
      for (int i = 0; i < results.length; i++) {
        debugPrint('[Notif]     reminder[$i] = '
            '${results[i].dateTime} (${results[i].label})');
      }
    }

    return results;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }


}

class _Reminder {
  final DateTime dateTime;
  final String label; // prefix seperti "Deadline besok: "
  const _Reminder(this.dateTime, this.label);
}
