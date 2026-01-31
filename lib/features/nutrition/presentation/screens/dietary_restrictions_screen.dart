import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/dietary_profile_provider.dart';
import '../../data/models/dietary_restriction.dart';

/// Dietary Restrictions Setup Screen
class DietaryRestrictionsScreen extends ConsumerStatefulWidget {
  const DietaryRestrictionsScreen({super.key});

  @override
  ConsumerState<DietaryRestrictionsScreen> createState() =>
      _DietaryRestrictionsScreenState();
}

class _DietaryRestrictionsScreenState
    extends ConsumerState<DietaryRestrictionsScreen> {
  final _customExclusionController = TextEditingController();

  @override
  void dispose() {
    _customExclusionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(dietaryProfileProvider);
    final restrictionsByCategory = {
      'allergy': PredefinedRestrictions.all.where((r) => r.category == 'allergy').toList(),
      'religious': PredefinedRestrictions.all.where((r) => r.category == 'religious').toList(),
      'preference': PredefinedRestrictions.all.where((r) => r.category == 'preference').toList(),
      'health': PredefinedRestrictions.all.where((r) => r.category == 'health').toList(),
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Dietary Restrictions'),
        backgroundColor: AppColors.cardBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen.withOpacity(0.2),
                        AppColors.primaryGreen.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'These restrictions will be applied when searching for recipes',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...restrictionsByCategory.entries.map((entry) {
                  return _buildCategorySection(entry.key, entry.value);
                }),
                const SizedBox(height: 24),
                _buildCustomExclusionsSection(),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                // Restrictions are auto-saved through toggleRestriction
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dietary restrictions saved'),
                      backgroundColor: AppColors.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Saved'),
              backgroundColor: AppColors.primaryGreen,
            ),
    );
  }

  Widget _buildCategorySection(
    String category,
    List<DietaryRestriction> restrictions,
  ) {
    if (restrictions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(_getCategoryIcon(category), color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                _getCategoryName(category),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: restrictions
              .map((restriction) => _buildRestrictionChip(restriction))
              .toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRestrictionChip(DietaryRestriction restriction) {
    final isActive = ref.watch(isRestrictionActiveProvider(restriction.id));

    return FilterChip(
      label: Text(restriction.name),
      selected: isActive,
      onSelected: (selected) {
        ref.read(dietaryProfileProvider.notifier).toggleRestriction(restriction.id);
      },
      backgroundColor: AppColors.cardBackground,
      selectedColor: AppColors.primaryGreen.withOpacity(0.3),
      checkmarkColor: AppColors.primaryGreen,
      labelStyle: TextStyle(
        color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isActive
            ? AppColors.primaryGreen
            : AppColors.textSecondary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildCustomExclusionsSection() {
    final customExclusions = ref.watch(dietaryProfileProvider).profile.customExclusions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.block, color: AppColors.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              'Custom Exclusions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customExclusionController,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add ingredient to exclude...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) => _addCustomExclusion(value),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addCustomExclusion(_customExclusionController.text),
              icon: Icon(Icons.add_circle, color: AppColors.primaryGreen),
              iconSize: 32,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (customExclusions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: customExclusions.map((exclusion) {
              return Chip(
                label: Text(exclusion),
                onDeleted: () {
                  ref
                      .read(dietaryProfileProvider.notifier)
                      .removeCustomExclusion(exclusion);
                },
                backgroundColor: AppColors.cardBackground,
                deleteIconColor: AppColors.error,
                labelStyle: TextStyle(color: AppColors.textPrimary),
                side: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
              );
            }).toList(),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No custom exclusions added',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  void _addCustomExclusion(String value) {
    if (value.trim().isEmpty) return;

    ref.read(dietaryProfileProvider.notifier).addCustomExclusion(value.trim());
    _customExclusionController.clear();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'allergy':
        return Icons.warning_amber;
      case 'religious':
        return Icons.church;
      case 'preference':
        return Icons.favorite;
      case 'health':
        return Icons.health_and_safety;
      default:
        return Icons.restaurant;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'allergy':
        return 'Allergies';
      case 'religious':
        return 'Religious';
      case 'preference':
        return 'Dietary Preferences';
      case 'health':
        return 'Health-Based';
      default:
        return 'Other';
    }
  }
}
