import 'package:flutter/material.dart';
import '../../data/models/workout_set.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SetTracker extends StatelessWidget {
  final int currentSet;
  final int totalSets;
  final List<WorkoutSet> completedSets;

  const SetTracker({
    super.key,
    required this.currentSet,
    required this.totalSets,
    required this.completedSets,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Progress',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(totalSets, (index) {
            final setNumber = index + 1;
            final isCompleted = completedSets.any((s) => s.setNumber == setNumber);
            final isCurrent = setNumber == currentSet && !isCompleted;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < totalSets - 1 ? 8 : 0,
                ),
                child: _buildSetIndicator(
                  setNumber: setNumber,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  completedSet: isCompleted
                      ? completedSets.firstWhere((s) => s.setNumber == setNumber)
                      : null,
                ),
              ),
            );
          }),
        ),
        if (completedSets.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCompletedSetsTable(),
        ],
      ],
    );
  }

  Widget _buildSetIndicator({
    required int setNumber,
    required bool isCompleted,
    required bool isCurrent,
    WorkoutSet? completedSet,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? icon;

    if (isCompleted) {
      bgColor = AppColors.primaryGreen.withOpacity(0.2);
      borderColor = AppColors.primaryGreen;
      textColor = AppColors.primaryGreen;
      icon = const Icon(
        Icons.check,
        color: AppColors.primaryGreen,
        size: 20,
      );
    } else if (isCurrent) {
      bgColor = AppColors.primaryGold.withOpacity(0.2);
      borderColor = AppColors.primaryGold;
      textColor = AppColors.primaryGold;
    } else {
      bgColor = AppColors.cardBackground;
      borderColor = AppColors.textSecondary.withOpacity(0.3);
      textColor = AppColors.textSecondary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon ??
              Text(
                '$setNumber',
                style: AppTextStyles.h3.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          if (completedSet != null) ...[
            const SizedBox(height: 2),
            Text(
              '${completedSet.actualReps}×${completedSet.actualWeight}kg',
              style: AppTextStyles.caption.copyWith(
                color: textColor,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedSetsTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed Sets',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('Set'),
                  _buildTableHeader('Reps'),
                  _buildTableHeader('Weight'),
                  _buildTableHeader('RPE'),
                ],
              ),
              ...completedSets.map((set) => TableRow(
                    children: [
                      _buildTableCell('${set.setNumber}'),
                      _buildTableCell('${set.actualReps}'),
                      _buildTableCell('${set.actualWeight} kg'),
                      _buildTableCell('${set.rpe}'),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
