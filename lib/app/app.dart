import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/database_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/notification_service.dart';
import '../features/course/providers/course_provider.dart';
import '../features/course/repositories/course_repository.dart';
import '../features/schedule/providers/schedule_provider.dart';
import '../features/schedule/repositories/schedule_repository.dart';
import '../features/task/providers/task_provider.dart';
import '../features/task/repositories/task_repository.dart';
import '../features/exam/providers/exam_provider.dart';
import '../features/exam/repositories/exam_repository.dart';
import '../features/settings/setting_provider.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/schedule/screens/schedule_screen.dart';
import '../features/course/screens/course_screen.dart';
import '../features/task/screens/task_screen.dart';
import '../features/exam/screens/exam_screen.dart';
import '../features/task/screens/task_detail_screen.dart';
import '../features/exam/screens/exam_form_screen.dart';
import '../shared/widgets/app_bottom_nav.dart';
import '../shared/widgets/lazy_indexed_stack.dart';
import '../shared/widgets/tutorial_banner_widget.dart';
import '../features/onboarding/screens/onboarding_screen.dart';

import '../core/theme/app_theme.dart';

class StudyFlowApp extends StatelessWidget {
  final DatabaseService db;
  final LocalStorageService storage;
  final NotificationService notif;
  final bool isFirstLaunch;
  final GlobalKey<NavigatorState>? navigatorKey;

  const StudyFlowApp({
    super.key,
    required this.db,
    required this.storage,
    required this.notif,
    this.isFirstLaunch = false,
    this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseProvider(CourseRepository(db)),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(ScheduleRepository(db)),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(TaskRepository(db), notif),
        ),
        ChangeNotifierProvider(
          create: (_) => ExamProvider(ExamRepository(db), notif),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          navigatorKey: navigatorKey,
          title: 'StudyFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(settings.themePreset),
          darkTheme: AppTheme.darkTheme(settings.themePreset),
          themeMode: settings.themeMode,
          home: isFirstLaunch ? const OnboardingScreen() : const MainScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == '/task_detail') {
              final taskId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) {
                  final task = context.read<TaskProvider>().getById(taskId);
                  if (task == null) return const Scaffold(body: Center(child: Text('Tugas tidak ditemukan')));
                  return TaskDetailScreen(task: task);
                },
              );
            }
            if (settings.name == '/exam_detail') {
              final examId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) {
                  final exam = context.read<ExamProvider>().getById(examId);
                  if (exam == null) return const Scaffold(body: Center(child: Text('Ujian tidak ditemukan')));
                  return ExamFormScreen(exam: exam);
                },
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    ScheduleScreen(),
    CourseScreen(),
    TaskScreen(),
    ExamScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Jalankan resync notification di latar belakang saat aplikasi pertama dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = context.read<CourseProvider>();
      String getCourseName(String id) => courseProvider.getById(id)?.name ?? 'Mata Kuliah';
      
      context.read<TaskProvider>().syncNotifications(getCourseName);
      context.read<ExamProvider>().syncNotifications(getCourseName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTutorialCompleted = context.watch<SettingsProvider>().isTutorialCompleted;

    return Scaffold(
      body: Stack(
        children: [
          LazyIndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (!isTutorialCompleted)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: TutorialBannerWidget(
                onNavigateTab: (index) => setState(() => _currentIndex = index),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
