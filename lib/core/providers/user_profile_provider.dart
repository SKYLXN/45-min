import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../constants/app_constants.dart';
import '../../features/body_analytics/data/services/health_service.dart';
import '../services/bmr_calculator_service.dart';

// ============================================================================
// User Profile Provider with Apple Health Integration
// ============================================================================

/// BMR Calculator Service Provider
final bmrCalculatorServiceProvider = Provider<BMRCalculatorService>((ref) {
  return BMRCalculatorService();
});

/// Provider for user's health profile constants from Apple Health
/// These are the "Morphologie & Profil" constants: height, sex, age
final userHealthProfileProvider = FutureProvider<UserHealthProfile>((ref) async {
  final healthService = HealthService();
  
  try {
    final hasPermission = await healthService.checkAuthorizationStatus();
    if (hasPermission) {
      return await healthService.fetchUserHealthProfile();
    }
  } catch (e) {
    print('⚠️ Error fetching health profile: $e');
  }
  
  return const UserHealthProfile();
});

/// Provider for current user profile
/// Automatically fetches height, biological sex, and age from Apple Health
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final healthService = HealthService();
  
  // Default values (will be overwritten by Apple Health if available)
  int age = 30;
  double height = 175.0;
  String gender = 'male';
  
  // Try to fetch complete health profile from Apple Health
  try {
    final hasPermission = await healthService.checkAuthorizationStatus();
    if (hasPermission) {
      print('🍎 Fetching user profile from Apple Health...');
      
      // Fetch the complete health profile
      final healthProfile = await healthService.fetchUserHealthProfile();
      
      // Use Apple Health data if available
      if (healthProfile.height != null) {
        height = healthProfile.height!;
        print('✅ Height from Apple Health: $height cm');
      } else {
        print('⚠️ No height data in Apple Health. Using default: $height cm');
      }
      
      if (healthProfile.age != null) {
        age = healthProfile.age!;
        print('✅ Age from Apple Health: $age years');
      } else {
        print('⚠️ No age data in Apple Health. Using default: $age years');
      }
      
      if (healthProfile.biologicalSex != null) {
        gender = healthProfile.biologicalSex!;
        print('✅ Sex from Apple Health: $gender');
      } else {
        print('⚠️ No sex data in Apple Health. Using default: $gender');
      }
    } else {
      print('⚠️ No Apple Health permission. Using default values.');
    }
  } catch (e) {
    print('⚠️ Error fetching from Apple Health: $e. Using defaults.');
  }
  
  // Return user profile with Apple Health data if available
  // TODO: Age and gender should be editable by user in settings
  return UserProfile(
    id: AppConstants.defaultUserId,
    name: 'Test User',
    age: age,
    height: height,
    gender: gender,
    primaryGoal: 'hypertrophy',
    targetMuscles: ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms'],
    equipmentIds: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
});

// ============================================================================
// State Notifier for User Profile Management
// ============================================================================

/// State for user profile
class UserProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const UserProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  UserProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check if profile is complete
  bool get isComplete => profile != null;

  /// Check if profile needs initial setup
  bool get needsSetup => profile == null;
}

/// Notifier for managing user profile state
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier() : super(const UserProfileState());

  /// Load user profile (mock implementation)
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = UserProfile(
        id: 'default_user',
        name: 'Test User',
        age: 25,
        height: 175.0,
        gender: 'male',
        primaryGoal: 'hypertrophy',
        targetMuscles: ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms'],
        equipmentIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: $e',
      );
    }
  }

  /// Create new profile
  Future<void> createProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create profile: $e',
      );
    }
  }

  /// Update existing profile
  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Save to database when repository is implemented
      // await _repository.updateUserProfile(profile);
      
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: $e',
      );
    }
  }

  /// Add equipment
  Future<void> addEquipment(String equipmentId) async {
    if (state.profile == null) return;
    
    final updatedEquipment = [...state.profile!.equipmentIds, equipmentId];
    final updatedProfile = state.profile!.copyWith(
      equipmentIds: updatedEquipment,
      updatedAt: DateTime.now(),
    );
    
    await updateProfile(updatedProfile);
  }

  /// Remove equipment
  Future<void> removeEquipment(String equipmentId) async {
    if (state.profile == null) return;
    
    final updatedEquipment = state.profile!.equipmentIds
        .where((id) => id != equipmentId)
        .toList();
    final updatedProfile = state.profile!.copyWith(
      equipmentIds: updatedEquipment,
      updatedAt: DateTime.now(),
    );
    
    await updateProfile(updatedProfile);
  }

  /// Add target muscle
  Future<void> addTargetMuscle(String muscle) async {
    if (state.profile == null) return;
    
    final updatedMuscles = [...state.profile!.targetMuscles, muscle];
    final updatedProfile = state.profile!.copyWith(
      targetMuscles: updatedMuscles,
      updatedAt: DateTime.now(),
    );
    
    await updateProfile(updatedProfile);
  }

  /// Remove target muscle
  Future<void> removeTargetMuscle(String muscle) async {
    if (state.profile == null) return;
    
    final updatedMuscles = state.profile!.targetMuscles
        .where((m) => m != muscle)
        .toList();
    final updatedProfile = state.profile!.copyWith(
      targetMuscles: updatedMuscles,
      updatedAt: DateTime.now(),
    );
    
    await updateProfile(updatedProfile);
  }
}

/// Provider for user profile state management
final userProfileStateProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>(
  (ref) {
    return UserProfileNotifier();
  },
);
