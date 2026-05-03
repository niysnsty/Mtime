import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/cycle_provider.dart';
import '../../data/models/cycle_model.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cycleProvider = Provider.of<CycleProvider>(context);
    final cycles = cycleProvider.cycles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Siklus', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: cycles.isEmpty 
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: cycles.length,
            itemBuilder: (context, index) {
              return _buildCycleHistoryItem(context, cycles[index]);
            },
          ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Belum ada riwayat siklus.'),
    );
  }

  Widget _buildCycleHistoryItem(BuildContext context, CycleModel cycle) {
    final startDate = DateFormat('dd MMM yyyy').format(cycle.startDate);
    final duration = cycle.duration;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startDate,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$duration Hari',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCustomProgressBar(context, cycle),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem('Haid', AppColors.primary),
              _buildLegendItem('Subur', Colors.blueAccent),
              _buildLegendItem('Luteal', Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomProgressBar(BuildContext context, CycleModel cycle) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          // Period segment (approx first 5 days)
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 5 / 28,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          // Ovulation segment (approx days 12-16)
          Positioned(
            left: (11 / 28) * (MediaQuery.of(context).size.width - 96), // 96 is padding
            child: Container(
              height: 12,
              width: (5 / 28) * (MediaQuery.of(context).size.width - 96),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
