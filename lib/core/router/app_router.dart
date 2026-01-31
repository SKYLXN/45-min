import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_helper.dart';
import '../../features/exercise_database/data/repositories/exercise_repository.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/body_analytics/presentation/screens/body_analytics_screen.dart';
import '../../features/smart_planner/presentation/screens/smart_planner_screen.dart';
import '../../features/smart_planner/presentation/screens/equipment_setup_screen.dart';
import '../../features/smart_planner/presentation/screens/weekly_program_screen.dart';
import '../../features/smart_planner/presentation/screens/workout_preview_screen.dart';
import '../../features/workout_mode/presentation/screens/workout_mode_screen.dart';
import '../../features/workout_mode/presentation/screens/active_workout_screen.dart';
import '../../features/workout_mode/presentation/screens/workout_summary_screen.dart';
import '../../features/exercise_database/presentation/screens/exercise_database_screen.dart';
import '../../features/exercise_database/presentation/screens/exercise_detail_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_dashboard_screen.dart';
import '../../features/nutrition/presentation/screens/recipe_search_screen.dart';
import '../../features/nutrition/presentation/screens/recipe_detail_screen.dart';
import '../../features/nutrition/presentation/screens/meal_suggestions_screen.dart';
import '../../features/nutrition/presentation/screens/meal_plan_generator_screen.dart';
import '../../features/nutrition/presentation/screens/dietary_restrictions_screen.dart';
import '../../features/nutrition/presentation/screens/weekly_meal_plan_screen.dart';
import '../../features/nutrition/presentation/screens/shopping_list_screen.dart';

/// App routing configuration using GoRouter
class AppRouter {
  AppRouter._();

  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String bodyAnalytics = '/body-analytics';
  static const String smartPlanner = '/smart-planner';
  static const String workoutMode = '/workout-mode';
  static const String activeWorkout = '/active-workout';
  static const String workoutSummary = '/workout-summary';
  static const String exerciseDatabase = '/exercise-database';
  static const String nutrition = '/nutrition';
  static const String nutritionDashboard = '/nutrition/dashboard';
  static const String recipeSearch = '/recipe-search';
  static const String mealSuggestions = '/nutrition/suggestions';
  static const String mealPlanGenerator = '/nutrition/meal-plan';
  static const String dietaryRestrictions = '/nutrition/dietary-restrictions';
  static const String weeklyMealPlan = '/weekly-meal-plan';
  static const String shoppingList = '/shopping-list';

  static final GoRouter router = GoRouter(
    initialLocation: onboarding,
    routes: [
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: home,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: bodyAnalytics,
        name: 'bodyAnalytics',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BodyAnalyticsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: smartPlanner,
        name: 'smartPlanner',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WeeklyProgramScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/equipment-setup',
        name: 'equipmentSetup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EquipmentSetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/workout-preview/:workoutId',
        name: 'workoutPreview',
        pageBuilder: (context, state) {
          final workoutId = state.pathParameters['workoutId'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: WorkoutPreviewScreen(workoutId: workoutId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: workoutMode,
        name: 'workoutMode',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: WorkoutModeScreen(
            workoutId: state.uri.queryParameters['workoutId'] ?? '',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: activeWorkout,
        name: 'activeWorkout',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ActiveWorkoutScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: workoutSummary,
        name: 'workoutSummary',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WorkoutSummaryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: exerciseDatabase,
        name: 'exerciseDatabase',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ExerciseDatabaseScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/exercise-detail/:exerciseId',
        name: 'exerciseDetail',
        pageBuilder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId'] ?? '';
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: ExerciseDetailLoader(exerciseId: exerciseId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: nutrition,
        name: 'nutrition',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NutritionDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: nutritionDashboard,
        name: 'nutritionDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NutritionDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: recipeSearch,
        name: 'recipeSearch',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RecipeSearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: '/recipe-detail/:recipeId',
        name: 'recipeDetail',
        pageBuilder: (context, state) {
          final recipeId = state.pathParameters['recipeId'] ?? '';
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: RecipeDetailScreen(recipeId: recipeId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          );
        },
      ),
      GoRoute(
        path: mealSuggestions,
        name: 'mealSuggestions',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MealSuggestionsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: mealPlanGenerator,
        name: 'mealPlanGenerator',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MealPlanGeneratorScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: dietaryRestrictions,
        name: 'dietaryRestrictions',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DietaryRestrictionsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: weeklyMealPlan,
        name: 'weeklyMealPlan',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WeeklyMealPlanScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
      GoRoute(
        path: shoppingList,
        name: 'shoppingList',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ShoppingListScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}

/// Loader widget that fetches exercise data and displays ExerciseDetailScreen
class ExerciseDetailLoader extends StatelessWidget {
  final String exerciseId;

  const ExerciseDetailLoader({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadExercise(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0E1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF88)),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Exercise not found: $exerciseId',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        return ExerciseDetailScreen(exercise: snapshot.data!);
      },
    );
  }

  Future<dynamic> _loadExercise() async {
    final dbHelper = DatabaseHelper.instance;
    final repository = ExerciseRepository(dbHelper: dbHelper);
    return await repository.getExerciseById(exerciseId);
  }
}
