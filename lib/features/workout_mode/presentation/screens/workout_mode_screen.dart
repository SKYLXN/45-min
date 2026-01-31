import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';

class WorkoutModeScreen extends StatelessWidget {
  final String workoutId;
  
  const WorkoutModeScreen({
    super.key,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text(AppStrings.workoutMode),
      ),
      body: Center(
        child: Text('Workout Mode - ID: $workoutId'),
      ),
    );
  }
}
