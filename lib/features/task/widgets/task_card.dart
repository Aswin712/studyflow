import 'package:flutter/material.dart';
import '../../../core/models/task.dart';
import '../../../core/models/course.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Course? course;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  const TaskCard({
    super.key,
    required this.task,
    this.course,
    this.onTap,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLate =
        AppDateUtils.isDeadlineLewat(task.deadlineDateTime) && !task.isDone;
    final isDekat = AppDateUtils.isDeadlineDekat(task.deadline) && !task.isDone;

    Color priorityColor = switch (task.priority) {
      3 => theme.colorScheme.error,
      2 => Colors.orange,
      _ => theme.colorScheme.outline,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLate
              ? theme.colorScheme.error.withValues(alpha: 0.5)
              : isDekat && !task.isDone
                  ? Colors.orange.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isLate || (isDekat && !task.isDone) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: task.isDone,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    activeColor: theme.colorScheme.primary,
                    onChanged: onToggle != null ? (_) => onToggle!() : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                          color: task.isDone ? theme.colorScheme.outline : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (course != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: course!.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                course!.initials,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: course!.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(
                            isLate
                                ? Icons.warning_amber_outlined
                                : Icons.schedule_outlined,
                            size: 14,
                            color: isLate
                                ? theme.colorScheme.error
                                : isDekat
                                    ? Colors.orange
                                    : theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.hitungSisaWaktu(
                                task.deadline, task.deadlineTime),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isLate
                                  ? theme.colorScheme.error
                                  : isDekat
                                      ? Colors.orange
                                      : theme.colorScheme.outline,
                              fontWeight:
                                  isLate || isDekat ? FontWeight.bold : FontWeight.w500,
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
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppConstants.priorityLabels[task.priority] ?? '',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: priorityColor,
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
