import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/course/providers/course_provider.dart';
import '../../features/schedule/providers/schedule_provider.dart';
import '../../features/task/providers/task_provider.dart';
import '../../features/exam/providers/exam_provider.dart';
import '../../features/settings/setting_provider.dart';

class TutorialBannerWidget extends StatelessWidget {
  final Function(int) onNavigateTab;

  const TutorialBannerWidget({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().courses;
    final schedules = context.watch<ScheduleProvider>().all;
    final tasks = context.watch<TaskProvider>().all;
    final exams = context.watch<ExamProvider>().all;
    final settings = context.read<SettingsProvider>();

    String title = '';
    String description = '';
    String buttonText = '';
    int targetTab = 0;
    IconData icon = Icons.info_outline;

    if (courses.isEmpty) {
      title = 'Langkah 1: Mata Kuliah';
      description = 'Tambahkan mata kuliah yang Anda ambil semester ini.';
      buttonText = 'Ke Tab Kuliah';
      targetTab = 2; // Index CourseScreen
      icon = Icons.book;
    } else if (schedules.isEmpty) {
      title = 'Langkah 2: Jadwal Kuliah';
      description = 'Buat jadwal untuk mata kuliah Anda agar tampil di Dashboard.';
      buttonText = 'Ke Tab Jadwal';
      targetTab = 1; // Index ScheduleScreen
      icon = Icons.calendar_today;
    } else if (tasks.isEmpty && exams.isEmpty) {
      title = 'Langkah 3: Tugas / Ujian';
      description = 'Catat tugas atau ujian pertama Anda agar tidak terlewat.';
      buttonText = 'Ke Tab Tugas';
      targetTab = 3; // Index TaskScreen
      icon = Icons.checklist;
    } else {
      // Misi selesai semua! Set status complete di frame berikutnya untuk hindari build error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settings.completeTutorial();
      });
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                // Tombol lewati
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => settings.completeTutorial(),
                  color: theme.colorScheme.onPrimaryContainer,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Lewati panduan',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withAlpha(204), // ~0.8 opacity
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => onNavigateTab(targetTab),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
