import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/exam.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/exam_provider.dart';
import 'exam_form_screen.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ujian')),
      body: Consumer<ExamProvider>(
        builder: (context, provider, _) {
          final exams = provider.upcoming;
          if (exams.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.school_outlined,
              title: 'Tidak ada ujian mendatang',
              subtitle: 'Tambah jadwal UTS, UAS, atau kuis',
              actionLabel: 'Tambah Ujian',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamFormScreen()),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            itemBuilder: (_, i) => _ExamCard(exam: exams[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = context.read<CourseProvider>().getById(exam.courseId);
    final sisaHari = AppDateUtils.hitungSisaHari(exam.date);
    final isDekat = AppDateUtils.isDeadlineDekat(exam.date, hariWarning: 7);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExamFormScreen(exam: exam)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Countdown bubble
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDekat
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      exam.date.day.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDekat
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      _bulan(exam.date.month),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDekat
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (course?.color ?? theme.colorScheme.primary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            exam.title,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: course?.color ??
                                  theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course?.name ?? 'Mata kuliah tidak ditemukan',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppDateUtils.formatJam(exam.time)} · ${exam.room}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                sisaHari,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDekat
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                  fontWeight: isDekat ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bulan(int month) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return bulan[month];
  }
}
