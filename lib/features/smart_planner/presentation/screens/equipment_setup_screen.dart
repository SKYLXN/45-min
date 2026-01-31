import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/equipment.dart';
import '../../providers/equipment_provider.dart';

class EquipmentSetupScreen extends ConsumerStatefulWidget {
  const EquipmentSetupScreen({super.key});

  @override
  ConsumerState<EquipmentSetupScreen> createState() =>
      _EquipmentSetupScreenState();
}

class _EquipmentSetupScreenState extends ConsumerState<EquipmentSetupScreen> {
  final Map<String, bool> _selectedEquipment = {};
  final Map<String, TextEditingController> _weightControllers = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for equipment with weight ranges
    for (final type in [EquipmentType.dumbbells.name, EquipmentType.kettlebell.name]) {
      _weightControllers[type] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _weightControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equipmentState = ref.watch(equipmentProvider);

    // Initialize selected equipment from state
    if (!_isInitialized && equipmentState.userEquipment.isNotEmpty) {
      for (final equipment in equipmentState.userEquipment) {
        final typeKey = equipment.type.name;
        _selectedEquipment[typeKey] = equipment.isAvailable;
        if (equipment.minWeight != null && equipment.maxWeight != null &&
            _weightControllers.containsKey(typeKey)) {
          _weightControllers[typeKey]!.text = '${equipment.minWeight}-${equipment.maxWeight}';
        }
      }
      _isInitialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Equipment Setup',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: equipmentState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 32),

                  // Equipment list
                  _buildEquipmentList(),
                  const SizedBox(height: 32),

                  // Save button
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Available Equipment',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'This helps us create personalized workout programs based on what you have access to.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentList() {
    return Column(
      children: EquipmentType.values.map((type) {
        return _buildEquipmentTile(type);
      }).toList(),
    );
  }

  Widget _buildEquipmentTile(EquipmentType type) {
    final typeKey = type.name;
    final isSelected = _selectedEquipment[typeKey] ?? false;
    final hasWeightRange = type == EquipmentType.dumbbells ||
        type == EquipmentType.kettlebell;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withOpacity(0.1)
                    : AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getEquipmentIcon(type),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              type.displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Switch(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  _selectedEquipment[typeKey] = value;
                });
              },
              activeColor: AppColors.primaryGreen,
            ),
          ),

          // Weight range input for applicable equipment
          if (isSelected && hasWeightRange)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _weightControllers[typeKey],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Weight Range (e.g., 5-30kg)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: '5-30',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.fitness_center,
                    color: AppColors.primaryGreen,
                  ),
                  suffixText: 'kg',
                  suffixStyle: const TextStyle(color: AppColors.textSecondary),
                ),
                keyboardType: TextInputType.text,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final selectedCount = _selectedEquipment.values.where((v) => v).length;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectedCount == 0 ? null : _saveEquipment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          selectedCount == 0
              ? 'Select at least one equipment'
              : 'Save Equipment ($selectedCount selected)',
          style: const TextStyle(
            color: AppColors.backgroundDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _saveEquipment() async {
    final equipment = <Equipment>[];

    _selectedEquipment.forEach((typeKey, isSelected) {
      if (isSelected) {
        // Parse equipment type from key
        final equipmentType = EquipmentType.values.firstWhere(
          (e) => e.name == typeKey,
          orElse: () => EquipmentType.other,
        );
        
        double? minWeight;
        double? maxWeight;
        if (_weightControllers.containsKey(typeKey)) {
          final text = _weightControllers[typeKey]!.text.trim();
          if (text.isNotEmpty) {
            // Parse weight range like "5-30" into min and max
            final parts = text.split('-');
            if (parts.length == 2) {
              minWeight = double.tryParse(parts[0].trim());
              maxWeight = double.tryParse(parts[1].trim());
            }
          }
        }

        equipment.add(Equipment(
          id: '${equipmentType.name}_${DateTime.now().millisecondsSinceEpoch}',
          type: equipmentType,
          isAvailable: true,
          minWeight: minWeight,
          maxWeight: maxWeight,
        ));
      }
    });

    // Save via provider
    await ref.read(equipmentProvider.notifier).saveEquipment(equipment);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Equipment saved successfully'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back
      context.go('/smart-planner');
    }
  }

  String _getEquipmentIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.bodyweight:
        return '🏃';
      case EquipmentType.dumbbells:
        return '🏋️';
      case EquipmentType.bench:
        return '🛏️';
      case EquipmentType.pullupBar:
        return '🤸';
      case EquipmentType.resistanceBands:
        return '🎗️';
      case EquipmentType.kettlebell:
        return '⚖️';
      case EquipmentType.other:
        return '⚡';
    }
  }
}
