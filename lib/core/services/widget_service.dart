import 'package:home_widget/home_widget.dart';
import 'database_service.dart';
import '../../features/course/repositories/course_repository.dart';
import '../../features/schedule/repositories/schedule_repository.dart';
import '../../features/task/repositories/task_repository.dart';
import '../models/course.dart';

class WidgetService {
  static const String androidWidgetName = 'ScheduleWidgetProvider';

  static Future<void> updateWidgetData() async {
    final db = await DatabaseService.getInstance();
    final courseRepo = CourseRepository(db);
    final scheduleRepo = ScheduleRepository(db);

    final weekday = DateTime.now().weekday - 1;
    final todaySchedules = await scheduleRepo.getByDay(weekday);
    final courses = await courseRepo.getAll();

    final taskRepo = TaskRepository(db);
    final taskList = await taskRepo.getAll();
    final allTasks = taskList.where((t) => !t.isDone).toList();
    
    // Urutkan task berdasarkan deadline terdekat
    allTasks.sort((a, b) => a.deadlineDateTime.compareTo(b.deadlineDateTime));
    
    // Ambil maksimal 3 tugas yang deadlinenya dalam 3 hari ke depan
    final now = DateTime.now();
    final limitDate = now.add(const Duration(days: 3));
    final upcomingTasks = allTasks.where((t) => t.deadlineDateTime.isBefore(limitDate)).take(3).toList();

    String finalMessage = '';

    if (todaySchedules.isEmpty) {
      await HomeWidget.saveWidgetData<String>('widget_title', 'StudyFlow');
      finalMessage = 'Tidak ada jadwal hari ini';
    } else {
      await HomeWidget.saveWidgetData<String>('widget_title', 'Jadwal Hari Ini');

      final buf = StringBuffer();
      for (final s in todaySchedules) {
        Course? course;
        try {
          course = courses.firstWhere((c) => c.id == s.courseId);
        } catch (_) {}

        final name = course?.name ?? 'Unknown';
        final start =
            '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}';
        buf.writeln('$start - $name (${s.room})');
      }
      finalMessage = buf.toString().trim();
    }

    if (upcomingTasks.isNotEmpty) {
      final buf = StringBuffer(finalMessage);
      buf.writeln('\n\n📌 Tugas Terdekat:');
      for (final t in upcomingTasks) {
        buf.writeln('- ${t.title}');
      }
      finalMessage = buf.toString().trim();
    }

    await HomeWidget.saveWidgetData<String>('widget_message', finalMessage);

    await HomeWidget.updateWidget(
      name: androidWidgetName,
    );
  }
}
