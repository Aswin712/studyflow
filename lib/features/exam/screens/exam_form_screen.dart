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

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ExamProvider>();
    final course =
        context.read<CourseProvider>().getById(_selectedCourseId!);
    final courseName = course?.name ?? '';

    if (_isEdit) {
      await provider.update(
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
      await provider.add(
        courseId: _selectedCourseId!,
        title: _titleCtrl.text,
        date: _date,
        time: _time,
        room: _roomCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        courseName: courseName,
      );
    }
    if (mounted) Navigator.pop(context);
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
