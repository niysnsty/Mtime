import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/daily_log_model.dart';
import '../dashboard/cycle_provider.dart';

class DailyLogPage extends StatefulWidget {
  const DailyLogPage({super.key});

  @override
  State<DailyLogPage> createState() => _DailyLogPageState();
}

class _DailyLogPageState extends State<DailyLogPage> {
  String _selectedMood = 'Senang';
  final List<String> _selectedSymptoms = [];
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> _moods = [
    {'name': 'Senang', 'icon': Icons.sentiment_very_satisfied_rounded},
    {'name': 'Biasa', 'icon': Icons.sentiment_satisfied_rounded},
    {'name': 'Sedih', 'icon': Icons.sentiment_dissatisfied_rounded},
    {'name': 'Marah', 'icon': Icons.sentiment_very_dissatisfied_rounded},
    {'name': 'Lelah', 'icon': Icons.battery_alert_rounded},
  ];

  final List<String> _symptoms = [
    'Sakit Perut', 'Pusing', 'Jerawat', 'Sakit Punggung', 'Kembung', 'Mual'
  ];

  @override
  Widget build(BuildContext context) {
    final cycleProvider = Provider.of<CycleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Catat Gejala', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Bagaimana suasana hati Anda?'),
            const SizedBox(height: 16),
            _buildMoodSelector(),
            const SizedBox(height: 40),
            _buildSectionTitle('Apa yang Anda rasakan?'),
            const SizedBox(height: 16),
            _buildSymptomChips(),
            const SizedBox(height: 40),
            _buildSectionTitle('Catatan Tambahan'),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tuliskan perasaan atau gejala lainnya...',
                fillColor: AppColors.surface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () async {
                final log = DailyLogModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  cycleId: cycleProvider.currentCycle?.id ?? 'default',
                  date: DateTime.now(),
                  mood: _selectedMood,
                  physicalSymptoms: _selectedSymptoms,
                  notes: _noteController.text,
                );
                await cycleProvider.addDailyLog(log);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Simpan Catatan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
    );
  }

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _moods.map((mood) {
        bool isSelected = _selectedMood == mood['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedMood = mood['name']),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  mood['icon'],
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mood['name'],
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSymptomChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _symptoms.map((symptom) {
        bool isSelected = _selectedSymptoms.contains(symptom);
        return FilterChip(
          label: Text(symptom),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSymptoms.add(symptom);
              } else {
                _selectedSymptoms.remove(symptom);
              }
            });
          },
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}
