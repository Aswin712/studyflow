import 'package:flutter/material.dart';
import '../../../core/models/exam.dart';
import '../../../core/models/course.dart';
import '../../../core/utils/date_utils.dart';

class ExamCard extends StatelessWidget {
  final Exam exam;
  final Course? course;
  final VoidCallback? onTap;

  const ExamCard({
    super.key,
    required this.exam,
    this.course,
    this.onTap,
  });

  static const _bulan = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = course?.color ?? theme.colorScheme.primary;
    final isDekat =
        AppDateUtils.isDeadlineDekat(exam.date, hariWarning: 7);
    final sisaHari = AppDateUtils.hitungSisaHari(exam.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDekat
              ? theme.colorScheme.error.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isDekat ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDekat ? theme.colorScheme.error.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isDekat
                        ? theme.colorScheme.error.withValues(alpha: 0.15)
                        : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDekat
                          ? theme.colorScheme.error.withValues(alpha: 0.3)
                          : color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        exam.date.day.toString(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDekat
                              ? theme.colorScheme.error
                              : color,
                        ),
                      ),
                      Text(
                        _bulan[exam.date.month],
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDekat
                              ? theme.colorScheme.error
                              : color,
                          fontWeight: FontWeight.bold,
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
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exam.title,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course?.name ?? 'Mata kuliah tidak ditemukan',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.formatJam(exam.time),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.room_outlined, size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              exam.room,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDekat ? theme.colorScheme.error.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    sisaHari,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDekat
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
