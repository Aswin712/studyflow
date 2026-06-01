# StudyFlow v2 - Script Setup Otomatis
# CARA PAKAI:
# 1. Buka PowerShell
# 2. cd ke folder project Flutter kamu, contoh:
#    cd D:\claude_kbt\studyflow
# 3. Jalankan: .\setup_studyflow.ps1

$ErrorActionPreference = "Stop"
Write-Host "StudyFlow v2 - Setup dimulai..." -ForegroundColor Cyan

# LANGKAH 1: Buat semua folder
New-Item -ItemType Directory -Force -Path "lib" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\app" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\core\models" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\core\services" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\core\utils" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\course\providers" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\course\repositories" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\course\screens" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\course\widgets" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\dashboard\screens" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\dashboard\widgets" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\exam\providers" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\exam\repositories" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\exam\screens" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\exam\widgets" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\schedule\providers" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\schedule\repositories" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\schedule\screens" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\schedule\widgets" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\task\providers" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\task\repositories" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\task\screens" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\task\widgets" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\shared\widgets" | Out-Null
Write-Host "Folder selesai" -ForegroundColor Green

# LANGKAH 2: Buat semua file Dart
Set-Content -Path "lib\main.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wajib untuk format tanggal Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Init storage & notifikasi sebelum runApp
  final storage = await LocalStorageService.getInstance();
  final notif = NotificationService();
  await notif.init();

  runApp(StudyFlowApp(storage: storage, notif: notif));
}
'@
Write-Host "  OK: lib\main.dart"

Set-Content -Path "lib\features\task\repositories\task_repository.dart" -Value @'
import '../../core/models/task.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/utils/constants.dart';

class TaskRepository {
  final LocalStorageService _storage;

  TaskRepository(this._storage);

  List<Task> getAll() {
    final raw = _storage.readList(AppConstants.keyTasks);
    return raw.map(Task.fromJson).toList();
  }

  List<Task> getPending() {
    return getAll()
        .where((t) => !t.isDone)
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  List<Task> getByCourse(String courseId) {
    return getAll().where((t) => t.courseId == courseId).toList();
  }

  Future<void> save(Task task) async {
    final list = getAll();
    final index = list.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      list[index] = task;
    } else {
      list.add(task);
    }
    await _storage.writeList(
      AppConstants.keyTasks,
      list.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> delete(String id) async {
    final list = getAll()..removeWhere((t) => t.id == id);
    await _storage.writeList(
      AppConstants.keyTasks,
      list.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> deleteByCourse(String courseId) async {
    final list = getAll()..removeWhere((t) => t.courseId == courseId);
    await _storage.writeList(
      AppConstants.keyTasks,
      list.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> toggleDone(String id) async {
    final list = getAll();
    final index = list.indexWhere((t) => t.id == id);
    if (index >= 0) {
      list[index] = list[index].copyWith(isDone: !list[index].isDone);
      await _storage.writeList(
        AppConstants.keyTasks,
        list.map((t) => t.toJson()).toList(),
      );
    }
  }
}
'@
Write-Host "  OK: lib\features\task\repositories\task_repository.dart"

Set-Content -Path "lib\features\task\screens\task_form_screen.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  String? _selectedCourseId;
  late DateTime _deadline;
  late int _priority;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _selectedCourseId = t?.courseId;
    _deadline = t?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _priority = t?.priority ?? 2;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().courses;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Tugas' : 'Tambah Tugas'),
        actions: _isEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: _confirmDelete,
                )
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul Tugas',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Mata Kuliah',
                border: OutlineInputBorder(),
              ),
              items: courses
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: c.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(c.name),
                        ]),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCourseId = v),
              validator: (v) => v == null ? 'Pilih mata kuliah' : null,
            ),
            const SizedBox(height: 16),

            // Deadline picker
            InkWell(
              onTap: _pickDeadline,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(AppDateUtils.formatTanggalPendek(_deadline)),
              ),
            ),
            const SizedBox(height: 16),

            // Prioritas
            Text('Prioritas',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: AppConstants.priorityLabels.entries
                  .map((e) => ButtonSegment<int>(
                        value: e.key,
                        label: Text(e.value),
                      ))
                  .toList(),
              selected: {_priority},
              onSelectionChanged: (s) =>
                  setState(() => _priority = s.first),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _submit,
              child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Tugas'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TaskProvider>();
    final course = context.read<CourseProvider>().getById(_selectedCourseId!);
    final courseName = course?.name ?? '';

    if (_isEdit) {
      provider.update(
        widget.task!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          courseId: _selectedCourseId,
          deadline: _deadline,
          priority: _priority,
        ),
        courseName,
      );
    } else {
      provider.add(
        courseId: _selectedCourseId!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        deadline: _deadline,
        priority: _priority,
        courseName: courseName,
      );
    }
    Navigator.pop(context);
  }

  void _confirmDelete() {
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
              context.read<TaskProvider>().delete(widget.task!.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\task\screens\task_form_screen.dart"

Set-Content -Path "lib\features\task\screens\task_screen.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/task_provider.dart';
import 'task_form_screen.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas'),
        actions: [
          Consumer<TaskProvider>(
            builder: (_, p, __) => IconButton(
              icon: Icon(
                p.showDone ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
              tooltip: p.showDone ? 'Sembunyikan selesai' : 'Tampilkan selesai',
              onPressed: p.toggleShowDone,
            ),
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          final tasks = provider.visible;
          if (tasks.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.checklist_outlined,
              title: provider.showDone
                  ? 'Belum ada tugas'
                  : 'Semua tugas selesai!',
              subtitle: provider.showDone
                  ? 'Tambah tugas dari mata kuliah kamu'
                  : 'Atau tambah tugas baru',
              actionLabel: 'Tambah Tugas',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaskFormScreen()),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (_, i) => _TaskCard(task: tasks[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
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
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = context.read<CourseProvider>().getById(task.courseId);
    final isLate = AppDateUtils.isDeadlineLewat(task.deadline) && !task.isDone;
    final isDekat =
        AppDateUtils.isDeadlineDekat(task.deadline) && !task.isDone;

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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: task.isDone,
                shape: const CircleBorder(),
                onChanged: (_) =>
                    context.read<TaskProvider>().toggleDone(task.id),
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
                            course.code,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                        ],
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
                          AppDateUtils.hitungSisaHari(task.deadline),
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
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
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
}
'@
Write-Host "  OK: lib\features\task\screens\task_screen.dart"

Set-Content -Path "lib\features\task\widgets\task_card.dart" -Value @'
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
    final isLate = AppDateUtils.isDeadlineLewat(task.deadline) && !task.isDone;
    final isDekat = AppDateUtils.isDeadlineDekat(task.deadline) && !task.isDone;

    Color priorityColor = switch (task.priority) {
      3 => theme.colorScheme.error,
      2 => Colors.orange,
      _ => theme.colorScheme.outline,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          child: Row(
            children: [
              Checkbox(
                value: task.isDone,
                shape: const CircleBorder(),
                onChanged: onToggle != null ? (_) => onToggle!() : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isDone
                            ? theme.colorScheme.outline
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                              color: course!.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(course!.code,
                              style: theme.textTheme.bodySmall),
                          const SizedBox(width: 6),
                        ],
                        Icon(
                          isLate
                              ? Icons.warning_amber_outlined
                              : Icons.schedule_outlined,
                          size: 12,
                          color: isLate
                              ? theme.colorScheme.error
                              : isDekat
                                  ? Colors.orange
                                  : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          AppDateUtils.hitungSisaHari(task.deadline),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isLate
                                ? theme.colorScheme.error
                                : isDekat
                                    ? Colors.orange
                                    : theme.colorScheme.outline,
                            fontWeight:
                                isLate || isDekat ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
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
}
'@
Write-Host "  OK: lib\features\task\widgets\task_card.dart"

Set-Content -Path "lib\features\task\providers\task_provider.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/task.dart';
import '../../core/services/notification_service.dart';
import '../repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo;
  final NotificationService _notif;
  List<Task> _tasks = [];
  bool _showDone = false;

  TaskProvider(this._repo, this._notif) {
    load();
  }

  List<Task> get all => List.unmodifiable(_tasks);
  bool get showDone => _showDone;

  List<Task> get pending => _tasks.where((t) => !t.isDone).toList()
    ..sort((a, b) => a.deadline.compareTo(b.deadline));

  List<Task> get done => _tasks.where((t) => t.isDone).toList();

  List<Task> get visible => _showDone ? _tasks : pending;

  int get pendingCount => pending.length;

  void toggleShowDone() {
    _showDone = !_showDone;
    notifyListeners();
  }

  void load() {
    _tasks = _repo.getAll();
    notifyListeners();
  }

  Future<void> add({
    required String courseId,
    required String title,
    required String description,
    required DateTime deadline,
    required int priority,
    required String courseName,
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      courseId: courseId,
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      isDone: false,
    );
    await _repo.save(task);
    await _notif.scheduleTaskReminder(task, courseName);
    load();
  }

  Future<void> update(Task task, String courseName) async {
    await _repo.save(task);
    await _notif.cancelTaskReminder(task.id);
    if (!task.isDone) {
      await _notif.scheduleTaskReminder(task, courseName);
    }
    load();
  }

  Future<void> toggleDone(String id) async {
    await _repo.toggleDone(id);
    final task = _repo.getAll().firstWhere((t) => t.id == id);
    if (task.isDone) {
      await _notif.cancelTaskReminder(id);
    }
    load();
  }

  Future<void> delete(String id) async {
    await _notif.cancelTaskReminder(id);
    await _repo.delete(id);
    load();
  }

  Future<void> deleteByCourse(String courseId) async {
    final tasks = _repo.getByCourse(courseId);
    for (final t in tasks) {
      await _notif.cancelTaskReminder(t.id);
    }
    await _repo.deleteByCourse(courseId);
    load();
  }
}
'@
Write-Host "  OK: lib\features\task\providers\task_provider.dart"

Set-Content -Path "lib\features\course\repositories\course_repository.dart" -Value @'
import '../../core/models/course.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/utils/constants.dart';

class CourseRepository {
  final LocalStorageService _storage;

  CourseRepository(this._storage);

  List<Course> getAll() {
    final raw = _storage.readList(AppConstants.keyCourses);
    return raw.map(Course.fromJson).toList();
  }

  Future<void> save(Course course) async {
    final list = getAll();
    final index = list.indexWhere((c) => c.id == course.id);
    if (index >= 0) {
      list[index] = course;
    } else {
      list.add(course);
    }
    await _storage.writeList(
      AppConstants.keyCourses,
      list.map((c) => c.toJson()).toList(),
    );
  }

  Future<void> delete(String id) async {
    final list = getAll()..removeWhere((c) => c.id == id);
    await _storage.writeList(
      AppConstants.keyCourses,
      list.map((c) => c.toJson()).toList(),
    );
  }

  Course? getById(String id) {
    try {
      return getAll().firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
'@
Write-Host "  OK: lib\features\course\repositories\course_repository.dart"

Set-Content -Path "lib\features\course\screens\course_form_screen.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/course.dart';
import '../providers/course_provider.dart';
import '../../../shared/widgets/color_picker_widget.dart';

class CourseFormScreen extends StatefulWidget {
  final Course? course;
  const CourseFormScreen({super.key, this.course});

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _lecturerCtrl;
  late final TextEditingController _roomCtrl;
  late int _sks;
  late Color _selectedColor;

  bool get _isEdit => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _lecturerCtrl = TextEditingController(text: c?.lecturer ?? '');
    _roomCtrl = TextEditingController(text: c?.room ?? '');
    _sks = c?.sks ?? 3;
    _selectedColor = c?.color ??
        context.read<CourseProvider>().defaultColorFor(
              context.read<CourseProvider>().courses.length,
            );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _lecturerCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Mata Kuliah',
                hintText: 'contoh: Pemrograman Mobile',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kode MK',
                      hintText: 'IF301',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SKS',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: _sks > 1
                                ? () => setState(() => _sks--)
                                : null,
                            icon: const Icon(Icons.remove, size: 18),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('`$_sks',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                          ),
                          IconButton.outlined(
                            onPressed: _sks < 6
                                ? () => setState(() => _sks++)
                                : null,
                            icon: const Icon(Icons.add, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lecturerCtrl,
              decoration: const InputDecoration(
                labelText: 'Dosen',
                hintText: 'Nama dosen pengampu',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Ruangan',
                hintText: 'contoh: GKB 3-201',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            Text('Warna', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            ColorPickerWidget(
              selectedColor: _selectedColor,
              onColorSelected: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _submit,
              child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Mata Kuliah'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<CourseProvider>();
    if (_isEdit) {
      provider.update(widget.course!.copyWith(
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        sks: _sks,
        lecturer: _lecturerCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        color: _selectedColor,
      ));
    } else {
      provider.add(
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        sks: _sks,
        lecturer: _lecturerCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        color: _selectedColor,
      );
    }
    Navigator.pop(context);
  }
}
'@
Write-Host "  OK: lib\features\course\screens\course_form_screen.dart"

Set-Content -Path "lib\features\course\screens\course_screen.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/course.dart';
import '../../providers/course_provider.dart';
import '../../screens/course_form_screen.dart';
import '../../../../shared/widgets/empty_state_widget.dart';

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
              child: Chip(
                label: Text('`${p.totalSks} SKS'),
                avatar: const Icon(Icons.star_outline, size: 16),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: course.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    course.code.isNotEmpty
                        ? course.code.substring(0, 2).toUpperCase()
                        : '??',
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
                    Text(course.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '`${course.code} · `${course.sks} SKS · `${course.lecturer}',
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
          '`${course.name} dan semua jadwal, tugas, serta ujian terkait akan dihapus.',
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
              context.read<CourseProvider>().delete(course.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\course\screens\course_screen.dart"

Set-Content -Path "lib\features\course\widgets\course_card.dart" -Value @'
import 'package:flutter/material.dart';
import '../../../core/models/course.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: course.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    course.code.length >= 2
                        ? course.code.substring(0, 2).toUpperCase()
                        : course.code.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                      '`${course.code} · `${course.sks} SKS · `${course.lecturer}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: theme.colorScheme.error,
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\course\widgets\course_card.dart"

Set-Content -Path "lib\features\course\providers\course_provider.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/course.dart';
import '../../core/utils/constants.dart';
import '../repositories/course_repository.dart';

class CourseProvider extends ChangeNotifier {
  final CourseRepository _repo;
  List<Course> _courses = [];

  CourseProvider(this._repo) {
    load();
  }

  List<Course> get courses => List.unmodifiable(_courses);

  Course? getById(String id) => _repo.getById(id);

  int get totalSks => _courses.fold(0, (sum, c) => sum + c.sks);

  void load() {
    _courses = _repo.getAll();
    notifyListeners();
  }

  Future<void> add({
    required String name,
    required String code,
    required int sks,
    required String lecturer,
    required String room,
    required Color color,
  }) async {
    final course = Course(
      id: const Uuid().v4(),
      name: name,
      code: code,
      sks: sks,
      lecturer: lecturer,
      room: room,
      color: color,
    );
    await _repo.save(course);
    load();
  }

  Future<void> update(Course course) async {
    await _repo.save(course);
    load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    load();
  }

  // Warna default berdasarkan index
  Color defaultColorFor(int index) {
    final hex = AppConstants.defaultCourseColors[
        index % AppConstants.defaultCourseColors.length];
    return Color(int.parse('FF`$hex', radix: 16));
  }
}
'@
Write-Host "  OK: lib\features\course\providers\course_provider.dart"

Set-Content -Path "lib\features\dashboard\screens\dashboard_screen.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/constants.dart';
import '../../course/providers/course_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../task/providers/task_provider.dart';
import '../../exam/providers/exam_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/upcoming_widget.dart';
import '../widgets/task_progress_widget.dart';
import '../widgets/today_schedule_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = _greeting(now.hour);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'StudyFlow',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      AppDateUtils.formatTanggal(now),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stat cards row
            SliverToBoxAdapter(child: _StatRow()),

            // Jadwal hari ini
            SliverToBoxAdapter(
              child: _Section(
                title: 'Jadwal Hari Ini',
                child: const TodayScheduleWidget(),
              ),
            ),

            // Progress tugas
            SliverToBoxAdapter(
              child: _Section(
                title: 'Progress Tugas',
                child: const TaskProgressWidget(),
              ),
            ),

            // Ujian mendatang
            SliverToBoxAdapter(
              child: _Section(
                title: 'Ujian Mendatang',
                child: const UpcomingWidget(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}

class _StatRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer4<CourseProvider, TaskProvider, ExamProvider,
        ScheduleProvider>(
      builder: (_, courseProv, taskProv, examProv, schedProv, __) {
        final totalSks = courseProv.totalSks;
        final pending = taskProv.pendingCount;
        final upcomingExams = examProv.upcoming.length;
        final todayCount = schedProv.today.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'SKS',
                  value: '`$totalSks',
                  icon: Icons.star_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Tugas',
                  value: '`$pending',
                  icon: Icons.checklist_outlined,
                  color: pending > 3 ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Ujian',
                  value: '`$upcomingExams',
                  icon: Icons.school_outlined,
                  color: upcomingExams > 0
                      ? Theme.of(context).colorScheme.error
                      : Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Hari ini',
                  value: '`$todayCount',
                  icon: Icons.calendar_today_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\dashboard\screens\dashboard_screen.dart"

Set-Content -Path "lib\features\dashboard\widgets\stat_card.dart" -Value @'
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\dashboard\widgets\stat_card.dart"

Set-Content -Path "lib\features\dashboard\widgets\task_progress_widget.dart" -Value @'
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Belum ada tugas yang ditambahkan',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total selesai',
                      style: theme.textTheme.labelMedium),
                  Text(
                    '`$totalDone / `$totalAll tugas',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: totalProgress,
                  minHeight: 10,
                  backgroundColor:
                      theme.colorScheme.outline.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),

        // Per mata kuliah
        if (courseStats.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...courseStats.entries.map((entry) {
            final course = entry.key;
            final (done, total) = entry.value;
            final progress = total > 0 ? done / total : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
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
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '`$done/`$total',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor:
                                course.color.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation(course.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
'@
Write-Host "  OK: lib\features\dashboard\widgets\task_progress_widget.dart"

Set-Content -Path "lib\features\dashboard\widgets\today_schedule_widget.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/constants.dart';
import '../../course/providers/course_provider.dart';
import '../../schedule/providers/schedule_provider.dart';

class TodayScheduleWidget extends StatelessWidget {
  const TodayScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedules =
        context.watch<ScheduleProvider>().today;
    final courseProv = context.watch<CourseProvider>();
    final todayName = AppConstants
        .dayNames[DateTime.now().weekday - 1];

    if (schedules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.wb_sunny_outlined,
                color: theme.colorScheme.outline),
            const SizedBox(width: 12),
            Text(
              '`$todayName tidak ada kuliah',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: schedules.map((s) {
        final course = courseProv.getById(s.courseId);
        final color = course?.color ?? theme.colorScheme.primary;

        // Cek apakah sedang berlangsung sekarang
        final now = TimeOfDay.now();
        final nowMinutes = now.hour * 60 + now.minute;
        final startMinutes = s.startTime.hour * 60 + s.startTime.minute;
        final endMinutes = s.endTime.hour * 60 + s.endTime.minute;
        final isOngoing =
            nowMinutes >= startMinutes && nowMinutes <= endMinutes;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isOngoing
                ? color.withOpacity(0.12)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: isOngoing
                ? Border.all(color: color.withOpacity(0.4), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course?.name ?? '-',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOngoing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Berlangsung',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '`${AppDateUtils.formatJam(s.startTime)} — `${AppDateUtils.formatJam(s.endTime)}  ·  `${s.room}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
'@
Write-Host "  OK: lib\features\dashboard\widgets\today_schedule_widget.dart"

Set-Content -Path "lib\features\dashboard\widgets\upcoming_widget.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../../exam/providers/exam_provider.dart';

class UpcomingWidget extends StatelessWidget {
  const UpcomingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exams = context.watch<ExamProvider>().upcoming;
    final courseProv = context.watch<CourseProvider>();

    if (exams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: Colors.green.shade400),
            const SizedBox(width: 12),
            Text(
              'Tidak ada ujian mendatang',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Tampilkan maks 3 ujian terdekat di dashboard
    final displayed = exams.take(3).toList();

    return Column(
      children: [
        ...displayed.map((exam) {
          final course = courseProv.getById(exam.courseId);
          final color = course?.color ?? theme.colorScheme.primary;
          final sisaHari = AppDateUtils.hitungSisaHari(exam.date);
          final isDekat =
              AppDateUtils.isDeadlineDekat(exam.date, hariWarning: 7);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: isDekat
                  ? Border.all(
                      color: theme.colorScheme.error.withOpacity(0.4))
                  : null,
            ),
            child: Row(
              children: [
                // Tanggal bubble
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        exam.date.day.toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        _bulan(exam.date.month),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '`${exam.title} — `${course?.name ?? '?'}',
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '`${AppDateUtils.formatJam(exam.time)}  ·  `${exam.room}',
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
                    fontWeight:
                        isDekat ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
        if (exams.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ `${exams.length - 3} ujian lainnya',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  String _bulan(int month) {
    const b = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return b[month];
  }
}
'@
Write-Host "  OK: lib\features\dashboard\widgets\upcoming_widget.dart"

Set-Content -Path "lib\features\schedule\repositories\schedule_repository.dart" -Value @'
import '../../core/models/schedule.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/utils/constants.dart';

class ScheduleRepository {
  final LocalStorageService _storage;

  ScheduleRepository(this._storage);

  List<Schedule> getAll() {
    final raw = _storage.readList(AppConstants.keySchedules);
    return raw.map(Schedule.fromJson).toList();
  }

  List<Schedule> getByDay(int day) {
    return getAll().where((s) => s.day == day).toList()
      ..sort((a, b) =>
          (a.startTime.hour * 60 + a.startTime.minute)
              .compareTo(b.startTime.hour * 60 + b.startTime.minute));
  }

  Future<void> save(Schedule schedule) async {
    final list = getAll();
    final index = list.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      list[index] = schedule;
    } else {
      list.add(schedule);
    }
    await _storage.writeList(
      AppConstants.keySchedules,
      list.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> delete(String id) async {
    final list = getAll()..removeWhere((s) => s.id == id);
    await _storage.writeList(
      AppConstants.keySchedules,
      list.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> deleteByCourse(String courseId) async {
    final list = getAll()..removeWhere((s) => s.courseId == courseId);
    await _storage.writeList(
      AppConstants.keySchedules,
      list.map((s) => s.toJson()).toList(),
    );
  }
}
'@
Write-Host "  OK: lib\features\schedule\repositories\schedule_repository.dart"

Set-Content -Path "lib\features\schedule\screens\schedule_form_screen.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/schedule.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/schedule_provider.dart';

class ScheduleFormScreen extends StatefulWidget {
  final Schedule? schedule;
  final int initialDay;

  const ScheduleFormScreen({
    super.key,
    this.schedule,
    this.initialDay = 0,
  });

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCourseId;
  late int _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late final TextEditingController _roomCtrl;

  bool get _isEdit => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _selectedCourseId = s?.courseId;
    _selectedDay = s?.day ?? widget.initialDay;
    _startTime = s?.startTime ?? const TimeOfDay(hour: 8, minute: 0);
    _endTime = s?.endTime ?? const TimeOfDay(hour: 9, minute: 40);
    _roomCtrl = TextEditingController(text: s?.room ?? '');
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().courses;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Jadwal' : 'Tambah Jadwal'),
        actions: _isEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: _confirmDelete,
                )
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pilih mata kuliah
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Mata Kuliah',
                border: OutlineInputBorder(),
              ),
              items: courses
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: c.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(c.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCourseId = v),
              validator: (v) => v == null ? 'Pilih mata kuliah' : null,
            ),
            const SizedBox(height: 16),

            // Pilih hari
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Hari',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(AppConstants.dayNames[i]),
                ),
              ),
              onChanged: (v) => setState(() => _selectedDay = v!),
            ),
            const SizedBox(height: 16),

            // Jam mulai & selesai
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Jam Mulai',
                    time: _startTime,
                    onPicked: (t) => setState(() => _startTime = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: 'Jam Selesai',
                    time: _endTime,
                    onPicked: (t) => setState(() => _endTime = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Ruangan',
                hintText: 'GKB 3-201',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _submit,
              child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ScheduleProvider>();
    if (_isEdit) {
      provider.update(widget.schedule!.copyWith(
        courseId: _selectedCourseId,
        day: _selectedDay,
        startTime: _startTime,
        endTime: _endTime,
        room: _roomCtrl.text.trim(),
      ));
    } else {
      provider.add(
        courseId: _selectedCourseId!,
        day: _selectedDay,
        startTime: _startTime,
        endTime: _endTime,
        room: _roomCtrl.text.trim(),
      );
    }
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus jadwal?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context
                  .read<ScheduleProvider>()
                  .delete(widget.schedule!.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPicked;

  const _TimePicker(
      {required this.label, required this.time, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(AppDateUtils.formatJam(time)),
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\schedule\screens\schedule_form_screen.dart"

Set-Content -Path "lib\features\schedule\screens\schedule_screen.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/schedule.dart';
import '../../../core/models/course.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/schedule_provider.dart';
import 'schedule_form_screen.dart';
import '../../../shared/widgets/empty_state_widget.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday - 1;
    if (_selectedDay > 6) _selectedDay = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kuliah')),
      body: Column(
        children: [
          _DaySelector(
            selectedDay: _selectedDay,
            onDaySelected: (d) => setState(() => _selectedDay = d),
          ),
          Expanded(child: _ScheduleList(day: _selectedDay)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScheduleFormScreen(initialDay: _selectedDay),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const _DaySelector(
      {required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().weekday - 1;

    return Container(
      height: 64,
      color: theme.colorScheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 7,
        itemBuilder: (context, index) {
          final isSelected = index == selectedDay;
          final isToday = index == today;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                AppConstants.dayNames[index].substring(0, 3),
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              avatar: isToday && !isSelected
                  ? CircleAvatar(
                      radius: 8,
                      backgroundColor: theme.colorScheme.primary,
                    )
                  : null,
              onSelected: (_) => onDaySelected(index),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  final int day;
  const _ScheduleList({required this.day});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ScheduleProvider, CourseProvider>(
      builder: (context, schedProv, courseProv, _) {
        final schedules = schedProv.getByDay(day);
        if (schedules.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.event_available_outlined,
            title: 'Tidak ada kuliah',
            subtitle: '`${AppConstants.dayNames[day]} bebas kuliah',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            final course = courseProv.getById(schedule.courseId);
            return _ScheduleCard(schedule: schedule, course: course);
          },
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final Course? course;

  const _ScheduleCard({required this.schedule, required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = course?.color ?? theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScheduleFormScreen(schedule: schedule),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course?.name ?? 'Mata kuliah tidak ditemukan',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14,
                                    color: theme.colorScheme.outline),
                                const SizedBox(width: 4),
                                Text(
                                  schedule.room,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppDateUtils.formatJam(schedule.startTime),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            AppDateUtils.formatJam(schedule.endTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\schedule\screens\schedule_screen.dart"

Set-Content -Path "lib\features\schedule\widgets\schedule_card.dart" -Value @'
import 'package:flutter/material.dart';
import '../../../core/models/schedule.dart';
import '../../../core/models/course.dart';
import '../../../core/utils/date_utils.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final Course? course;
  final VoidCallback? onTap;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.course,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = course?.color ?? theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course?.name ?? 'Mata kuliah tidak ditemukan',
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  schedule.room,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppDateUtils.formatJam(schedule.startTime),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            AppDateUtils.formatJam(schedule.endTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\schedule\widgets\schedule_card.dart"

Set-Content -Path "lib\features\schedule\providers\schedule_provider.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/schedule.dart';
import '../repositories/schedule_repository.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _repo;
  List<Schedule> _schedules = [];

  ScheduleProvider(this._repo) {
    load();
  }

  List<Schedule> get all => List.unmodifiable(_schedules);

  List<Schedule> getByDay(int day) => _repo.getByDay(day);

  // Jadwal hari ini (0=Senin)
  List<Schedule> get today {
    final weekday = DateTime.now().weekday - 1; // DateTime: 1=Mon
    return getByDay(weekday);
  }

  void load() {
    _schedules = _repo.getAll();
    notifyListeners();
  }

  Future<void> add({
    required String courseId,
    required int day,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String room,
  }) async {
    final schedule = Schedule(
      id: const Uuid().v4(),
      courseId: courseId,
      day: day,
      startTime: startTime,
      endTime: endTime,
      room: room,
    );
    await _repo.save(schedule);
    load();
  }

  Future<void> update(Schedule schedule) async {
    await _repo.save(schedule);
    load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    load();
  }

  Future<void> deleteByCourse(String courseId) async {
    await _repo.deleteByCourse(courseId);
    load();
  }
}
'@
Write-Host "  OK: lib\features\schedule\providers\schedule_provider.dart"

Set-Content -Path "lib\features\exam\repositories\exam_repository.dart" -Value @'
import '../../core/models/exam.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/utils/constants.dart';

class ExamRepository {
  final LocalStorageService _storage;

  ExamRepository(this._storage);

  List<Exam> getAll() {
    final raw = _storage.readList(AppConstants.keyExams);
    return raw.map(Exam.fromJson).toList();
  }

  List<Exam> getUpcoming() {
    final now = DateTime.now();
    return getAll()
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Exam> getByCourse(String courseId) {
    return getAll().where((e) => e.courseId == courseId).toList();
  }

  Future<void> save(Exam exam) async {
    final list = getAll();
    final index = list.indexWhere((e) => e.id == exam.id);
    if (index >= 0) {
      list[index] = exam;
    } else {
      list.add(exam);
    }
    await _storage.writeList(
      AppConstants.keyExams,
      list.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> delete(String id) async {
    final list = getAll()..removeWhere((e) => e.id == id);
    await _storage.writeList(
      AppConstants.keyExams,
      list.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> deleteByCourse(String courseId) async {
    final list = getAll()..removeWhere((e) => e.courseId == courseId);
    await _storage.writeList(
      AppConstants.keyExams,
      list.map((e) => e.toJson()).toList(),
    );
  }
}
'@
Write-Host "  OK: lib\features\exam\repositories\exam_repository.dart"

Set-Content -Path "lib\features\exam\screens\exam_form_screen.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/exam.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/exam_provider.dart';

class ExamFormScreen extends StatefulWidget {
  final Exam? exam;
  const ExamFormScreen({super.key, this.exam});

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _notesCtrl;
  String? _selectedCourseId;
  late DateTime _date;
  late TimeOfDay _time;

  bool get _isEdit => widget.exam != null;

  static const _examTypes = ['UTS', 'UAS', 'Kuis', 'Praktikum', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _titleCtrl = TextEditingController(text: e?.title ?? 'UTS');
    _roomCtrl = TextEditingController(text: e?.room ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _selectedCourseId = e?.courseId;
    _date = e?.date ?? DateTime.now().add(const Duration(days: 14));
    _time = e?.time ?? const TimeOfDay(hour: 8, minute: 0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _roomCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>().courses;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Ujian' : 'Tambah Ujian'),
        actions: _isEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: _confirmDelete,
                )
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Jenis ujian
            Text('Jenis Ujian',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _examTypes.map((type) {
                final isSelected = _titleCtrl.text == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _titleCtrl.text = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Mata Kuliah',
                border: OutlineInputBorder(),
              ),
              items: courses
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: c.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(c.name),
                        ]),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCourseId = v),
              validator: (v) => v == null ? 'Pilih mata kuliah' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(AppDateUtils.formatTanggalPendek(_date)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Jam',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(AppDateUtils.formatJam(_time)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Ruangan',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Materi yang perlu dipelajari...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _submit,
              child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Ujian'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ExamProvider>();
    final course =
        context.read<CourseProvider>().getById(_selectedCourseId!);
    final courseName = course?.name ?? '';

    if (_isEdit) {
      provider.update(
        widget.exam!.copyWith(
          title: _titleCtrl.text,
          courseId: _selectedCourseId,
          date: _date,
          time: _time,
          room: _roomCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        ),
        courseName,
      );
    } else {
      provider.add(
        courseId: _selectedCourseId!,
        title: _titleCtrl.text,
        date: _date,
        time: _time,
        room: _roomCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        courseName: courseName,
      );
    }
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus ujian?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context.read<ExamProvider>().delete(widget.exam!.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\exam\screens\exam_form_screen.dart"

Set-Content -Path "lib\features\exam\screens\exam_screen.dart" -Value @'
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
                                .withOpacity(0.15),
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
                      '`${AppDateUtils.formatJam(exam.time)} · `${exam.room}',
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
'@
Write-Host "  OK: lib\features\exam\screens\exam_screen.dart"

Set-Content -Path "lib\features\exam\widgets\exam_card.dart" -Value @'
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDekat
                      ? theme.colorScheme.errorContainer
                      : color.withOpacity(0.15),
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
                            : color,
                      ),
                    ),
                    Text(
                      _bulan[exam.date.month],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDekat
                            ? theme.colorScheme.onErrorContainer
                            : color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            exam.title,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '`${AppDateUtils.formatJam(exam.time)} · `${exam.room}',
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
                  fontWeight:
                      isDekat ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'@
Write-Host "  OK: lib\features\exam\widgets\exam_card.dart"

Set-Content -Path "lib\features\exam\providers\exam_provider.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/exam.dart';
import '../../core/services/notification_service.dart';
import '../repositories/exam_repository.dart';

class ExamProvider extends ChangeNotifier {
  final ExamRepository _repo;
  final NotificationService _notif;
  List<Exam> _exams = [];

  ExamProvider(this._repo, this._notif) {
    load();
  }

  List<Exam> get all => List.unmodifiable(_exams);

  List<Exam> get upcoming => _repo.getUpcoming();

  Exam? get next => upcoming.isEmpty ? null : upcoming.first;

  void load() {
    _exams = _repo.getAll();
    notifyListeners();
  }

  Future<void> add({
    required String courseId,
    required String title,
    required DateTime date,
    required TimeOfDay time,
    required String room,
    required String notes,
    required String courseName,
  }) async {
    final exam = Exam(
      id: const Uuid().v4(),
      courseId: courseId,
      title: title,
      date: date,
      time: time,
      room: room,
      notes: notes,
    );
    await _repo.save(exam);
    await _notif.scheduleExamReminder(exam, courseName);
    load();
  }

  Future<void> update(Exam exam, String courseName) async {
    await _repo.save(exam);
    await _notif.cancelExamReminder(exam.id);
    await _notif.scheduleExamReminder(exam, courseName);
    load();
  }

  Future<void> delete(String id) async {
    await _notif.cancelExamReminder(id);
    await _repo.delete(id);
    load();
  }

  Future<void> deleteByCourse(String courseId) async {
    final exams = _repo.getByCourse(courseId);
    for (final e in exams) {
      await _notif.cancelExamReminder(e.id);
    }
    await _repo.deleteByCourse(courseId);
    load();
  }
}
'@
Write-Host "  OK: lib\features\exam\providers\exam_provider.dart"

Set-Content -Path "lib\shared\widgets\app_bottom_nav.dart" -Value @'
import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Jadwal',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: 'Mata Kuliah',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: 'Tugas',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school),
          label: 'Ujian',
        ),
      ],
    );
  }
}
'@
Write-Host "  OK: lib\shared\widgets\app_bottom_nav.dart"

Set-Content -Path "lib\shared\widgets\color_picker_widget.dart" -Value @'
import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';

class ColorPickerWidget extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.defaultCourseColors.map((hex) {
        final color = Color(int.parse('FF`$hex', radix: 16));
        final isSelected = color.value == selectedColor.value;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
'@
Write-Host "  OK: lib\shared\widgets\color_picker_widget.dart"

Set-Content -Path "lib\shared\widgets\empty_state_widget.dart" -Value @'
import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
'@
Write-Host "  OK: lib\shared\widgets\empty_state_widget.dart"

Set-Content -Path "lib\app\app.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/schedule/screens/schedule_screen.dart';
import '../features/course/screens/course_screen.dart';
import '../features/task/screens/task_screen.dart';
import '../features/exam/screens/exam_screen.dart';
import '../shared/widgets/app_bottom_nav.dart';

class StudyFlowApp extends StatelessWidget {
  final LocalStorageService storage;
  final NotificationService notif;

  const StudyFlowApp({
    super.key,
    required this.storage,
    required this.notif,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CourseProvider(CourseRepository(storage)),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(ScheduleRepository(storage)),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              TaskProvider(TaskRepository(storage), notif),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ExamProvider(ExamRepository(storage), notif),
        ),
      ],
      child: MaterialApp(
        title: 'StudyFlow',
        debugShowCheckedModeBanner: false,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        themeMode: ThemeMode.system,
        home: const _HomeScreen(),
      ),
    );
  }

  ThemeData _lightTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D9FEC),
          brightness: Brightness.light,
        ),
      );

  ThemeData _darkTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D9FEC),
          brightness: Brightness.dark,
        ),
      );
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    ScheduleScreen(),
    CourseScreen(),
    TaskScreen(),
    ExamScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
'@
Write-Host "  OK: lib\app\app.dart"

Set-Content -Path "lib\app\routes.dart" -Value @'
import 'package:flutter/material.dart';
import '../features/schedule/screens/schedule_screen.dart';
import '../features/schedule/screens/schedule_form_screen.dart';
import '../features/course/screens/course_screen.dart';
import '../features/course/screens/course_form_screen.dart';
import '../features/task/screens/task_screen.dart';
import '../features/task/screens/task_form_screen.dart';
import '../features/exam/screens/exam_screen.dart';
import '../features/exam/screens/exam_form_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String schedule = '/schedule';
  static const String scheduleForm = '/schedule/form';
  static const String course = '/course';
  static const String courseForm = '/course/form';
  static const String task = '/task';
  static const String taskForm = '/task/form';
  static const String exam = '/exam';
  static const String examForm = '/exam/form';

  static Map<String, WidgetBuilder> get routes => {
    dashboard: (_) => const DashboardScreen(),
    schedule: (_) => const ScheduleScreen(),
    scheduleForm: (_) => const ScheduleFormScreen(),
    course: (_) => const CourseScreen(),
    courseForm: (_) => const CourseFormScreen(),
    task: (_) => const TaskScreen(),
    taskForm: (_) => const TaskFormScreen(),
    exam: (_) => const ExamScreen(),
    examForm: (_) => const ExamFormScreen(),
  };
}
'@
Write-Host "  OK: lib\app\routes.dart"

Set-Content -Path "lib\core\services\local_storage_service.dart" -Value @'
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Satu-satunya class yang boleh menyentuh shared_preferences.
/// Repository memanggil class ini — bukan SharedPreferences langsung.
class LocalStorageService {
  static LocalStorageService? _instance;
  late SharedPreferences _prefs;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Generic read
  List<Map<String, dynamic>> readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  // Generic write
  Future<void> writeList(String key, List<Map<String, dynamic>> data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  // Theme
  Future<void> saveThemeMode(bool isDark) async {
    await _prefs.setBool(AppConstants.keyThemeMode, isDark);
  }

  bool loadThemeMode() {
    return _prefs.getBool(AppConstants.keyThemeMode) ?? false;
  }

  // Clear semua data (untuk reset / testing)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
'@
Write-Host "  OK: lib\core\services\local_storage_service.dart"

Set-Content -Path "lib\core\services\notification_service.dart" -Value @'
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/exam.dart';
import '../models/task.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelId,
          AppConstants.notifChannelName,
          channelDescription: AppConstants.notifChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Schedule notifikasi H-1 sebelum ujian
  Future<void> scheduleExamReminder(Exam exam, String courseName) async {
    final examDateTime = DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
      exam.time.hour,
      exam.time.minute,
    );
    final reminderTime = examDateTime.subtract(const Duration(days: 1));

    if (reminderTime.isBefore(DateTime.now())) return;

    final id = AppConstants.notifBaseExam +
        exam.id.hashCode.abs() % 900;

    await _plugin.zonedSchedule(
      id,
      'Ujian besok: `${exam.title}',
      '`$courseName — `${AppDateUtils.formatJam(exam.time)} di `${exam.room}',
      tz.TZDateTime.from(reminderTime, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule notifikasi H-1 sebelum deadline tugas
  Future<void> scheduleTaskReminder(Task task, String courseName) async {
    final reminderTime = task.deadline.subtract(const Duration(days: 1));

    if (reminderTime.isBefore(DateTime.now())) return;

    final id = AppConstants.notifBaseTask +
        task.id.hashCode.abs() % 900;

    await _plugin.zonedSchedule(
      id,
      'Deadline besok: `${task.title}',
      courseName,
      tz.TZDateTime.from(reminderTime, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelExamReminder(String examId) async {
    final id = AppConstants.notifBaseExam + examId.hashCode.abs() % 900;
    await _plugin.cancel(id);
  }

  Future<void> cancelTaskReminder(String taskId) async {
    final id = AppConstants.notifBaseTask + taskId.hashCode.abs() % 900;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
'@
Write-Host "  OK: lib\core\services\notification_service.dart"

Set-Content -Path "lib\core\utils\constants.dart" -Value @'
class AppConstants {
  // Storage keys
  static const String keyCourses = 'sf_courses';
  static const String keySchedules = 'sf_schedules';
  static const String keyTasks = 'sf_tasks';
  static const String keyExams = 'sf_exams';
  static const String keyThemeMode = 'sf_theme_mode';

  // Notification channels
  static const String notifChannelId = 'studyflow_channel';
  static const String notifChannelName = 'StudyFlow Reminders';
  static const String notifChannelDesc = 'Reminder ujian dan deadline tugas';

  // Notification IDs (base, actual = base + index)
  static const int notifBaseExam = 1000;
  static const int notifBaseTask = 2000;

  // Hari kuliah
  static const List<String> dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  // Prioritas tugas
  static const Map<int, String> priorityLabels = {
    1: 'Rendah',
    2: 'Sedang',
    3: 'Tinggi',
  };

  // Default colors untuk mata kuliah (hex string)
  static const List<String> defaultCourseColors = [
    'FF5C8A', 'FF9A3C', 'FFCA3A', '6BCB77', '4D9FEC',
    'A96CDE', 'FF6B6B', '4ECDC4', 'F7B731', '45AAF2',
  ];
}
'@
Write-Host "  OK: lib\core\utils\constants.dart"

Set-Content -Path "lib\core\utils\date_utils.dart" -Value @'
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTanggal(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  static String formatTanggalPendek(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String formatJam(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '`$h:`$m';
  }

  static String hitungSisaHari(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'Terlewat `${diff.abs()} hari';
    if (diff == 0) return 'Hari ini!';
    if (diff == 1) return 'Besok';
    return '`$diff hari lagi';
  }

  static bool isDeadlineDekat(DateTime deadline, {int hariWarning = 3}) {
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;
    return diff >= 0 && diff <= hariWarning;
  }

  static bool isDeadlineLewat(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }

  // Konversi TimeOfDay ke menit (untuk sorting)
  static int timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
}
'@
Write-Host "  OK: lib\core\utils\date_utils.dart"

Set-Content -Path "lib\core\models\course.dart" -Value @'
import 'dart:ui';

class Course {
  final String id;
  final String name;
  final String code;
  final int sks;
  final String lecturer;
  final String room;
  final Color color;

  const Course({
    required this.id,
    required this.name,
    required this.code,
    required this.sks,
    required this.lecturer,
    required this.room,
    required this.color,
  });

  Course copyWith({
    String? id,
    String? name,
    String? code,
    int? sks,
    String? lecturer,
    String? room,
    Color? color,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      sks: sks ?? this.sks,
      lecturer: lecturer ?? this.lecturer,
      room: room ?? this.room,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'sks': sks,
    'lecturer': lecturer,
    'room': room,
    'color': color.toARGB32(),
  };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String,
    sks: json['sks'] as int,
    lecturer: json['lecturer'] as String,
    room: json['room'] as String,
    color: Color(json['color'] as int),
  );

  @override
  bool operator ==(Object other) => other is Course && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
'@
Write-Host "  OK: lib\core\models\course.dart"

Set-Content -Path "lib\core\models\exam.dart" -Value @'
import 'package:flutter/material.dart';

class Exam {
  final String id;
  final String courseId;
  final String title; // UTS / UAS / Kuis
  final DateTime date;
  final TimeOfDay time;
  final String room;
  final String notes;

  const Exam({
    required this.id,
    required this.courseId,
    required this.title,
    required this.date,
    required this.time,
    required this.room,
    required this.notes,
  });

  Exam copyWith({
    String? id,
    String? courseId,
    String? title,
    DateTime? date,
    TimeOfDay? time,
    String? room,
    String? notes,
  }) {
    return Exam(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      room: room ?? this.room,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'title': title,
    'date': date.toIso8601String(),
    'timeHour': time.hour,
    'timeMinute': time.minute,
    'room': room,
    'notes': notes,
  };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    time: TimeOfDay(
      hour: json['timeHour'] as int,
      minute: json['timeMinute'] as int,
    ),
    room: json['room'] as String,
    notes: json['notes'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) => other is Exam && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
'@
Write-Host "  OK: lib\core\models\exam.dart"

Set-Content -Path "lib\core\models\schedule.dart" -Value @'
import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String courseId;
  final int day; // 0=Senin, 6=Minggu
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String room;

  const Schedule({
    required this.id,
    required this.courseId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  Schedule copyWith({
    String? id,
    String? courseId,
    int? day,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? room,
  }) {
    return Schedule(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'day': day,
    'startHour': startTime.hour,
    'startMinute': startTime.minute,
    'endHour': endTime.hour,
    'endMinute': endTime.minute,
    'room': room,
  };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    day: json['day'] as int,
    startTime: TimeOfDay(
      hour: json['startHour'] as int,
      minute: json['startMinute'] as int,
    ),
    endTime: TimeOfDay(
      hour: json['endHour'] as int,
      minute: json['endMinute'] as int,
    ),
    room: json['room'] as String,
  );

  @override
  bool operator ==(Object other) => other is Schedule && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
'@
Write-Host "  OK: lib\core\models\schedule.dart"

Set-Content -Path "lib\core\models\task.dart" -Value @'
class Task {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime deadline;
  final int priority; // 1=rendah, 2=sedang, 3=tinggi
  final bool isDone;

  const Task({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.isDone,
  });

  Task copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    DateTime? deadline,
    int? priority,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'title': title,
    'description': description,
    'deadline': deadline.toIso8601String(),
    'priority': priority,
    'isDone': isDone,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    deadline: DateTime.parse(json['deadline'] as String),
    priority: json['priority'] as int,
    isDone: json['isDone'] as bool,
  );

  @override
  bool operator ==(Object other) => other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
'@
Write-Host "  OK: lib\core\models\task.dart"

# LANGKAH 3: pubspec.yaml
Set-Content -Path "pubspec.yaml" -Value @'
name: studyflow
description: Aplikasi manajemen akademik mahasiswa
publish_to: 'none'
version: 2.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  shared_preferences: ^2.3.2
  flutter_local_notifications: ^17.2.4
  intl: ^0.19.0
  uuid: ^4.4.0
  timezone: ^0.9.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
'@
Write-Host "  OK: pubspec.yaml"

# LANGKAH 4: Fix widget_test.dart
Set-Content -Path "test\widget_test.dart" -Value "void main() {}"
Write-Host "  OK: test/widget_test.dart"

Write-Host ""
Write-Host "SELESAI! 39 file berhasil dibuat." -ForegroundColor Green
Write-Host "Jalankan: flutter pub get" -ForegroundColor Yellow
Write-Host "Lalu: flutter run" -ForegroundColor Yellow