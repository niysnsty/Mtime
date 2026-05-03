import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'data/models/user_model.dart';
import 'data/models/cycle_model.dart';
import 'data/models/daily_log_model.dart';

import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/cycle_repository_impl.dart';
import 'features/auth/auth_provider.dart';
import 'features/dashboard/cycle_provider.dart';
import 'features/main_navigation_wrapper.dart';
import 'features/auth/splash_page.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notifications
  await NotificationService.init();
  
  // Initialize Hive
  await Hive.initFlutter();
  try {
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(CycleModelAdapter());
    Hive.registerAdapter(DailyLogModelAdapter());
  } catch (e) {
    // Adapter already registered
  }
  
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<CycleModel>('cycleBox');
  await Hive.openBox<DailyLogModel>('logBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(MockAuthRepositoryImpl()),
        ),
      ],
      child: const MTimeApp(),
    ),
  );
}

class MTimeApp extends StatelessWidget {
  const MTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const SplashPage();
          }
          if (authProvider.isAuthenticated) {
            return ChangeNotifierProvider(
              create: (_) => CycleProvider(
                MockCycleRepositoryImpl(), // Switch to FirestoreCycleRepositoryImpl() for production
                authProvider.user!.id,
              ),
              child: const MainNavigationWrapper(),
            );
          }
          return const SplashPage();
        },
      ),
    );
  }
}
