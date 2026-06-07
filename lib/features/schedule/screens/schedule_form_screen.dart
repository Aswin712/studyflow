import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/schedule.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../providers/schedule_provider.dart';

// Preset waktu kuliah yang umum digunakan
const _timePresets = [
  TimeOfDay(hour: 7, minute: 0),
  TimeOfDay(hour: 8, minute: 0),
  TimeOfDay(hour: 9, minute: 0),
  TimeOfDay(hour: 10, minute: 0),
  TimeOfDay(hour: 11, minute: 0),
  TimeOfDay(hour: 13, minute: 0),
  TimeOfDay(hour: 14, minute: 0),
  TimeOfDay(hour: 15, minute: 0),
  TimeOfDay(hour: 16, minute: 0),
];

class ScheduleFormScreen extends StatefulWidget {
  final Schedule? schedule;
  final int initialDay;
  /// Jika diisi, prefill form dengan data dari jadwal ini (untuk fitur Duplikat)
  final Schedule? prefill;

  const ScheduleFormScreen({
    super.key,
    this.schedule,
    this.initialDay = 0,
    this.prefill,
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
    // Mode Edit: gunakan data jadwal yang ada
    // Mode Duplikat: gunakan prefill (jadwal asal tapi tanpa ID)
    // Mode Baru: gunakan default
    final s = widget.schedule ?? widget.prefill;
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

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

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
              decoration: const InputDecoration(labelText: 'Mata Kuliah'),
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
              decoration: const InputDecoration(labelText: 'Hari'),
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

            // ── Time Chips Preset ──────────────────────────────────
            const SizedBox(height: 10),
            Text(
              'Preset waktu mulai',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _timePresets.map((t) {
                final isSelected =
                    _startTime.hour == t.hour && _startTime.minute == t.minute;
                return ChoiceChip(
                  label: Text(AppDateUtils.formatJam(t)),
                  selected: isSelected,
                  onSelected: (_) {
                    final durasi =
                        _toMinutes(_endTime) - _toMinutes(_startTime);
                    setState(() {
                      _startTime = t;
                      // Geser jam selesai secara proporsional
                      final newEndMinutes =
                          _toMinutes(t) + durasi.clamp(60, 180);
                      _endTime = TimeOfDay(
                        hour: (newEndMinutes ~/ 60) % 24,
                        minute: newEndMinutes % 60,
                      );
                    });
                  },
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            // ──────────────────────────────────────────────────────
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

    // Validasi: jam selesai harus setelah jam mulai
    if (_toMinutes(_endTime) <= _toMinutes(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Jam selesai harus setelah jam mulai'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validasi konflik jadwal
    final schedProv = context.read<ScheduleProvider>();
    final existingSchedules = schedProv.getByDay(_selectedDay);
    final startMin = _toMinutes(_startTime);
    final endMin = _toMinutes(_endTime);

    for (final s in existingSchedules) {
      if (_isEdit && s.id == widget.schedule!.id) continue;
      final existStart = _toMinutes(s.startTime);
      final existEnd = _toMinutes(s.endTime);
      final overlap = startMin < existEnd && endMin > existStart;
      if (overlap) {
        final course = context.read<CourseProvider>().getById(s.courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Bentrok dengan "${course?.name ?? 'jadwal lain'}" '
              '(${AppDateUtils.formatJam(s.startTime)}–${AppDateUtils.formatJam(s.endTime)})',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_isEdit) {
      schedProv.update(widget.schedule!.copyWith(
        courseId: _selectedCourseId,
        day: _selectedDay,
        startTime: _startTime,
        endTime: _endTime,
        room: _roomCtrl.text.trim(),
      ));
    } else {
      schedProv.add(
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
              context.read<ScheduleProvider>().delete(widget.schedule!.id);
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
