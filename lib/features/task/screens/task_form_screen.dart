import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/task.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/image_picker_widget.dart';

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
  TimeOfDay? _deadlineTime;
  late int _priority;
  String? _imagePath; // akan diisi oleh ImagePickerWidget nanti

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _selectedCourseId = t?.courseId;
    _deadline = t?.deadline ?? DateTime.now();
    _deadlineTime = t?.deadlineTime;
    _priority = t?.priority ?? 2;
    _imagePath = t?.imagePath;
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
                
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Mata Kuliah',
                
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

            // ── Deadline tanggal + jam ──────────────────────────────
            Text('Deadline', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),

            Row(
              children: [
                // Tanggal
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(AppDateUtils.formatTanggalPendek(_deadline)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Jam (opsional)
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Jam (opsional)',
                        
                        suffixIcon: _deadlineTime != null
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                padding: EdgeInsets.zero,
                                onPressed: () =>
                                    setState(() => _deadlineTime = null),
                              )
                            : const Icon(Icons.access_time, size: 18),
                      ),
                      child: Text(
                        _deadlineTime != null
                            ? AppDateUtils.formatJam(_deadlineTime!)
                            : '23:59',
                        style: _deadlineTime == null
                            ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Preview deadline lengkap
            const SizedBox(height: 8),
            _DeadlinePreview(date: _deadline, time: _deadlineTime),
            const SizedBox(height: 16),

            // Prioritas
            Text('Prioritas', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: AppConstants.priorityLabels.entries
                  .map((e) => ButtonSegment<int>(
                        value: e.key,
                        label: Text(e.value),
                      ))
                  .toList(),
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 16),

            // Foto tugas — opsional
            Text('Foto Tugas (opsional)',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ImagePickerWidget(
              imagePath: _imagePath,
              onImageSelected: (path) => setState(() => _imagePath = path),
              onImageRemoved: () => setState(() => _imagePath = null),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime ?? TimeOfDay.now(),
      helpText: 'Pilih jam deadline',
    );
    if (picked != null) setState(() => _deadlineTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Peringatan jika deadline sudah lewat
    final deadlineDt = _deadlineTime != null
        ? DateTime(_deadline.year, _deadline.month, _deadline.day,
            _deadlineTime!.hour, _deadlineTime!.minute)
        : DateTime(_deadline.year, _deadline.month, _deadline.day, 23, 59);

    if (deadlineDt.isBefore(DateTime.now())) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 32),
          title: const Text('Deadline sudah lewat'),
          content: const Text(
            'Tanggal deadline yang dipilih sudah berlalu.\n'
            'Notifikasi tidak akan dikirim. Tetap simpan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ubah Deadline'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Tetap Simpan'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final provider = context.read<TaskProvider>();
    final course = context.read<CourseProvider>().getById(_selectedCourseId!);
    final courseName = course?.name ?? '';

    if (_isEdit) {
      await provider.update(
        widget.task!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          courseId: _selectedCourseId,
          deadline: _deadline,
          deadlineTime: _deadlineTime,
          priority: _priority,
          imagePath: _imagePath,
        ),
        courseName,
      );
    } else {
      await provider.add(
        courseId: _selectedCourseId!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        deadline: _deadline,
        deadlineTime: _deadlineTime,
        priority: _priority,
        courseName: courseName,
        imagePath: _imagePath,
      );
    }
    if (mounted) Navigator.pop(context);
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

/// Widget preview deadline — tampil di bawah field tanggal/jam
class _DeadlinePreview extends StatelessWidget {
  final DateTime date;
  final TimeOfDay? time;

  const _DeadlinePreview({required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sisaWaktu = AppDateUtils.hitungSisaWaktu(date, time);
    final isDekat = AppDateUtils.isDeadlineDekat(date, hariWarning: 3);
    final isLate = AppDateUtils.isDeadlineLewat(
      time != null
          ? DateTime(date.year, date.month, date.day, time!.hour, time!.minute)
          : DateTime(date.year, date.month, date.day, 23, 59),
    );

    Color statusColor;
    IconData statusIcon;
    if (isLate) {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.warning_amber_outlined;
    } else if (isDekat) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    } else {
      statusColor = theme.colorScheme.outline;
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDateUtils.formatDeadlineLengkap(date, time),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sisaWaktu,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (time == null)
            Text(
              'default 23:59',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}
