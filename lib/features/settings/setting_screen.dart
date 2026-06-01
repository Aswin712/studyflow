import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'setting_provider.dart';
import '../../../core/services/backup_service.dart';
import '../course/providers/course_provider.dart';
import '../schedule/providers/schedule_provider.dart';
import '../task/providers/task_provider.dart';
import '../exam/providers/exam_provider.dart';
import '../../../core/theme/theme_presets.dart';
import 'personalization_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Profil'),
          const SizedBox(height: 8),
          const _UserNameCard(),
          const SizedBox(height: 24),
          const _SectionLabel('Tampilan'),
          const SizedBox(height: 8),
          const _AppearanceCard(),
          const SizedBox(height: 24),
          const _SectionLabel('Manajemen Data'),
          const SizedBox(height: 8),
          const _DataManagementCard(),
          const SizedBox(height: 24),
          const _SectionLabel('Tentang'),
          const SizedBox(height: 8),
          _InfoCard(),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _UserNameCard extends StatefulWidget {
  const _UserNameCard();

  @override
  State<_UserNameCard> createState() => _UserNameCardState();
}

class _UserNameCardState extends State<_UserNameCard> {
  late final TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final name = context.read<SettingsProvider>().userName;
    _ctrl = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SettingsProvider>();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _getInitial(provider.userName),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _editing
                  ? TextField(
                      controller: _ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Nama kamu',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _save(context),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.userName.isEmpty
                              ? 'Belum ada nama'
                              : provider.userName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: provider.userName.isEmpty
                                ? theme.colorScheme.outline
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Nama ditampilkan di Dashboard',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            _editing
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        color: theme.colorScheme.primary,
                        onPressed: () => _save(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _ctrl.text = provider.userName;
                          setState(() => _editing = false);
                        },
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => setState(() => _editing = true),
                  ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    context.read<SettingsProvider>().setUserName(_ctrl.text);
    setState(() => _editing = false);
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

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          leading: Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
          title: const Text('Personalisasi Tampilan'),
          subtitle: const Text('Tema warna dan mode gelap'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonalizationScreen()),
            );
          },
        ),
      ),
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  const _DataManagementCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.upload_file_outlined,
                  color: theme.colorScheme.primary),
              title: const Text('Eksport Data (Backup)'),
              subtitle: const Text('Simpan jadwal dan tugas ke file'),
              onTap: () async {
                final success = await BackupService.backupData();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup berhasil diekspor')),
                  );
                }
              },
            ),
            Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ListTile(
              leading: Icon(Icons.download_outlined,
                  color: theme.colorScheme.primary),
              title: const Text('Import Data (Restore)'),
              subtitle: const Text('Pulihkan data dari file backup'),
              onTap: () async {
                final result = await BackupService.restoreData();
                if (result == 'SUCCESS' && context.mounted) {
                  // Invalidate cache + reload dari storage
                  context.read<CourseProvider>().reload();
                  context.read<ScheduleProvider>().reload();
                  context.read<TaskProvider>().reload();
                  context.read<ExamProvider>().reload();
                  context.read<SettingsProvider>().reload();
  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restore data berhasil')),
                  );
                } else if (result != null && result != 'SUCCESS' && context.mounted) {
                  // Tampilkan error jika format tidak valid atau korup
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.info_outline, color: theme.colorScheme.outline),
              title: const Text('Versi aplikasi'),
              trailing: Text('3.4.0',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
            Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ListTile(
              leading:
                  Icon(Icons.school_outlined, color: theme.colorScheme.outline),
              title: const Text('StudyFlow'),
              subtitle: const Text('Manajemen akademik mahasiswa'),
            ),
          ],
        ),
      ),
    );
  }
}
