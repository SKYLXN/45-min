import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/body_metrics.dart';
import '../../providers/body_analytics_provider.dart';

/// Manual body metrics entry screen for users without smart scales or on Android
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for input fields
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _skeletalMuscleController = TextEditingController();
  final _visceralFatController = TextEditingController();
  final _boneMassController = TextEditingController();
  final _waterPercentageController = TextEditingController();
  final _metabolicAgeController = TextEditingController();
  
  bool _isSaving = false;
  
  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _skeletalMuscleController.dispose();
    _visceralFatController.dispose();
    _boneMassController.dispose();
    _waterPercentageController.dispose();
    _metabolicAgeController.dispose();
    super.dispose();
  }
  
  Future<void> _saveMetrics() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final weight = double.parse(_weightController.text);
      final bodyFat = _bodyFatController.text.isNotEmpty 
          ? double.parse(_bodyFatController.text) 
          : null;
      final skeletalMuscle = _skeletalMuscleController.text.isNotEmpty 
          ? double.parse(_skeletalMuscleController.text) 
          : null;
      
      // Calculate BMI (assuming height from user profile - placeholder 170cm)
      // TODO: Get actual height from UserProfile
      const heightInMeters = 1.70;
      final bmi = weight / (heightInMeters * heightInMeters);
      
      // Calculate BMR using Mifflin-St Jeor equation (male, 30 years old - placeholder)
      // TODO: Get actual age and gender from UserProfile
      final bmr = (10 * weight) + (6.25 * 170) - (5 * 30) + 5;
      
      // Calculate skeletal muscle from body fat if not provided
      double? calculatedSkeletalMuscle = skeletalMuscle;
      if (calculatedSkeletalMuscle == null && bodyFat != null) {
        final leanMass = weight * (1 - bodyFat / 100);
        calculatedSkeletalMuscle = leanMass * 0.45; // Approximation: 45% of lean mass
      }
      
      final metrics = BodyMetrics(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weight: weight,
        bmi: bmi,
        skeletalMuscle: calculatedSkeletalMuscle,
        bodyFat: bodyFat,
        bmr: bmr,
        visceralFat: _visceralFatController.text.isNotEmpty 
            ? double.parse(_visceralFatController.text) 
            : null,
        boneMass: _boneMassController.text.isNotEmpty 
            ? double.parse(_boneMassController.text) 
            : null,
        waterPercentage: _waterPercentageController.text.isNotEmpty 
            ? double.parse(_waterPercentageController.text) 
            : null,
        metabolicAge: _metabolicAgeController.text.isNotEmpty 
            ? int.parse(_metabolicAgeController.text) 
            : null,
        timestamp: DateTime.now(),
      );
      
      await ref.read(bodyAnalyticsProvider.notifier).saveBodyMetrics(metrics);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Body metrics saved successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Manual Entry'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveMetrics,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Weight is required. Other metrics are optional but help improve workout recommendations.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Required section
            Text(
              'Required',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _weightController,
              label: 'Weight (kg)',
              hint: 'e.g., 73.2',
              icon: Icons.monitor_weight_outlined,
              isRequired: true,
            ),
            
            const SizedBox(height: 24),
            
            // Optional section
            Text(
              'Optional',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _bodyFatController,
              label: 'Body Fat %',
              hint: 'e.g., 15.9',
              icon: Icons.percent,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _skeletalMuscleController,
              label: 'Skeletal Muscle (kg)',
              hint: 'e.g., 35.2',
              icon: Icons.fitness_center,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _visceralFatController,
              label: 'Visceral Fat Level',
              hint: 'e.g., 8',
              icon: Icons.warning_amber_outlined,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _boneMassController,
              label: 'Bone Mass (kg)',
              hint: 'e.g., 3.2',
              icon: Icons.accessibility_new,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _waterPercentageController,
              label: 'Water %',
              hint: 'e.g., 58.5',
              icon: Icons.water_drop_outlined,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _metabolicAgeController,
              label: 'Metabolic Age',
              hint: 'e.g., 25',
              icon: Icons.calendar_today_outlined,
              isInteger: true,
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveMetrics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: AppColors.backgroundDark)
                    : const Text(
                        'Save Metrics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool isInteger = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        if (value != null && value.isNotEmpty) {
          if (isInteger) {
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
          } else {
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
          }
        }
        return null;
      },
    );
  }
}
