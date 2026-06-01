class AppConstants {
  // Storage keys
  static const String keyCourses = 'sf_courses';
  static const String keySchedules = 'sf_schedules';
  static const String keyTasks = 'sf_tasks';
  static const String keyExams = 'sf_exams';
  static const String keyThemeMode = 'sf_theme_mode';
  static const String keyUseSystemTheme = 'sf_use_system_theme';
  static const String keyThemePreset = 'sf_theme_preset';
  static const String keyUserName = 'sf_user_name';
  static const String keyFirstLaunch = 'sf_first_launch';

  // Notification channels
  static const String notifChannelId = 'studyflow_channel';
  static const String notifChannelName = 'StudyFlow Reminders';
  static const String notifChannelDesc = 'Reminder ujian dan deadline tugas';

  // Notification IDs (base, actual = base + hash*10 + slot)
  // Exam range: 10000..19999, Task range: 20000..29999
  static const int notifBaseExam = 10000;
  static const int notifBaseTask = 20000;

  // Hari kuliah
  static const List<String> dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  // Prioritas tugas
  static const Map<int, String> priorityLabels = {
    1: 'Rendah',
    2: 'Sedang',
    3: 'Tinggi',
  };

  // Default colors untuk mata kuliah (hex string)
  static const List<String> defaultCourseColors = [
    'FF5C8A',
    'FF9A3C',
    'FFCA3A',
    '6BCB77',
    '4D9FEC',
    'A96CDE',
    'FF6B6B',
    '4ECDC4',
    'F7B731',
    '45AAF2',
  ];
}
