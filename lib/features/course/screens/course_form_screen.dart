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
  late final TextEditingController _lecturerCtrl;
  late final TextEditingController _roomCtrl;
  late int _sks;
  Color? _selectedColor;
  bool _isCompleted = false;
  String? _grade;

  final _grades = ['A', 'B', 'C', 'D', 'E'];

  bool get _isEdit => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _lecturerCtrl = TextEditingController(text: c?.lecturer ?? '');
    _roomCtrl = TextEditingController(text: c?.room ?? '');
    _sks = c?.sks ?? 3;
    _selectedColor = c?.color;
    _isCompleted = c?.isCompleted ?? false;
    _grade = c?.grade;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedColor ??= context.read<CourseProvider>().defaultColorFor(
          context.read<CourseProvider>().courses.length,
        );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
                
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // SKS saja — tanpa field kode MK
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lecturerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dosen',
                      hintText: 'Nama dosen pengampu',
                      
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                // SKS stepper compact
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SKS', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton.outlined(
                          onPressed:
                              _sks > 1 ? () => setState(() => _sks--) : null,
                          icon: const Icon(Icons.remove, size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('$_sks',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        IconButton.outlined(
                          onPressed:
                              _sks < 6 ? () => setState(() => _sks++) : null,
                          icon: const Icon(Icons.add, size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Ruangan',
                hintText: 'contoh: GKB 3-201',
                
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 24),

            Text('Warna', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            ColorPickerWidget(
              selectedColor: _selectedColor!,
              onColorSelected: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: 24),

            SwitchListTile(
              title: const Text('Mata Kuliah Selesai'),
              subtitle: const Text('Tandai jika sudah lulus untuk menghitung IPK'),
              value: _isCompleted,
              onChanged: (val) {
                setState(() {
                  _isCompleted = val;
                  if (!val) _grade = null;
                });
              },
            ),
            if (_isCompleted) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Nilai Akhir',
                  
                ),
                initialValue: _grade,
                items: _grades
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _grade = val),
                validator: (v) => v == null ? 'Pilih nilai' : null,
              ),
            ],
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
        sks: _sks,
        lecturer: _lecturerCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        color: _selectedColor,
        isCompleted: _isCompleted,
        grade: _isCompleted ? _grade : null,
      ));
    } else {
      provider.add(
        name: _nameCtrl.text.trim(),
        sks: _sks,
        lecturer: _lecturerCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        color: _selectedColor!,
        isCompleted: _isCompleted,
        grade: _isCompleted ? _grade : null,
      );
    }
    Navigator.pop(context);
  }
}
