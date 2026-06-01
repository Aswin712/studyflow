import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../course/providers/course_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../task/providers/task_provider.dart';
import '../../exam/providers/exam_provider.dart';
import '../../settings/setting_provider.dart';
import '../../settings/setting_screen.dart';
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
            // Header with settings icon — Selector agar hanya rebuild saat userName berubah
            SliverToBoxAdapter(
              child: Selector<SettingsProvider, String>(
                selector: (_, s) => s.userName,
                builder: (context, userName, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isEmpty
                                  ? greeting
                                  : '$greeting, $userName',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                'StudyFlow',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white, // Required for ShaderMask
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppDateUtils.formatTanggal(now),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // User avatar → Settings
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: userName.isEmpty
                                ? Icon(Icons.person_outline,
                                    size: 24,
                                    color: theme.colorScheme.onPrimaryContainer)
                                : Text(
                                    _getInitial(userName),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stat cards row
            SliverToBoxAdapter(child: _StatRow()),

            // Jadwal hari ini
            const SliverToBoxAdapter(
              child: _Section(
                title: 'Jadwal Hari Ini',
                child: TodayScheduleWidget(),
              ),
            ),

            // Progress tugas
            const SliverToBoxAdapter(
              child: _Section(
                title: 'Progress Tugas',
                child: TaskProgressWidget(),
              ),
            ),

            // Ujian mendatang
            const SliverToBoxAdapter(
              child: _Section(
                title: 'Ujian Mendatang',
                child: UpcomingWidget(),
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

  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
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
                  value: '$totalSks',
                  icon: Icons.star_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Tugas',
                  value: '$pending',
                  icon: Icons.checklist_outlined,
                  color: pending > 3 ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Ujian',
                  value: '$upcomingExams',
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
                  value: '$todayCount',
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
