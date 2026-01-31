import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/health_initialization_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/app_initialization_service.dart';
import 'features/exercise_database/providers/exercise_seed_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting 45min app...');
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found or could not be loaded: $e');
  }
  
  // Initialize Firebase (handle duplicate initialization gracefully)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Firebase already initialized - this is fine
    print('Firebase initialization skipped: $e');
  }
  
  // Initialize notification service
  try {
    await NotificationService.initialize();
    print('✅ Notification service initialized');
  } catch (e) {
    print('❌ Notification service initialization failed: $e');
  }
  
  runApp(
    const ProviderScope(
      child: FortyFiveMinApp(),
    ),
  );
}

class FortyFiveMinApp extends ConsumerWidget {
  const FortyFiveMinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger exercise seed initialization on app startup
    final seedStatus = ref.watch(exerciseSeedStatusProvider);
    
    // Trigger Apple Health initialization on app startup (runs in background)
    ref.watch(healthInitializationProvider);

    return FutureBuilder<bool>(
      future: _initializeApp(ref),
      builder: (context, appInitSnapshot) {
        if (appInitSnapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: Color(0xFF0A0E1A),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00FF88)),
                    SizedBox(height: 16),
                    Text(
                      'Initializing Data Persistence...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (appInitSnapshot.hasError || appInitSnapshot.data != true) {
          // App initialization failed - show error but let app continue
          debugPrint('App initialization failed: ${appInitSnapshot.error}');
        }

        return MaterialApp.router(
          title: '45min',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
          // Show loading screen while seeding database
          builder: (context, child) {
            return seedStatus.when(
              data: (status) {
                // Seed complete, show app
                return child ?? const SizedBox.shrink();
              },
              loading: () => const MaterialApp(
                home: Scaffold(
                  backgroundColor: Color(0xFF0A0E1A),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF00FF88)),
                        SizedBox(height: 16),
                        Text(
                          'Initializing Exercise Database...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              error: (error, stack) {
                // Error during seeding - show app anyway (will retry later)
                debugPrint('Error initializing exercise seed: $error');
                return child ?? const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }

  /// Initialize app with comprehensive data persistence
  Future<bool> _initializeApp(WidgetRef ref) async {
    try {
      final appInitService = ref.read(appInitializationServiceProvider);
      return await appInitService.initialize();
    } catch (e) {
      debugPrint('App initialization error: $e');
      return false;
    }
  }
}
