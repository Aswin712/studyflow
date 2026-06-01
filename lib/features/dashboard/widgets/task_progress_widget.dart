import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/course.dart';
import '../../course/providers/course_provider.dart';
import '../../task/providers/task_provider.dart';

class TaskProgressWidget extends StatelessWidget {
  const TaskProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProv = context.watch<TaskProvider>();
    final courseProv = context.watch<CourseProvider>();
    final allTasks = taskProv.all;

    if (allTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Belum ada tugas yang ditambahkan',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Total progress
    final totalDone = allTasks.where((t) => t.isDone).length;
    final totalAll = allTasks.length;
    final totalProgress = totalAll > 0 ? totalDone / totalAll : 0.0;

    // Per mata kuliah
    final courses = courseProv.courses;
    final courseStats = <Course, (int done, int total)>{};
    for (final course in courses) {
      final courseTasks =
          allTasks.where((t) => t.courseId == course.id).toList();
      if (courseTasks.isEmpty) continue;
      final done = courseTasks.where((t) => t.isDone).length;
      courseStats[course] = (done, courseTasks.length);
    }

    return Column(
      children: [
        // Total progress card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total selesai',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    '$totalDone / $totalAll tugas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: totalProgress,
                  minHeight: 12,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),

        // Per mata kuliah
        if (courseStats.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...courseStats.entries.map((entry) {
            final course = entry.key;
            final (done, total) = entry.value;
            final progress = total > 0 ? done / total : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: course.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  course.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$done/$total',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor:
                                  course.color.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(course.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
