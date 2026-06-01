import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/task_provider.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedTaskIds = {};
  
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
        if (_selectedTaskIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTaskIds.add(id);
      }
    });
  }

  void _selectAllDone() {
    final doneTasks = context.read<TaskProvider>().done;
    setState(() {
      _selectedTaskIds.addAll(doneTasks.map((t) => t.id));
      _isSelectionMode = true;
    });
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus tugas terpilih?'),
        content: Text('${_selectedTaskIds.length} tugas akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context.read<TaskProvider>().deleteMultiple(Set.from(_selectedTaskIds));
              setState(() {
                _selectedTaskIds.clear();
                _isSelectionMode = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedTaskIds.length} Terpilih')
            : const Text('Tugas'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedTaskIds.clear();
                }),
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
             IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Pilih semua selesai',
              onPressed: _selectAllDone,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus terpilih',
              onPressed: _selectedTaskIds.isEmpty ? null : _deleteSelected,
            ),
          ] else ...[
            Consumer<TaskProvider>(
              builder: (_, p, __) {
                if (p.showDone && p.done.isNotEmpty) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.checklist),
                        tooltip: 'Pilih tugas selesai',
                        onPressed: () => setState(() => _isSelectionMode = true),
                      ),
                      IconButton(
                        icon: Icon(
                          p.showDone ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        tooltip: p.showDone ? 'Sembunyikan selesai' : 'Tampilkan selesai',
                        onPressed: p.toggleShowDone,
                      ),
                    ],
                  );
                }
                return IconButton(
                  icon: Icon(
                    p.showDone ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                  tooltip: p.showDone ? 'Sembunyikan selesai' : 'Tampilkan selesai',
                  onPressed: p.toggleShowDone,
                );
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari judul tugas atau mata kuliah...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                final courseProvider = context.read<CourseProvider>();
                final allVisibleTasks = provider.visible;
                
                // Filter tasks based on search query
                final tasks = _searchQuery.isEmpty 
                    ? allVisibleTasks 
                    : allVisibleTasks.where((t) {
                        final titleMatch = t.title.toLowerCase().contains(_searchQuery);
                        final course = courseProvider.getById(t.courseId);
                        final courseMatch = course != null && course.name.toLowerCase().contains(_searchQuery);
                        return titleMatch || courseMatch;
                      }).toList();

                if (tasks.isEmpty) {
                  return EmptyStateWidget(
                    icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.checklist_outlined,
                    title: _searchQuery.isNotEmpty 
                        ? 'Tidak ditemukan'
                        : provider.showDone
                            ? 'Belum ada tugas'
                            : 'Semua tugas selesai!',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Coba kata kunci lain'
                        : provider.showDone
                            ? 'Tambah tugas dari mata kuliah kamu'
                            : 'Atau tambah tugas baru',
                    actionLabel: _searchQuery.isNotEmpty ? '' : 'Tambah Tugas',
                    onAction: _searchQuery.isNotEmpty ? () {} : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => _TaskCard(
                    task: tasks[i],
                    isSelectionMode: _isSelectionMode,
                    isSelected: _selectedTaskIds.contains(tasks[i].id),
                    onSelect: () => _toggleSelection(tasks[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onSelect;

  const _TaskCard({
    required this.task, 
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = context.read<CourseProvider>().getById(task.courseId);
    final isLate = AppDateUtils.isDeadlineLewat(task.deadlineDateTime) && !task.isDone;
    final isDekat = AppDateUtils.isDeadlineDekat(task.deadline) && !task.isDone;

    Color priorityColor;
    switch (task.priority) {
      case 3:
        priorityColor = theme.colorScheme.error;
      case 2:
        priorityColor = Colors.orange;
      default:
        priorityColor = theme.colorScheme.outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelectionMode && task.isDone) {
            onSelect();
          } else if (!isSelectionMode) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(task: task)),
            );
          }
        },
        onLongPress: () {
          if (!isSelectionMode && task.isDone) {
            onSelect();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (isSelectionMode && task.isDone)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelect(),
                )
              else
                Checkbox(
                  value: task.isDone,
                  shape: const CircleBorder(),
                  onChanged: isSelectionMode ? null : (_) async {
                    await context.read<TaskProvider>().toggleDone(task.id);
                  },
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                        color: task.isDone
                            ? theme.colorScheme.outline
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (course != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: course.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            course.initials,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (task.hasImage) ...[
                          Icon(
                            Icons.image_outlined,
                            size: 12,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (!task.isDone) ...[
                          Icon(
                            isLate
                                ? Icons.warning_amber_outlined
                                : Icons.schedule,
                            size: 12,
                            color: isLate
                                ? theme.colorScheme.error
                                : isDekat
                                    ? Colors.orange
                                    : theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            AppDateUtils.hitungSisaWaktu(
                                task.deadline, task.deadlineTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isLate
                                  ? theme.colorScheme.error
                                  : isDekat
                                      ? Colors.orange
                                      : theme.colorScheme.outline,
                              fontWeight: isLate || isDekat
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ],
                        if (task.isDone)
                          Text(
                            'Selesai',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tombol hapus untuk tugas selesai
              if (task.isDone && !isSelectionMode)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Hapus tugas',
                  onPressed: () => _confirmDelete(context),
                )
              else if (!task.isDone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppConstants.priorityLabels[task.priority] ?? '',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: priorityColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('"${task.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context.read<TaskProvider>().delete(task.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}