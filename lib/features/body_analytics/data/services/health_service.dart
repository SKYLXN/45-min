import 'package:health/health.dart';
import '../../../../core/models/body_metrics.dart';

/// Service for interacting with Apple HealthKit
/// 
/// Data Categories:
/// 1. Morphologie & Profil (Constants): HEIGHT, BIOLOGICAL_SEX, BIRTH_DATE
/// 2. Body Composition: WEIGHT, BODY_FAT_PERCENTAGE, LEAN_BODY_MASS, BODY_MASS_INDEX, WAIST_CIRCUMFERENCE
/// 3. Recovery & Nervous System: SLEEP_SESSION, HEART_RATE_VARIABILITY_SDNN, RESTING_HEART_RATE
class HealthService {
  final Health _health = Health();
  
  // Health data types we need access to
  static final List<HealthDataType> _readTypes = [
    // =========================================================================
    // 1. Morphologie & Profil (Constants - for BMR/calorie calculations)
    // =========================================================================
    HealthDataType.HEIGHT,                    // Required for BMI calculation
    HealthDataType.GENDER,                    // Biological sex - changes calorie formulas
    HealthDataType.BIRTH_DATE,                // For precise age calculation
    
    // =========================================================================
    // 2. Body Composition (The "Dessiné" tracking)
    // =========================================================================
    HealthDataType.WEIGHT,                    // Base metric
    HealthDataType.BODY_FAT_PERCENTAGE,       // KPI #1 - Target 10-12% for visible abs
    HealthDataType.LEAN_BODY_MASS,            // Muscles + bones - if increasing = gaining muscle
    HealthDataType.BODY_MASS_INDEX,           // Global health indicator
    HealthDataType.WAIST_CIRCUMFERENCE,       // Secret weapon - visceral fat indicator
    HealthDataType.BASAL_ENERGY_BURNED,       // BMR - will use yearly average for accuracy
    HealthDataType.ACTIVE_ENERGY_BURNED,      // Active calories
    
    // =========================================================================
    // 3. Recovery & Nervous System (The "Brain" of the app)
    // =========================================================================
    HealthDataType.SLEEP_ASLEEP,              // Sleep duration
    HealthDataType.SLEEP_IN_BED,              // Time in bed
    HealthDataType.HEART_RATE_VARIABILITY_SDNN, // HRV - fatigue/stress detector
    HealthDataType.RESTING_HEART_RATE,        // Lower = more efficient heart
    HealthDataType.HEART_RATE,                // General heart rate readings
    HealthDataType.WALKING_HEART_RATE,        // Heart rate during walking
    // Note: VO2_MAX not yet available in Flutter health package v13.3.0
    // Will be added when package supports it
    
    // =========================================================================
    // 4. Workout (for writing sessions to HealthKit)
    // =========================================================================
    HealthDataType.WORKOUT,
  ];
  
  /// Request authorization to access HealthKit data
  /// Call this on first launch or when new data types are added
  Future<bool> requestAuthorization() async {
    try {
      print('🍎 Requesting HealthKit authorization for ${_readTypes.length} data types...');
      
      final permissions = _readTypes.map((type) {
        // Request write permission for workout, read for everything else
        if (type == HealthDataType.WORKOUT) {
          return HealthDataAccess.WRITE;
        }
        return HealthDataAccess.READ;
      }).toList();
      
      final granted = await _health.requestAuthorization(
        _readTypes,
        permissions: permissions,
      );
      
      if (granted) {
        print('✅ HealthKit authorization granted');
      } else {
        print('⚠️ HealthKit authorization denied or partially granted');
      }
      
      return granted;
    } catch (e) {
      print('❌ Error requesting HealthKit authorization: $e');
      return false;
    }
  }
  
  /// Force re-authorization (useful after adding new data types)
  /// This will show the permission dialog again
  Future<bool> reauthorize() async {
    print('🔄 Re-requesting HealthKit authorization...');
    return await requestAuthorization();
  }
  
  /// Check if we have authorization for required data types
  /// Note: iOS doesn't always expose permission status, so we try to fetch data
  /// If we can fetch data, permissions are granted
  Future<bool> checkAuthorizationStatus() async {
    try {
      // Try to fetch a small amount of recent data to verify permissions
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      // Try to fetch weight data as a test
      final testData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.WEIGHT],
      );
      
      // If we can fetch data (even if empty), permissions are granted
      // Empty list means no data but permissions are OK
      // Null or exception means no permissions
      return testData != null;
    } catch (e) {
      print('Error checking HealthKit authorization: $e');
      // If there's an error, try to request authorization again
      print('🔄 Authorization check failed, requesting permissions...');
      return await requestAuthorization();
    }
  }
  
  /// Fetch body metrics (weight, body fat, lean mass, BMI, waist, BMR) for a date range
  /// Groups data by date and uses REAL values from Apple Health (not estimates)
  /// For BMR, uses yearly average for accuracy instead of daily fluctuations
  Future<List<BodyMetrics>> fetchBodyMetrics({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Get height first (constant value, needed for BMI calculation if not in HealthKit)
      final height = await fetchHeight() ?? 175.0; // Default 175cm if not available
      
      // Fetch each data type separately to handle authorization gracefully
      // Some types may not be authorized, so we catch errors individually
      List<HealthDataPoint> weightData = [];
      List<HealthDataPoint> bodyFatData = [];
      List<HealthDataPoint> leanMassData = [];
      List<HealthDataPoint> bmiData = [];
      List<HealthDataPoint> waistData = [];
      
      // Weight (core metric - should always be available)
      try {
        weightData = await _health.getHealthDataFromTypes(
          startTime: start, endTime: end, types: [HealthDataType.WEIGHT],
        );
      } catch (e) {
        print('⚠️ Could not fetch weight data: $e');
      }
      
      // Body Fat Percentage
      try {
        bodyFatData = await _health.getHealthDataFromTypes(
          startTime: start, endTime: end, types: [HealthDataType.BODY_FAT_PERCENTAGE],
        );
      } catch (e) {
        print('⚠️ Could not fetch body fat data: $e');
      }
      
      // Lean Body Mass (optional - may not be available on all devices)
      try {
        leanMassData = await _health.getHealthDataFromTypes(
          startTime: start, endTime: end, types: [HealthDataType.LEAN_BODY_MASS],
        );
      } catch (e) {
        print('⚠️ Lean body mass not available: $e');
      }
      
      // BMI (optional - may not be available on all devices)
      try {
        bmiData = await _health.getHealthDataFromTypes(
          startTime: start, endTime: end, types: [HealthDataType.BODY_MASS_INDEX],
        );
      } catch (e) {
        print('⚠️ BMI not available: $e');
      }
      
      // Waist Circumference (optional - requires manual entry in Health app)
      try {
        waistData = await _health.getHealthDataFromTypes(
          startTime: start, endTime: end, types: [HealthDataType.WAIST_CIRCUMFERENCE],
        );
      } catch (e) {
        print('⚠️ Waist circumference not available: $e');
      }
      
      // Get yearly average BMR for accuracy (daily BMR fluctuates too much)
      final yearlyAvgBmr = await fetchYearlyAverageBMR();
      
      // Group data by date (normalize to midnight)
      final Map<DateTime, Map<String, double>> dataByDate = {};
      
      // Weight
      for (var point in weightData) {
        final date = _normalizeDate(point.dateFrom);
        dataByDate[date] ??= {};
        dataByDate[date]!['weight'] = (point.value as NumericHealthValue).numericValue.toDouble();
      }
      
      // Body Fat Percentage (KPI #1 - target 10-12% for visible abs)
      for (var point in bodyFatData) {
        final date = _normalizeDate(point.dateFrom);
        dataByDate[date] ??= {};
        dataByDate[date]!['bodyFat'] = (point.value as NumericHealthValue).numericValue.toDouble();
      }
      
      // Lean Body Mass (real value from HealthKit, not estimated)
      for (var point in leanMassData) {
        final date = _normalizeDate(point.dateFrom);
        dataByDate[date] ??= {};
        dataByDate[date]!['leanMass'] = (point.value as NumericHealthValue).numericValue.toDouble();
      }
      
      // BMI (real value from HealthKit)
      for (var point in bmiData) {
        final date = _normalizeDate(point.dateFrom);
        dataByDate[date] ??= {};
        dataByDate[date]!['bmi'] = (point.value as NumericHealthValue).numericValue.toDouble();
      }
      
      // Waist Circumference (secret weapon - visceral fat indicator)
      for (var point in waistData) {
        final date = _normalizeDate(point.dateFrom);
        dataByDate[date] ??= {};
        // Convert from meters to cm if needed
        double waist = (point.value as NumericHealthValue).numericValue.toDouble();
        if (waist < 2.0) waist *= 100; // Likely in meters, convert to cm
        dataByDate[date]!['waist'] = waist;
      }
      
      // Convert grouped data to BodyMetrics objects
      final List<BodyMetrics> metrics = [];
      for (var entry in dataByDate.entries) {
        final data = entry.value;
        
        // Only create a metric if we have at least weight data
        if (data.containsKey('weight')) {
          final weight = data['weight']!;
          final bodyFat = data['bodyFat'] ?? 0.0;
          
          // Use REAL lean body mass from HealthKit, or calculate from body fat if not available
          double leanMass;
          if (data.containsKey('leanMass')) {
            leanMass = data['leanMass']!;
          } else if (bodyFat > 0) {
            // Calculate: Lean Mass = Weight - Fat Mass
            final fatMass = weight * (bodyFat / 100);
            leanMass = weight - fatMass;
          } else {
            leanMass = 0.0;
          }
          
          // Use REAL BMI from HealthKit, or calculate from height
          double bmi;
          if (data.containsKey('bmi')) {
            bmi = data['bmi']!;
          } else {
            // Calculate: BMI = weight(kg) / height(m)²
            final heightInMeters = height / 100;
            bmi = weight / (heightInMeters * heightInMeters);
          }
          
          // Skeletal muscle estimate: ~45% of lean mass
          final skeletalMuscle = leanMass > 0 ? leanMass * 0.45 : 0.0;
          
          // Waist circumference
          final waist = data['waist'];
          
          metrics.add(BodyMetrics(
            id: '${entry.key.millisecondsSinceEpoch}',
            userId: 'default',
            weight: weight,
            bodyFat: bodyFat,
            skeletalMuscle: skeletalMuscle,
            bmi: bmi,
            bmr: yearlyAvgBmr, // Use yearly average for consistency
            height: height,
            leanBodyMass: leanMass,
            waistCircumference: waist,
            timestamp: entry.key,
          ));
        }
      }
      
      // Sort by date (newest first)
      metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return metrics;
    } catch (e) {
      print('Error fetching body metrics from HealthKit: $e');
      return [];
    }
  }
  
  /// Fetch yearly average BMR for more accurate calculations
  /// Groups BMR data by day and calculates daily totals, then averages the daily totals
  Future<int> fetchYearlyAverageBMR() async {
    try {
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      
      final bmrData = await _health.getHealthDataFromTypes(
        startTime: oneYearAgo,
        endTime: now,
        types: [HealthDataType.BASAL_ENERGY_BURNED],
      );
      
      if (bmrData.isEmpty) {
        print('⚠️ No BMR data found in HealthKit for the past year');
        return await _calculateFallbackBMR() ?? 1200;
      }
      
      // Group BMR data by date and sum daily totals
      final Map<DateTime, double> dailyBMR = {};
      
      for (var point in bmrData) {
        final date = _normalizeDate(point.dateFrom);
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        
        if (dailyBMR.containsKey(date)) {
          dailyBMR[date] = dailyBMR[date]! + value;
        } else {
          dailyBMR[date] = value;
        }
      }
      
      if (dailyBMR.isEmpty) {
        print('⚠️ No valid BMR data after grouping by date');
        return 0;
      }
      
      // Calculate average of daily totals
      final totalDailyBMR = dailyBMR.values.reduce((a, b) => a + b);
      final avgDailyBMR = (totalDailyBMR / dailyBMR.length).round();
      
      print('✅ Yearly average BMR: $avgDailyBMR kcal/day (from ${dailyBMR.length} days, ${bmrData.length} data points)');
      
      // Sanity check: BMR should be at least 800 kcal/day for adults
      // If the calculated BMR is too low, there might be a data issue
      if (avgDailyBMR < 800) {
        print('⚠️ Calculated BMR ($avgDailyBMR kcal) seems too low. Using fallback estimation.');
        return await _calculateFallbackBMR() ?? 1200; // Conservative fallback
      }
      
      return avgDailyBMR;
    } catch (e) {
      print('Error fetching yearly average BMR: $e');
      // Try fallback calculation if HealthKit fails
      return await _calculateFallbackBMR() ?? 1200;
    }
  }
  
  /// Calculate BMR using Harris-Benedict equation as fallback
  Future<int?> _calculateFallbackBMR() async {
    try {
      final height = await fetchHeight(); // in cm
      final weight = await _getLatestWeight(); // in kg
      final sex = await fetchBiologicalSex(); 
      final birthDate = await fetchDateOfBirth();
      
      if (height == null || weight == null || sex == null || birthDate == null) {
        print('⚠️ Missing data for BMR calculation (height: $height, weight: $weight, sex: $sex, birthDate: $birthDate)');
        return null;
      }
      
      final age = DateTime.now().difference(birthDate).inDays ~/ 365;
      
      // Harris-Benedict equation (revised)
      double bmr;
      if (sex == 'male') {
        bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
      } else {
        bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
      }
      
      print('✅ Calculated fallback BMR: ${bmr.round()} kcal/day using Harris-Benedict');
      return bmr.round();
    } catch (e) {
      print('Error calculating fallback BMR: $e');
      return null;
    }
  }
  
  /// Get the most recent weight for BMR calculations
  Future<double?> _getLatestWeight() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final metrics = await fetchBodyMetrics(start: thirtyDaysAgo, end: now);
    return metrics.isNotEmpty ? metrics.last.weight : null;
  }
  
  /// Fetch the most recent body metrics from the last 30 days
  Future<BodyMetrics?> fetchLatestBodyMetrics() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final metrics = await fetchBodyMetrics(
      start: thirtyDaysAgo,
      end: now,
    );
    
    return metrics.isNotEmpty ? metrics.first : null;
  }
  
  /// Fetch recovery metrics (sleep, HRV, resting HR) for a specific date
  Future<RecoveryMetrics?> fetchRecoveryMetrics(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Fetch sleep data
      final sleepData = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: [HealthDataType.SLEEP_ASLEEP],
      );
      
      // Calculate total sleep hours
      double sleepHours = 0.0;
      for (var point in sleepData) {
        final duration = point.dateTo.difference(point.dateFrom);
        sleepHours += duration.inMinutes / 60.0;
      }
      
      // Fallback for missing sleep data (user's average: 7 hours)
      if (sleepHours == 0.0) {
        sleepHours = 7.0;
      }
      
      // Fetch HRV data
      final hrvData = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
      );
      
      // Get average HRV
      double avgHrv = 0.0;
      if (hrvData.isNotEmpty) {
        final hrvValues = hrvData.map((p) => (p.value as NumericHealthValue).numericValue.toDouble());
        avgHrv = hrvValues.reduce((a, b) => a + b) / hrvValues.length;
      }
      
      // Fallback for missing HRV data (default reasonable value)
      if (avgHrv == 0.0) {
        avgHrv = 35.0; // Typical HRV value for healthy adults
      }
      
      // Get resting heart rate
      final rhrData = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: [HealthDataType.RESTING_HEART_RATE],
      );
      
      double restingHR = 0.0;
      if (rhrData.isNotEmpty) {
        final hrValues = rhrData.map((p) => (p.value as NumericHealthValue).numericValue.toDouble());
        restingHR = hrValues.reduce((a, b) => a + b) / hrValues.length;
      }
      
      // Fallback for missing resting heart rate data (user's average: 67 bpm)
      if (restingHR == 0.0) {
        restingHR = 67.0;
      }
      
      return RecoveryMetrics(
        date: date,
        sleepHours: sleepHours,
        hrv: avgHrv,
        restingHR: restingHR,
      );
    } catch (e) {
      print('Error fetching recovery metrics: $e');
      return null;
    }
  }

  /// Check if specific health data types are authorized
  Future<bool> hasPermissions(List<HealthDataType> types) async {
    try {
      final authorized = await _health.hasPermissions(types);
      return authorized == true;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }
  
  /// Fetch heart rate metrics for a specific date
  Future<HeartRateMetrics?> fetchHeartRateMetrics(DateTime date) async {
    try {
      // Debug permissions status first
      await debugPermissions();
      
      // Check if heart rate data types are authorized
      final heartRateTypes = [
        HealthDataType.HEART_RATE,
        HealthDataType.WALKING_HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
      ];
      
      final authorized = await _health.hasPermissions(heartRateTypes);
      
      if (authorized != true) {
        print('🔄 Heart rate data not authorized. Requesting specific heart rate authorization...');
        
        // Request authorization specifically for heart rate data types
        final granted = await _health.requestAuthorization(
          heartRateTypes,
          permissions: heartRateTypes.map((_) => HealthDataAccess.READ).toList(),
        );
        
        if (!granted) {
          print('⚠️ Heart rate authorization denied. Please enable in Apple Health settings manually.');
        } else {
          print('✅ Heart rate authorization granted!');
          
          // Double-check permissions after authorization
          final recheck = await _health.hasPermissions(heartRateTypes);
          if (recheck != true) {
            print('⚠️ Authorization granted but permissions still denied.');
            print('📱 Please open Apple Health → Sources → Forty Five Min → Turn on Heart Rate data');
            print('📍 Or go to Settings → Privacy & Security → Health → Forty Five Min');
          }
        }
      }
      
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Fetch general heart rate data
      final heartRateData = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: [HealthDataType.HEART_RATE],
      );
      
      print('📊 Heart rate data points found: ${heartRateData.length}');
      
      double avgHeartRate = 0.0;
      if (heartRateData.isNotEmpty) {
        final hrValues = heartRateData.map((p) => (p.value as NumericHealthValue).numericValue.toDouble());
        avgHeartRate = hrValues.reduce((a, b) => a + b) / hrValues.length;
      }
      
      // Fallback for missing heart rate data
      if (avgHeartRate == 0.0) {
        avgHeartRate = 75.0; // Typical resting heart rate
      }
      
      // Fetch walking heart rate average
      final walkingHRData = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: [HealthDataType.WALKING_HEART_RATE],
      );
      
      double walkingHeartRate = 0.0;
      if (walkingHRData.isNotEmpty) {
        final whrValues = walkingHRData.map((p) => (p.value as NumericHealthValue).numericValue.toDouble());
        walkingHeartRate = whrValues.reduce((a, b) => a + b) / whrValues.length;
      }
      
      // Fallback for missing walking heart rate data
      if (walkingHeartRate == 0.0) {
        walkingHeartRate = 90.0; // Typical walking heart rate
      }
      
      // VO2 Max (Cardio Fitness) - Not available in Flutter health package v13.3.0
      // When available, this would fetch actual VO2 max data from Apple Health
      // For now, calculate estimated VO2 max based on age and fitness level
      // VO2 max typically ranges from 14-60 ml/kg/min per Apple documentation
      
      double vo2Max = _estimateVO2Max(); // Use estimation method for now
      
      // Fallback for missing VO2 max data
      if (vo2Max == 0.0) {
        vo2Max = 35.0; // Average VO2 max for healthy adults (ml/kg/min)
      }
      
      return HeartRateMetrics(
        date: date,
        averageHeartRate: avgHeartRate,
        walkingHeartRate: walkingHeartRate,
        vo2Max: vo2Max,
      );
    } catch (e) {
      print('Error fetching heart rate metrics: $e');
      return null;
    }
  }

  /// Estimate VO2 max based on age and fitness level
  /// This is a placeholder until VO2_MAX is available in Flutter health package
  /// Uses estimated values based on age and general fitness level
  double _estimateVO2Max() {
    try {
      // For now, return a reasonable estimate for a healthy adult
      // Real VO2 max ranges from 14-60 ml/kg/min according to Apple docs
      // Sedentary: 15-30, Active: 30-50, Athletic: 50-60+
      // We'll use 35.0 as a moderate fitness level estimate
      return 35.0; // ml/kg/min - reasonable estimate for healthy adults
    } catch (e) {
      return 35.0; // fallback value
    }
  }

  /// Debug method to check all health permissions status
  Future<void> debugPermissions() async {
    try {
      print('🔍 Debugging Health Permissions:');
      
      final heartRateTypes = [
        HealthDataType.HEART_RATE,
        HealthDataType.WALKING_HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
      ];
      
      for (var type in heartRateTypes) {
        final hasPermission = await _health.hasPermissions([type]);
        print('  $type: ${(hasPermission == true) ? "✅ Granted" : "❌ Denied"}');
      }
      
      final allPermissions = await _health.hasPermissions(_readTypes);
      print('  All permissions: ${(allPermissions == true) ? "✅ Granted" : "❌ Some denied"}');
      
    } catch (e) {
      print('❌ Error checking permissions: $e');
    }
  }
  
  /// Fetch active calories burned for a specific date
  Future<double> fetchActiveCalories(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final caloriesData = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      
      double totalCalories = 0.0;
      for (var point in caloriesData) {
        totalCalories += (point.value as NumericHealthValue).numericValue.toDouble();
      }
      
      return totalCalories;
    } catch (e) {
      print('Error fetching active calories: $e');
      return 0.0;
    }
  }
  
  /// Write a workout session to HealthKit
  Future<bool> writeWorkoutSession({
    required String workoutName,
    required DateTime start,
    required DateTime end,
    required int caloriesBurned,
  }) async {
    try {
      final success = await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.STRENGTH_TRAINING,
        start: start,
        end: end,
        totalEnergyBurned: caloriesBurned,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );
      
      return success;
    } catch (e) {
      print('Error writing workout to HealthKit: $e');
      return false;
    }
  }
  
  /// Fetch height from Apple Health
  /// Returns height in cm, or null if not available
  Future<double?> fetchHeight() async {
    try {
      final heightData = await _health.getHealthDataFromTypes(
        startTime: DateTime.now().subtract(const Duration(days: 365)),
        endTime: DateTime.now(),
        types: [HealthDataType.HEIGHT],
      );
      
      if (heightData.isNotEmpty) {
        // Get most recent height measurement
        final heightValue = heightData.last.value as NumericHealthValue;
        double height = heightValue.numericValue.toDouble();
        // Convert from meters to cm if needed
        if (height < 3.0) {
          height = height * 100; // Convert meters to cm
        }
        return height;
      }
      
      return null;
    } catch (e) {
      print('Error fetching height from HealthKit: $e');
      return null;
    }
  }
  
  /// Fetch user's biological sex from Apple Health
  /// Returns 'male', 'female', or null if not available
  Future<String?> fetchBiologicalSex() async {
    try {
      final now = DateTime.now();
      final longAgo = now.subtract(const Duration(days: 365 * 100)); // 100 years back
      
      final genderData = await _health.getHealthDataFromTypes(
        startTime: longAgo,
        endTime: now,
        types: [HealthDataType.GENDER],
      );
      
      if (genderData.isNotEmpty) {
        // The value should be a string like 'male', 'female', 'other'
        final genderValue = genderData.last.value.toString().toLowerCase();
        print('✅ Biological sex from Apple Health: $genderValue');
        
        if (genderValue.contains('male') && !genderValue.contains('female')) {
          return 'male';
        } else if (genderValue.contains('female')) {
          return 'female';
        }
        return genderValue;
      }
      
      print('⚠️ No biological sex data in Apple Health');
      return null;
    } catch (e) {
      print('⚠️ Could not fetch biological sex: $e');
      return null;
    }
  }
  
  /// Fetch user's date of birth from Apple Health
  /// Returns birth date or null if not available
  Future<DateTime?> fetchDateOfBirth() async {
    try {
      final now = DateTime.now();
      final longAgo = now.subtract(const Duration(days: 365 * 100)); // 100 years back
      
      final birthData = await _health.getHealthDataFromTypes(
        startTime: longAgo,
        endTime: now,
        types: [HealthDataType.BIRTH_DATE],
      );
      
      if (birthData.isNotEmpty) {
        // The dateFrom should contain the birth date
        final birthDate = birthData.last.dateFrom;
        print('✅ Date of birth from Apple Health: $birthDate');
        return birthDate;
      }
      
      print('⚠️ No date of birth data in Apple Health');
      return null;
    } catch (e) {
      print('⚠️ Could not fetch date of birth: $e');
      return null;
    }
  }
  
  /// Fetch complete user health profile (height, sex, age)
  /// These are "constants" used for BMR and calorie calculations
  Future<UserHealthProfile> fetchUserHealthProfile() async {
    try {
      print('🍎 Fetching user health profile from Apple Health...');
      
      // Fetch all profile data in parallel
      final results = await Future.wait([
        fetchHeight(),
        fetchBiologicalSex(),
        fetchDateOfBirth(),
      ]);
      
      final height = results[0] as double?;
      final biologicalSex = results[1] as String?;
      final dateOfBirth = results[2] as DateTime?;
      
      // Calculate age from date of birth
      int? age;
      if (dateOfBirth != null) {
        final now = DateTime.now();
        age = now.year - dateOfBirth.year;
        if (now.month < dateOfBirth.month ||
            (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
          age--;
        }
      }
      
      print('✅ Health Profile: height=$height cm, sex=$biologicalSex, age=$age');
      
      return UserHealthProfile(
        height: height,
        biologicalSex: biologicalSex,
        dateOfBirth: dateOfBirth,
        age: age,
      );
    } catch (e) {
      print('Error fetching user health profile: $e');
      return const UserHealthProfile();
    }
  }
  
  /// Fetch waist circumference from Apple Health
  /// This is the "secret weapon" - indicates visceral fat loss even when weight stagnates
  Future<double?> fetchWaistCircumference() async {
    try {
      final waistData = await _health.getHealthDataFromTypes(
        startTime: DateTime.now().subtract(const Duration(days: 30)),
        endTime: DateTime.now(),
        types: [HealthDataType.WAIST_CIRCUMFERENCE],
      );
      
      if (waistData.isNotEmpty) {
        double waist = (waistData.last.value as NumericHealthValue).numericValue.toDouble();
        // Convert from meters to cm if needed
        if (waist < 2.0) waist *= 100;
        print('✅ Latest waist circumference: $waist cm');
        return waist;
      }
      
      return null;
    } catch (e) {
      print('Error fetching waist circumference: $e');
      return null;
    }
  }
  
  /// Deduplicate body metrics - prefer scale readings over estimates
  /// This helps when you have both InBody scale data and Apple Watch estimates
  List<BodyMetrics> deduplicateMetrics(List<BodyMetrics> metrics) {
    if (metrics.isEmpty) return [];
    
    // Group by date
    final Map<String, List<BodyMetrics>> byDate = {};
    for (var metric in metrics) {
      final dateKey = _normalizeDate(metric.timestamp).toIso8601String();
      byDate[dateKey] ??= [];
      byDate[dateKey]!.add(metric);
    }
    
    // For each date, keep the most complete measurement
    final List<BodyMetrics> deduplicated = [];
    for (var dateMetrics in byDate.values) {
      if (dateMetrics.length == 1) {
        deduplicated.add(dateMetrics.first);
      } else {
        // Sort by "completeness" - metrics with more data are preferred
        dateMetrics.sort((a, b) {
          int scoreA = _calculateCompletenessScore(a);
          int scoreB = _calculateCompletenessScore(b);
          return scoreB.compareTo(scoreA);
        });
        deduplicated.add(dateMetrics.first);
      }
    }
    
    // Sort by date (newest first)
    deduplicated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return deduplicated;
  }
  
  /// Calculate how complete a body metric reading is (more fields = higher score)
  int _calculateCompletenessScore(BodyMetrics metric) {
    int score = 0;
    if (metric.weight > 0) score++;
    if (metric.bodyFat > 0) score++;
    if (metric.skeletalMuscle > 0) score++;
    if (metric.bmr > 0) score++;
    return score;
  }
  
  /// Normalize a DateTime to midnight (removes time component)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Fetch recent workout data from Apple Health to detect conflicts
  /// Returns list of workouts with type and duration
  Future<List<WorkoutData>> fetchRecentWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final workouts = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.WORKOUT],
      );

      if (workouts == null || workouts.isEmpty) {
        return [];
      }

      final workoutDataList = <WorkoutData>[];
      
      for (var workout in workouts) {
        // Extract workout type and duration
        // Note: HealthKit workout type isn't directly exposed in all versions
        // We'll use a generic "Cardio" type for now
        final workoutType = workout.type.name;
        final start = workout.dateFrom;
        final end = workout.dateTo;
        final durationMinutes = end.difference(start).inMinutes;
        
        workoutDataList.add(WorkoutData(
          type: workoutType,
          startTime: start,
          endTime: end,
          durationMinutes: durationMinutes,
          distance: null, // Distance not directly available from HealthDataPoint
        ));
      }

      return workoutDataList;
    } catch (e) {
      print('Error fetching recent workouts: $e');
      return [];
    }
  }

  /// Check if user did significant cardio today (running, cycling, etc.)
  Future<bool> hasSignificantCardioToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final workouts = await fetchRecentWorkouts(
        start: startOfDay,
        end: now,
      );

      // Check for significant cardio activities
      const cardioTypes = [
        'RUNNING',
        'CYCLING',
        'SWIMMING',
        'ROWING',
        'HIKING',
        'STAIR_CLIMBING',
      ];

      for (var workout in workouts) {
        final type = workout.type.toUpperCase();
        
        // Check if it's cardio and significant duration/distance
        if (cardioTypes.any((cardio) => type.contains(cardio))) {
          // Running/Cycling: >5km or >30 minutes
          if (workout.distance != null && workout.distance! > 5000) {
            return true; // More than 5km
          }
          if (workout.durationMinutes > 30) {
            return true; // More than 30 minutes
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking cardio activity: $e');
      return false; // Default to no conflict on error
    }
  }
}

/// Data class for recovery metrics
class RecoveryMetrics {
  final DateTime date;
  final double sleepHours;
  final double hrv; // HRV in milliseconds
  final double restingHR; // Resting heart rate in BPM
  
  const RecoveryMetrics({
    required this.date,
    required this.sleepHours,
    required this.hrv,
    required this.restingHR,
  });
}

/// Data class for heart rate metrics from HealthKit
class HeartRateMetrics {
  final DateTime date;
  final double averageHeartRate; // Average heart rate in BPM
  final double walkingHeartRate; // Walking heart rate average in BPM
  final double vo2Max; // VO2 Max in ml/kg/min
  
  const HeartRateMetrics({
    required this.date,
    required this.averageHeartRate,
    required this.walkingHeartRate,
    required this.vo2Max,
  });
}

/// Data class for workout data from HealthKit
class WorkoutData {
  final String type; // e.g., "RUNNING", "CYCLING"
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double? distance; // Distance in meters (null for non-distance activities)

  const WorkoutData({
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.distance,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distance == null) return '';
    final km = distance! / 1000;
    return '${km.toStringAsFixed(1)}km';
  }

  /// Get formatted duration string
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// User health profile constants from Apple Health
/// These are used for BMR and calorie calculations (Morphologie & Profil)
class UserHealthProfile {
  final double? height;        // cm - for BMI and symmetry check
  final String? biologicalSex; // 'male' or 'female' - changes calorie formulas
  final DateTime? dateOfBirth; // For precise age calculation
  final int? age;              // Calculated from dateOfBirth (metabolism slows with age)
  
  const UserHealthProfile({
    this.height,
    this.biologicalSex,
    this.dateOfBirth,
    this.age,
  });
  
  /// Check if profile has enough data for BMR calculation
  bool get hasMinimumDataForBMR {
    return height != null && biologicalSex != null && age != null;
  }
  
  /// Get gender string for BMR calculation
  String get genderForCalculation => biologicalSex ?? 'male';
  
  /// Get age for calculation (default to 30 if not available)
  int get ageForCalculation => age ?? 30;
  
  /// Get height for calculation (default to 175cm if not available)
  double get heightForCalculation => height ?? 175.0;
}
