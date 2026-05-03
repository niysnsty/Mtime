import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Track Your Cycle',
      'description': 'Keep track of your menstrual cycle with elegance and precision.',
      'icon': 'calendar_month_rounded',
    },
    {
      'title': 'Understand Symptoms',
      'description': 'Log your moods and physical symptoms to understand your body better.',
      'icon': 'favorite_rounded',
    },
    {
      'title': 'Get Insights',
      'description': 'Receive smart predictions and personalized health insights.',
      'icon': 'insights_rounded',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return _buildPage(
                title: _onboardingData[index]['title']!,
                description: _onboardingData[index]['description']!,
                iconName: _onboardingData[index]['icon']!,
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                    (index) => _buildIndicator(index == _currentPage),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    }
                  },
                  child: Text(_currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({required String title, required String description, required String iconName}) {
    IconData icon;
    switch(iconName) {
      case 'calendar_month_rounded': icon = Icons.calendar_month_rounded; break;
      case 'favorite_rounded': icon = Icons.favorite_rounded; break;
      case 'insights_rounded': icon = Icons.insights_rounded; break;
      default: icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 60),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 24),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.secondary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
