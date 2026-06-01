import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/task_provider.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = context.read<CourseProvider>().getById(task.courseId);
    final isLate =
        AppDateUtils.isDeadlineLewat(task.deadlineDateTime) && !task.isDone;
    final isDekat = AppDateUtils.isDeadlineDekat(task.deadline) && !task.isDone;

    Color statusColor = isLate
        ? theme.colorScheme.error
        : isDekat
            ? Colors.orange
            : theme.colorScheme.outline;

    Color priorityColor = switch (task.priority) {
      3 => theme.colorScheme.error,
      2 => Colors.orange,
      _ => theme.colorScheme.outline,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Foto — tampil di atas kalau ada
          if (task.hasImage) _FotoSection(imagePath: task.imagePath!),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + judul
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: task.isDone,
                      shape: const CircleBorder(),
                      onChanged: (_) {
                        context.read<TaskProvider>().toggleDone(task.id);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 11),
                        child: Text(
                          task.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            decoration:
                                task.isDone ? TextDecoration.lineThrough : null,
                            color:
                                task.isDone ? theme.colorScheme.outline : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mata kuliah
                if (course != null)
                  _InfoRow(
                    icon: Icons.book_outlined,
                    iconColor: course.color,
                    child: Text(
                      course.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 10),

                // Deadline
                _InfoRow(
                  icon: isLate
                      ? Icons.warning_amber_outlined
                      : Icons.schedule_outlined,
                  iconColor: statusColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDateUtils.formatDeadlineLengkap(
                            task.deadline, task.deadlineTime),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        AppDateUtils.hitungSisaWaktu(
                            task.deadline, task.deadlineTime),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Prioritas
                _InfoRow(
                  icon: Icons.flag_outlined,
                  iconColor: priorityColor,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppConstants.priorityLabels[task.priority] ?? '',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: priorityColor),
                    ),
                  ),
                ),

                // Deskripsi
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Deskripsi',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      )),
                  const SizedBox(height: 6),
                  Text(task.description, style: theme.textTheme.bodyMedium),
                ],

                const SizedBox(height: 32),

                // Tombol hapus
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error),
                  label: Text('Hapus Tugas',
                      style: TextStyle(color: theme.colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus tugas?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context.read<TaskProvider>().delete(task.id);
              Navigator.pop(context); // tutup dialog
              Navigator.pop(context); // tutup detail
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

class _FotoSection extends StatelessWidget {
  final String imagePath;
  const _FotoSection({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    if (!file.existsSync()) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullScreenPhoto(file: file),
        ),
      ),
      child: Hero(
        tag: imagePath,
        child: SizedBox(
          width: double.infinity,
          height: 240,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: 800, // decode di resolusi yang lebih kecil
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: frame != null
                    ? child
                    : Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Halaman foto fullscreen dengan Hero animation + pinch-to-zoom
class _FullScreenPhoto extends StatelessWidget {
  final File file;
  const _FullScreenPhoto({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: file.path,
            child: Image.file(
              file,
              cacheWidth: 1200, // full screen tapi tidak oversize
            ),
          ),
        ),
      ),
    );
  }
}
