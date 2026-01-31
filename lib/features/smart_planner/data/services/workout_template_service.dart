/// Service for defining workout templates and exercise pairing logic
class WorkoutTemplateService {
  /// Get Workout A template structure (Push: Chest/Shoulders/Triceps)
  Map<String, dynamic> getWorkoutATemplate() {
    return {
      'name': 'Workout A - Push',
      'focus': ['Chest', 'Shoulders', 'Triceps'],
      'structure': [
        {
          'type': 'compound',
          'muscleGroup': 'Chest',
          'sets': 4,
          'reps': '8-10',
          'notes': 'Primary compound movement - focus on progressive overload',
        },
        {
          'type': 'accessory',
          'muscleGroup': 'Chest',
          'sets': 3,
          'reps': '10-12',
          'notes': 'Secondary chest exercise for volume',
        },
        {
          'type': 'compound',
          'muscleGroup': 'Shoulders',
          'sets': 3,
          'reps': '8-10',
          'notes': 'Overhead pressing movement',
        },
        {
          'type': 'isolation',
          'muscleGroup': 'Shoulders',
          'sets': 3,
          'reps': '12-15',
          'notes': 'Lateral or front raises for shoulder development',
        },
        {
          'type': 'isolation',
          'muscleGroup': 'Arms',
          'focus': 'Triceps',
          'sets': 3,
          'reps': '10-12',
          'notes': 'Triceps isolation to finish push muscles',
        },
        {
          'type': 'core',
          'muscleGroup': 'Abs',
          'sets': 3,
          'reps': '15-20',
          'notes': 'Core stability work',
        },
      ],
      'estimatedDuration': 45,
      'restPeriods': {
        'compound': 120, // seconds
        'accessory': 90,
        'isolation': 60,
        'core': 45,
      },
    };
  }

  /// Get Workout B template structure (Pull: Back/Biceps + optional Legs)
  Map<String, dynamic> getWorkoutBTemplate({bool includeLegs = false}) {
    final structure = [
      {
        'type': 'compound',
        'muscleGroup': 'Back',
        'sets': 4,
        'reps': '8-10',
        'notes': 'Primary pulling movement (rows or pull-ups)',
      },
      {
        'type': 'accessory',
        'muscleGroup': 'Back',
        'sets': 3,
        'reps': '10-12',
        'notes': 'Secondary back exercise for width or thickness',
      },
      {
        'type': 'isolation',
        'muscleGroup': 'Arms',
        'focus': 'Biceps',
        'sets': 3,
        'reps': '10-12',
        'notes': 'Biceps isolation',
      },
    ];

    // Add legs if Saturday workout
    if (includeLegs) {
      structure.addAll([
        {
          'type': 'compound',
          'muscleGroup': 'Legs',
          'sets': 3,
          'reps': '10-12',
          'notes': 'Compound leg movement (squats or deadlifts)',
        },
        {
          'type': 'accessory',
          'muscleGroup': 'Legs',
          'sets': 3,
          'reps': '12-15',
          'notes': 'Leg accessory (lunges, leg press, etc.)',
        },
      ]);
    }

    // Always finish with core
    structure.add({
      'type': 'core',
      'muscleGroup': 'Abs',
      'sets': 3,
      'reps': '15-20',
      'notes': 'Core stability work',
    });

    return {
      'name': includeLegs ? 'Workout B - Pull + Legs' : 'Workout B - Pull',
      'focus': includeLegs
          ? ['Back', 'Biceps', 'Legs']
          : ['Back', 'Biceps'],
      'structure': structure,
      'estimatedDuration': includeLegs ? 60 : 45,
      'restPeriods': {
        'compound': 120,
        'accessory': 90,
        'isolation': 60,
        'core': 45,
      },
    };
  }

  /// Get exercise pairing logic (for supersets)
  List<Map<String, dynamic>> getSupersetPairs() {
    return [
      {
        'primary': 'Chest',
        'secondary': 'Back',
        'type': 'antagonist',
        'note': 'Push-pull pairing for efficiency',
      },
      {
        'primary': 'Biceps',
        'secondary': 'Triceps',
        'type': 'antagonist',
        'note': 'Arm pairing for balanced development',
      },
      {
        'primary': 'Chest',
        'secondary': 'Shoulders',
        'type': 'synergist',
        'note': 'Both push muscles work together',
      },
    ];
  }

  /// Get recommended rest times by exercise type
  int getRestTime(String exerciseType) {
    switch (exerciseType.toLowerCase()) {
      case 'compound':
        return 120; // 2 minutes
      case 'accessory':
        return 90; // 1.5 minutes
      case 'isolation':
        return 60; // 1 minute
      case 'core':
        return 45; // 45 seconds
      default:
        return 90; // Default
    }
  }

  /// Get weekly split structure (4 days per week)
  List<Map<String, dynamic>> getWeeklySplit() {
    return [
      {
        'day': 'Monday',
        'workout': 'A',
        'focus': 'Chest/Shoulders/Triceps',
        'type': 'Push',
      },
      {
        'day': 'Wednesday',
        'workout': 'B',
        'focus': 'Back/Biceps',
        'type': 'Pull',
      },
      {
        'day': 'Friday',
        'workout': 'A',
        'focus': 'Chest/Shoulders/Triceps',
        'type': 'Push',
      },
      {
        'day': 'Saturday',
        'workout': 'B',
        'focus': 'Back/Biceps/Legs',
        'type': 'Pull + Legs',
      },
    ];
  }

  /// Validate exercise selection for a workout
  bool validateWorkoutStructure(
    List<String> exerciseMuscleGroups,
    String workoutType,
  ) {
    if (workoutType == 'A') {
      // Workout A should include chest and shoulders
      return exerciseMuscleGroups.contains('Chest') &&
          exerciseMuscleGroups.contains('Shoulders');
    } else if (workoutType == 'B') {
      // Workout B should include back
      return exerciseMuscleGroups.contains('Back');
    }
    return false;
  }

  /// Get exercise order priority (compound first)
  int getExercisePriority(bool isCompound, String muscleGroup) {
    if (isCompound) {
      // Compound exercises first, ordered by muscle group size
      switch (muscleGroup) {
        case 'Legs':
          return 1;
        case 'Back':
          return 2;
        case 'Chest':
          return 3;
        case 'Shoulders':
          return 4;
        default:
          return 5;
      }
    } else {
      // Isolation exercises after compounds
      switch (muscleGroup) {
        case 'Arms':
          return 6;
        case 'Shoulders':
          return 7;
        case 'Abs':
          return 8;
        default:
          return 9;
      }
    }
  }
}
