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

    // Reset jika mata kuliah sudah dihapus
    if (_selectedCourseId != null &&
        !courses.any((c) => c.id == _selectedCourseId)) {
      _selectedCourseId = null;
    }

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
              initialValue: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Mata Kuliah',
                
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
              initialValue: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Hari',
                
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
          
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(AppDateUtils.formatJam(time)),
      ),
    );
  }
}
