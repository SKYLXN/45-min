import 'package:equatable/equatable.dart';
import '../../features/nutrition/data/models/dietary_restriction.dart';

/// User profile with personal information and fitness goals
class UserProfile extends Equatable {
  final String id;
  final String name;
  final int age;
  final double height; // cm
  final String gender; // 'male' or 'female'
  final String primaryGoal; // 'hypertrophy', 'strength', 'endurance', 'fat_loss'
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'very_active', 'athlete'
  final List<String> targetMuscles; // e.g., ['Chest', 'Abs']
  final List<String> equipmentIds; // References to Equipment
  final DietaryProfile dietaryProfile; // Dietary restrictions and preferences
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.gender,
    required this.primaryGoal,
    this.activityLevel = 'moderate',
    required this.targetMuscles,
    required this.equipmentIds,
    this.dietaryProfile = const DietaryProfile(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      height: (json['height'] as num).toDouble(),
      gender: json['gender'] as String,
      primaryGoal: json['primary_goal'] as String,
      activityLevel: json['activity_level'] as String? ?? 'moderate',
      targetMuscles: (json['target_muscles'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      equipmentIds: (json['equipment_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dietaryProfile: json['dietary_profile'] != null
          ? DietaryProfile.fromJson(json['dietary_profile'] as Map<String, dynamic>)
          : const DietaryProfile(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'height': height,
      'gender': gender,
      'primary_goal': primaryGoal,
      'activity_level': activityLevel,
      'target_muscles': targetMuscles,
      'equipment_ids': equipmentIds,
      'dietary_profile': dietaryProfile.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    double? height,
    String? gender,
    String? primaryGoal,
    String? activityLevel,
    List<String>? targetMuscles,
    List<String>? equipmentIds,
    DietaryProfile? dietaryProfile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      dietaryProfile: dietaryProfile ?? this.dietaryProfile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user has specific equipment
  bool hasEquipment(String equipmentId) {
    return equipmentIds.contains(equipmentId);
  }

  /// Check if user targets specific muscle group
  bool targetsMustle(String muscle) {
    return targetMuscles.contains(muscle);
  }

  /// Get all excluded ingredients from dietary restrictions
  List<String> get excludedIngredients {
    return dietaryProfile.getAllExclusions();
  }

  /// Get Spoonacular diet parameter (for API calls)
  String? get spoonacularDiet {
    final restrictions = dietaryProfile.getActiveRestrictions();
    
    // Map our dietary restrictions to Spoonacular diet types
    for (final restriction in restrictions) {
      switch (restriction.id) {
        case 'vegetarian':
          return 'vegetarian';
        case 'vegan':
          return 'vegan';
        case 'pescatarian':
          return 'pescatarian';
        case 'no_gluten':
          return 'gluten free';
        case 'no_dairy':
          return 'dairy free';
        case 'halal':
          return 'halal'; // Custom, may not be supported
        default:
          continue;
      }
    }
    
    return null; // No matching diet type
  }

  /// Get Spoonacular intolerances parameter (for API calls)
  String? get spoonacularIntolerances {
    final restrictions = dietaryProfile.getActiveRestrictions();
    final intolerances = <String>[];
    
    for (final restriction in restrictions) {
      switch (restriction.id) {
        case 'no_dairy':
          intolerances.add('dairy');
          break;
        case 'no_gluten':
          intolerances.add('gluten');
          break;
        case 'no_nuts':
          intolerances.add('tree nut');
          intolerances.add('peanut');
          break;
        case 'no_shellfish':
          intolerances.add('shellfish');
          break;
        case 'no_soy':
          intolerances.add('soy');
          break;
        case 'no_onion_garlic':
          intolerances.add('onion');
          intolerances.add('garlic');
          break;
        default:
          continue;
      }
    }
    
    return intolerances.isEmpty ? null : intolerances.join(',');
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        height,
        gender,
        primaryGoal,
        activityLevel,
        targetMuscles,
        equipmentIds,
        dietaryProfile,
        createdAt,
        updatedAt,
      ];
}
