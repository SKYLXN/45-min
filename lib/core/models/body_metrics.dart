import 'package:equatable/equatable.dart';

/// Body metrics from Apple HealthKit integration
/// 
/// Data Categories:
/// 1. Body Composition: weight, bodyFat, leanBodyMass, skeletalMuscle, bmi
/// 2. Measurements: height, waistCircumference
/// 3. Metabolism: bmr (yearly average for accuracy)
class BodyMetrics extends Equatable {
  final String id;
  final String userId;
  
  // =========================================================================
  // Core Body Composition (from Apple Health)
  // =========================================================================
  final double weight;              // kg - Base metric
  final double bodyFat;             // % - KPI #1 (target 10-12% for visible abs)
  final double? leanBodyMass;       // kg - Muscles + bones (REAL from HealthKit)
  final double skeletalMuscle;      // kg - Estimated ~45% of lean mass
  final double bmi;                 // Body Mass Index (REAL from HealthKit or calculated)
  
  // =========================================================================
  // Measurements (from Apple Health)
  // =========================================================================
  final double? height;             // cm - Constant for BMI calculation
  final double? waistCircumference; // cm - Visceral fat indicator (secret weapon)
  
  // =========================================================================
  // Metabolism (from Apple Health - yearly average for accuracy)
  // =========================================================================
  final int bmr;                    // kcal - Basal Metabolic Rate (yearly avg)
  
  // =========================================================================
  // Additional Metrics (from smart scales)
  // =========================================================================
  final int? visceralFat;           // rating
  final double? boneMass;           // kg
  final double? waterPercentage;    // percentage
  final int? metabolicAge;          // years
  final double? protein;            // percentage
  
  final DateTime timestamp;

  const BodyMetrics({
    required this.id,
    required this.userId,
    required this.weight,
    required this.bmi,
    required this.skeletalMuscle,
    required this.bodyFat,
    required this.bmr,
    this.leanBodyMass,
    this.height,
    this.waistCircumference,
    this.visceralFat,
    this.boneMass,
    this.waterPercentage,
    this.metabolicAge,
    this.protein,
    required this.timestamp,
  });

  /// Create a BodyMetrics from JSON (database or API)
  factory BodyMetrics.fromJson(Map<String, dynamic> json) {
    return BodyMetrics(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weight: (json['weight'] as num).toDouble(),
      bmi: (json['bmi'] as num).toDouble(),
      skeletalMuscle: (json['skeletal_muscle'] as num).toDouble(),
      bodyFat: (json['body_fat'] as num).toDouble(),
      bmr: json['bmr'] as int,
      leanBodyMass: json['lean_body_mass'] != null
          ? (json['lean_body_mass'] as num).toDouble()
          : null,
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
      waistCircumference: json['waist_circumference'] != null
          ? (json['waist_circumference'] as num).toDouble()
          : null,
      visceralFat: json['visceral_fat'] as int?,
      boneMass: json['bone_mass'] != null 
          ? (json['bone_mass'] as num).toDouble() 
          : null,
      waterPercentage: json['water_percentage'] != null
          ? (json['water_percentage'] as num).toDouble()
          : null,
      metabolicAge: json['metabolic_age'] as int?,
      protein: json['protein'] != null
          ? (json['protein'] as num).toDouble()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'weight': weight,
      'bmi': bmi,
      'skeletal_muscle': skeletalMuscle,
      'body_fat': bodyFat,
      'bmr': bmr,
      'lean_body_mass': leanBodyMass,
      'height': height,
      'waist_circumference': waistCircumference,
      'visceral_fat': visceralFat,
      'bone_mass': boneMass,
      'water_percentage': waterPercentage,
      'metabolic_age': metabolicAge,
      'protein': protein,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  BodyMetrics copyWith({
    String? id,
    String? userId,
    double? weight,
    double? bmi,
    double? skeletalMuscle,
    double? bodyFat,
    int? bmr,
    double? leanBodyMass,
    double? height,
    double? waistCircumference,
    int? visceralFat,
    double? boneMass,
    double? waterPercentage,
    int? metabolicAge,
    double? protein,
    DateTime? timestamp,
  }) {
    return BodyMetrics(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      skeletalMuscle: skeletalMuscle ?? this.skeletalMuscle,
      bodyFat: bodyFat ?? this.bodyFat,
      bmr: bmr ?? this.bmr,
      leanBodyMass: leanBodyMass ?? this.leanBodyMass,
      height: height ?? this.height,
      waistCircumference: waistCircumference ?? this.waistCircumference,
      visceralFat: visceralFat ?? this.visceralFat,
      boneMass: boneMass ?? this.boneMass,
      waterPercentage: waterPercentage ?? this.waterPercentage,
      metabolicAge: metabolicAge ?? this.metabolicAge,
      protein: protein ?? this.protein,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Check if body fat is within healthy range for visible abs
  /// Men: 10-12% for visible abs, Women: 14-16%
  bool get isHealthyBodyFat {
    return bodyFat >= 10.0 && bodyFat <= 20.0;
  }
  
  /// Check if approaching visible abs range (men: 10-12%)
  bool get isNearAbsVisible {
    return bodyFat > 0 && bodyFat <= 15.0;
  }

  /// Calculate lean body mass if not provided from HealthKit
  /// Prefers real value from Apple Health over calculation
  double get calculatedLeanBodyMass {
    if (leanBodyMass != null && leanBodyMass! > 0) {
      return leanBodyMass!;
    }
    return weight - (weight * bodyFat / 100);
  }
  
  /// Check if waist is in healthy range (men: < 94cm, women: < 80cm)
  bool isWaistHealthy({required String gender}) {
    if (waistCircumference == null) return true;
    if (gender.toLowerCase() == 'male') {
      return waistCircumference! < 94;
    } else {
      return waistCircumference! < 80;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        weight,
        bmi,
        skeletalMuscle,
        bodyFat,
        bmr,
        leanBodyMass,
        height,
        waistCircumference,
        visceralFat,
        boneMass,
        waterPercentage,
        metabolicAge,
        protein,
        timestamp,
      ];
}
