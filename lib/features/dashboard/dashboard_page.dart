import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import 'cycle_provider.dart';
import '../logs/daily_log_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cycleProvider = Provider.of<CycleProvider>(context);
    final prediction = cycleProvider.getPrediction();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCycleCircle(context, prediction),
                  const SizedBox(height: 40),
                  _buildQuickStats(context, prediction),
                  const SizedBox(height: 32),
                  _buildDailyLogSection(context),
                  const SizedBox(height: 32),
                  _buildHealthTips(context),
                  const SizedBox(height: 100), // Extra space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyLogPage()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Input Gejala', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          'Halo, ${authProvider.user?.name.split(' ')[0] ?? 'User'}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => authProvider.logout(),
          icon: const Icon(Icons.logout_rounded, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildCycleCircle(BuildContext context, Map<String, dynamic> prediction) {
    final status = prediction['status'] as String;
    final daysUntil = prediction['daysUntil'] as int;

    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.peachGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ring (Simplified for now)
            SizedBox(
              width: 240,
              height: 240,
              child: CircularProgressIndicator(
                value: 0.7, // Example progress
                strokeWidth: 12,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.4)),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$daysUntil',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 64,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Hari lagi',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, Map<String, dynamic> prediction) {
    final nextPeriod = prediction['nextPeriod'] as DateTime?;
    return Row(
      children: [
        _buildStatCard(
          context,
          'Prediksi Berikutnya',
          nextPeriod != null ? DateFormat('dd MMM').format(nextPeriod) : '--',
          Icons.calendar_today_rounded,
          AppColors.primary,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          context,
          'Masa Subur',
          '5 Hari lagi', // Placeholder
          Icons.water_drop_rounded,
          Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Log Harian', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
            TextButton(onPressed: () {}, child: const Text('Lihat Semua')),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.accent),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Anda belum mencatat gejala hari ini. Yuk, catat sekarang!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTips(BuildContext context) {
    final List<Map<String, String>> tips = [
      {
        'title': 'Nutrisi Saat Haid',
        'desc': 'Penuhi asupan zat besi untuk mencegah lemas.',
        'color': '0xFFFFE4E9',
      },
      {
        'title': 'Yoga & Relaksasi',
        'desc': 'Gerakan ringan dapat mengurangi nyeri perut.',
        'color': '0xFFFFF9E1',
      },
      {
        'title': 'Pola Tidur',
        'desc': 'Tidur cukup membantu menstabilkan hormon.',
        'color': '0xFFE3F2FD',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tips Kesehatan', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) {
              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(int.parse(tips[index]['color']!)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tips[index]['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tips[index]['desc']!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
