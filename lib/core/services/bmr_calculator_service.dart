import '../models/user_profile.dart';

/// Service for calculating Basal Metabolic Rate (BMR)
/// 
/// Uses Mifflin-St Jeor Equation (most accurate for modern populations):
/// - Men: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age) + 5
/// - Women: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age) - 161
class BMRCalculatorService {
  /// Calculate BMR using Mifflin-St Jeor Equation
  /// 
  /// This is the most accurate equation for modern populations
  /// Accuracy: ±10% for 80% of population
  int calculateBMR({
    required double weight, // kg
    required double height, // cm
    required int age, // years
    required String gender, // 'male' or 'female'
  }) {
    // Base calculation (same for both genders)
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    
    // Gender-specific adjustment
    if (gender.toLowerCase() == 'male') {
      bmr += 5;
    } else {
      bmr -= 161;
    }
    
    return bmr.round();
  }
  
  /// Calculate BMR from user profile and current weight
  int calculateFromProfile({
    required UserProfile profile,
    required double currentWeight,
  }) {
    return calculateBMR(
      weight: currentWeight,
      height: profile.height,
      age: profile.age,
      gender: profile.gender,
    );
  }
  
  /// Calculate Total Daily Energy Expenditure (TDEE)
  /// TDEE = BMR × Activity Factor
  int calculateTDEE({
    required int bmr,
    required String activityLevel,
  }) {
    final activityFactor = _getActivityFactor(activityLevel);
    return (bmr * activityFactor).round();
  }
  
  /// Get activity factor multiplier
  double _getActivityFactor(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2; // Little/no exercise
      case 'light':
      case 'lightly_active':
        return 1.375; // Exercise 1-3 days/week
      case 'moderate':
      case 'moderately_active':
        return 1.55; // Exercise 3-5 days/week
      case 'very_active':
        return 1.725; // Exercise 6-7 days/week
      case 'athlete':
      case 'extremely_active':
        return 1.9; // Physical job + exercise or 2x/day training
      default:
        return 1.55; // Default to moderate
    }
  }
  
  /// Validate BMR is within reasonable range
  /// Typical range: 1000-2500 kcal/day
  bool isReasonableBMR(int bmr) {
    return bmr >= 1000 && bmr <= 3000;
  }
  
  /// Get BMR category description
  String getBMRCategory(int bmr) {
    if (bmr < 1200) return 'Very Low';
    if (bmr < 1500) return 'Low';
    if (bmr < 1800) return 'Average';
    if (bmr < 2200) return 'Above Average';
    return 'High';
  }
}
