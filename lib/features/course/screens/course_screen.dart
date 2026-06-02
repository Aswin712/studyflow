import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/course.dart';
import '../providers/course_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../task/providers/task_provider.dart';
import '../../exam/providers/exam_provider.dart';
import 'course_form_screen.dart';
import 'ipk_calculator_screen.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/tutorial_fab_highlight.dart';
import '../../settings/setting_provider.dart';

class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mata Kuliah'),
        actions: [
          Consumer<CourseProvider>(
            builder: (_, p, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ActionChip(
                label: Text('IPK: ${p.currentIpk.toStringAsFixed(2)} | ${p.totalSks} SKS'),
                avatar: const Icon(Icons.school_outlined, size: 16),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IpkCalculatorScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, _) {
          final courses = provider.courses;
          if (courses.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.book_outlined,
              title: 'Belum ada mata kuliah',
              subtitle: 'Tambah mata kuliah semester ini',
              actionLabel: 'Tambah Mata Kuliah',
              onAction: () => _openForm(context),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) =>
                _CourseCard(course: courses[index]),
          );
        },
      ),
      floatingActionButton: Consumer2<SettingsProvider, CourseProvider>(
        builder: (context, settings, courseProvider, child) {
          final isHighlighting = !settings.isTutorialCompleted && courseProvider.courses.isEmpty;
          return TutorialFabHighlight(
            isHighlighting: isHighlighting,
            child: FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {Course? course}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseFormScreen(course: course),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openForm(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar pakai initials dari nama
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: course.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    course.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${course.sks} SKS · ${course.lecturer}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseFormScreen(course: course),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus mata kuliah?'),
        content: Text(
          '${course.name} dan semua jadwal, tugas, serta ujian terkait akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Cascade: hapus semua jadwal, tugas, dan ujian terkait
              context.read<ScheduleProvider>().deleteByCourse(course.id);
              context.read<TaskProvider>().deleteByCourse(course.id);
              context.read<ExamProvider>().deleteByCourse(course.id);
              context.read<CourseProvider>().delete(course.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
