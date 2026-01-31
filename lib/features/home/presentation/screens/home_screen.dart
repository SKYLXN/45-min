import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../body_analytics/data/services/health_service.dart';
import '../../../body_analytics/providers/body_analytics_provider.dart';
import '../../../smart_planner/providers/smart_planner_provider.dart';
import '../../../workout_mode/providers/active_workout_provider.dart';
import '../../../nutrition/providers/nutrition_log_provider.dart';
import '../../../nutrition/providers/weekly_meal_plan_provider.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/weekly_plan_card.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data persistence on home screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDataPersistence();
    });
  }

  /// Initialize data persistence for all critical app data
  Future<void> _initializeDataPersistence() async {
    try {
      // Load nutrition data (food logs, meal plans)
      ref.read(nutritionLogProvider.notifier).loadTodayLog();
      ref.read(nutritionLogProvider.notifier).loadRecentLogs();
      ref.read(weeklyMealPlanProvider.notifier).loadSavedPlans();
      
      // Initialize other providers (just access them)
      ref.read(smartPlannerProvider);
      ref.read(bodyAnalyticsProvider);
      
      print('✅ Data persistence initialized successfully');
    } catch (e) {
      print('❌ Error initializing data persistence: $e');
    }
  }
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_rounded,
      label: 'Home',
      route: '/',
    ),
    _NavItem(
      icon: Icons.analytics_rounded,
      label: 'Analytics',
      route: '/body-analytics',
    ),
    _NavItem(
      icon: Icons.calendar_today_rounded,
      label: 'Planner',
      route: '/smart-planner',
    ),
    _NavItem(
      icon: Icons.fitness_center_rounded,
      label: 'Exercises',
      route: '/exercise-database',
    ),
    _NavItem(
      icon: Icons.restaurant_rounded,
      label: 'Nutrition',
      route: '/nutrition',
    ),
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].route || location.startsWith('${_navItems[i].route}/')) {
        return i;
      }
    }
    return 0; // Default to home
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer,
                size: 20,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(width: 12),
            const Text(AppStrings.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context),
              const SizedBox(height: 32),
              _buildNextWorkoutCard(context),
              const SizedBox(height: 24),
              const NutritionCard(),
              const SizedBox(height: 24),
              const WeeklyPlanCard(),
              const SizedBox(height: 24),
              _buildQuickStats(context),
              const SizedBox(height: 24),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          context.go(_navItems[index].route);
        },
        items: _navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to transform,',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Medouz? 💪',
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ],
    );
  }

  Widget _buildNextWorkoutCard(BuildContext context) {
    final activeWorkoutState = ref.watch(activeWorkoutProvider);
    final smartPlannerState = ref.watch(smartPlannerProvider);
    
    // Show resume card if workout is active
    if (activeWorkoutState.isActive) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryGold, Colors.orange.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.play_circle_filled,
                    color: AppColors.backgroundDark,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Workout in Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.backgroundDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                activeWorkoutState.plannedWorkout?.workoutType ?? 'Workout',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.backgroundDark,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Exercise ${activeWorkoutState.currentExerciseIndex + 1}/${activeWorkoutState.totalExercises} • ${activeWorkoutState.progress.toStringAsFixed(0)}% complete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.backgroundDark.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/active-workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundDark,
                    foregroundColor: AppColors.primaryGold,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume Workout'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Show next workout from program
    final nextWorkout = smartPlannerState.currentProgram?.workouts.firstWhere(
      (w) => w.completedAt == null,
      orElse: () => smartPlannerState.currentProgram!.workouts.first,
    );
    
    if (nextWorkout != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: AppColors.backgroundDark,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Next Workout',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.backgroundDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                nextWorkout.workoutType,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.backgroundDark,
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${nextWorkout.estimatedDuration} min • ${nextWorkout.exercises.length} exercises',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.backgroundDark.withOpacity(0.8),
                    ),
              ),
              if (nextWorkout.completedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.backgroundDark.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.backgroundDark.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/workout-preview/${nextWorkout.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundDark,
                    foregroundColor: AppColors.primaryGreen,
                  ),
                  child: Text(nextWorkout.completedAt != null ? 'View Workout' : 'Start Workout'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Default fallback - no program available
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.backgroundDark,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'No Program Active',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Generate Your Program',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.backgroundDark,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a personalized workout plan tailored to your goals',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.backgroundDark.withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/smart-planner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.backgroundDark,
                  foregroundColor: AppColors.primaryGreen,
                ),
                child: const Text('Go to Planner'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final bodyAnalyticsAsync = ref.watch(latestBodyMetricsProvider);
    final smartPlannerState = ref.watch(smartPlannerProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        bodyAnalyticsAsync.when(
          data: (metrics) {
            // Calculate weekly workout progress
            final program = smartPlannerState.currentProgram;
            int completedWorkouts = 0;
            int totalWorkouts = 0;
            if (program != null) {
              totalWorkouts = program.workouts.length;
              completedWorkouts = program.workouts.where((w) => w.completedAt != null).length;
            }
            
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.trending_up,
                        label: 'Muscle Mass',
                        value: metrics != null 
                            ? '${metrics.skeletalMuscle.toStringAsFixed(1)} kg'
                            : '-- kg',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.local_fire_department,
                        label: 'BMR',
                        value: metrics != null
                            ? '${metrics.bmr.toStringAsFixed(0)} kcal'
                            : '-- kcal',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.straighten,
                        label: 'Body Fat',
                        value: metrics != null
                            ? '${metrics.bodyFat.toStringAsFixed(1)}%'
                            : '--%',
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.calendar_today,
                        label: 'This Week',
                        value: totalWorkouts > 0
                            ? '$completedWorkouts/$totalWorkouts done'
                            : 'No program',
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildLoadingCard(context)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLoadingCard(context)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildLoadingCard(context)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLoadingCard(context)),
                ],
              ),
            ],
          ),
          error: (_, __) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.trending_up,
                      label: 'Muscle Mass',
                      value: '-- kg',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.local_fire_department,
                      label: 'BMR',
                      value: '-- kcal',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.straighten,
                      label: 'Body Fat',
                      value: '--%',
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.calendar_today,
                      label: 'This Week',
                      value: 'No data',
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          context,
          icon: Icons.favorite,
          label: 'Connect Apple Health',
          onTap: () => _requestHealthPermissions(context),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          icon: Icons.analytics,
          label: 'View Body Analytics',
          onTap: () => context.push('/body-analytics'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          icon: Icons.restaurant_menu,
          label: 'Meal Suggestions',
          onTap: () => context.push('/nutrition'),
        ),
      ],
    );
  }

  Future<void> _requestHealthPermissions(BuildContext context) async {
    try {
      final healthService = HealthService();
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Request authorization
      final granted = await healthService.requestAuthorization();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show result
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? '✅ Health permissions granted! Check Settings → Health → Data Access & Devices → 45min'
                  : '❌ Health permissions denied. Please enable in Settings.',
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
