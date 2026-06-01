import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';

class IpkCalculatorScreen extends StatefulWidget {
  const IpkCalculatorScreen({super.key});

  @override
  State<IpkCalculatorScreen> createState() => _IpkCalculatorScreenState();
}

class _IpkCalculatorScreenState extends State<IpkCalculatorScreen> {
  final _targetCtrl = TextEditingController();
  double? _targetIpk;

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator IPK')),
      body: Consumer<CourseProvider>(
        builder: (context, provider, _) {
          final courses = provider.courses;
          final completed = courses.where((c) => c.isCompleted && c.grade != null).toList();
          
          final ipk = provider.currentIpk;
          final totalSks = provider.totalSks;
          final completedSks = provider.completedSks;
          final ongoingSks = totalSks - completedSks;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        ipk.toStringAsFixed(2),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'IPK Saat Ini',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(label: 'Total SKS', value: '$totalSks'),
                          _Stat(label: 'Selesai', value: '$completedSks SKS'),
                          _Stat(label: 'Sisa', value: '$ongoingSks SKS'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text('Simulasi Target', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Container(
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _targetCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Target IPK (Skala 4.0)',
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _targetIpk = double.tryParse(val);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_targetIpk != null && ongoingSks > 0) ...[
                        const SizedBox(height: 16),
                        _buildSimulationResult(
                          targetIpk: _targetIpk!,
                          currentIpk: ipk,
                          completedSks: completedSks,
                          ongoingSks: ongoingSks,
                          theme: theme,
                        ),
                      ] else if (_targetIpk != null && ongoingSks == 0) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada mata kuliah yang sedang berjalan untuk disimulasikan.',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text('Mata Kuliah Selesai', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (completed.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Belum ada mata kuliah yang diselesaikan.'),
                )
              else
                ...completed.map((c) => ListTile(
                  title: Text(c.name),
                  subtitle: Text('${c.sks} SKS'),
                  trailing: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Text(
                      c.grade!,
                      style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSimulationResult({
    required double targetIpk,
    required double currentIpk,
    required int completedSks,
    required int ongoingSks,
    required ThemeData theme,
  }) {
    final totalSks = completedSks + ongoingSks;
    final targetTotalBobot = targetIpk * totalSks;
    final currentTotalBobot = currentIpk * completedSks;
    final neededBobot = targetTotalBobot - currentTotalBobot;
    
    if (neededBobot <= 0) {
      return const Text('Kamu sudah melampaui target ini!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    }
    
    final neededIps = neededBobot / ongoingSks;
    if (neededIps > 4.0) {
      return Text(
        'Target tidak realistis. Rata-rata nilai yang dibutuhkan untuk sisa $ongoingSks SKS adalah ${neededIps.toStringAsFixed(2)} (Maksimal 4.0).',
        style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
      );
    }

    return Text(
      'Untuk mencapai IPK $targetIpk, kamu butuh rata-rata nilai setara IP ${neededIps.toStringAsFixed(2)} pada $ongoingSks SKS yang tersisa.',
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
