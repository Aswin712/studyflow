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
import '../../../shared/widgets/tutorial_fab_highlight.dart';
import '../../settings/setting_provider.dart';

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
      floatingActionButton: Consumer3<SettingsProvider, CourseProvider, ScheduleProvider>(
        builder: (context, settings, courseProvider, scheduleProvider, child) {
          final isHighlighting = !settings.isTutorialCompleted && 
                                 courseProvider.courses.isNotEmpty && 
                                 scheduleProvider.all.isEmpty;
          return TutorialFabHighlight(
            isHighlighting: isHighlighting,
            child: FloatingActionButton.extended(
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
        },
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
        // Filter: hanya tampilkan jadwal yg mata kuliahnya masih ada
        final schedules = schedProv
            .getByDay(day)
            .where((s) => courseProv.getById(s.courseId) != null)
            .toList();
        if (schedules.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.event_available_outlined,
            title: 'Tidak ada kuliah',
            subtitle: '${AppConstants.dayNames[day]} bebas kuliah',
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
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
                      // Tombol Duplikat
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Duplikat jadwal',
                        child: IconButton(
                          icon: Icon(Icons.copy_outlined,
                              size: 18, color: theme.colorScheme.outline),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScheduleFormScreen(
                                prefill: schedule,
                                initialDay: schedule.day,
                              ),
                            ),
                          ),
                        ),
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

