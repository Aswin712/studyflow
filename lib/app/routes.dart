import 'package:flutter/material.dart';
import '../features/schedule/screens/schedule_screen.dart';
import '../features/schedule/screens/schedule_form_screen.dart';
import '../features/course/screens/course_screen.dart';
import '../features/course/screens/course_form_screen.dart';
import '../features/task/screens/task_screen.dart';
import '../features/task/screens/task_form_screen.dart';
import '../features/exam/screens/exam_screen.dart';
import '../features/exam/screens/exam_form_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String schedule = '/schedule';
  static const String scheduleForm = '/schedule/form';
  static const String course = '/course';
  static const String courseForm = '/course/form';
  static const String task = '/task';
  static const String taskForm = '/task/form';
  static const String exam = '/exam';
  static const String examForm = '/exam/form';

  static Map<String, WidgetBuilder> get routes => {
    dashboard: (_) => const DashboardScreen(),
    schedule: (_) => const ScheduleScreen(),
    scheduleForm: (_) => const ScheduleFormScreen(),
    course: (_) => const CourseScreen(),
    courseForm: (_) => const CourseFormScreen(),
    task: (_) => const TaskScreen(),
    taskForm: (_) => const TaskFormScreen(),
    exam: (_) => const ExamScreen(),
    examForm: (_) => const ExamFormScreen(),
  };
}
