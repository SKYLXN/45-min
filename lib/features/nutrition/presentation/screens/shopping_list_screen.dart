import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/weekly_meal_plan_provider.dart';
import '../../data/services/shopping_list_service.dart';
import '../../data/models/weekly_meal_plan.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingList = ref.watch(shoppingListProvider);
    final isExporting = ref.watch(weeklyMealPlanProvider).isExporting;

    if (shoppingList == null || shoppingList.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: const Text('Shopping List'),
        ),
        body: _buildEmptyState(),
      );
    }

    final service = ref.read(shoppingListServiceProvider);
    final grouped = service.groupByCategory(shoppingList);
    final totalItems = shoppingList.length;
    final estimatedCost = service.estimateTotalCost(shoppingList);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Get the RenderBox for positioning the share sheet on iPad
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              final Rect sharePositionOrigin = box != null
                  ? box.localToGlobal(Offset.zero) & box.size
                  : Rect.zero;
              
              _shareList(context, ref, shoppingList, sharePositionOrigin);
            },
            tooltip: 'Share list',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(totalItems, estimatedCost),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final category = grouped.keys.elementAt(index);
                final items = grouped[category]!;

                return _buildCategorySection(category, items);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: isExporting
                ? null
                : () => _exportToReminders(context, ref),
            backgroundColor: AppColors.primaryGreen,
            heroTag: 'export',
            icon: isExporting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : const Icon(Icons.apple, color: Colors.black),
            label: Text(
              isExporting ? 'Exporting...' : 'Export to Reminders',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Shopping List',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate a weekly meal plan first to create your shopping list.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int totalItems, double estimatedCost) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shopping List',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'For this week\'s meals',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalItems items',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Est: \$${estimatedCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _getCategoryIcon(category),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.textSecondary.withOpacity(0.1),
          ),
          ...items.map((item) => _buildShoppingItem(item)),
        ],
      ),
    );
  }

  Widget _buildShoppingItem(dynamic item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_box_outline_blank,
            color: AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.displayText,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (item.count > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item.count}×',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;

    switch (category) {
      case 'Produce':
        icon = Icons.eco;
        color = Colors.green;
        break;
      case 'Protein':
        icon = Icons.set_meal;
        color = Colors.red;
        break;
      case 'Dairy':
        icon = Icons.local_drink;
        color = Colors.blue;
        break;
      case 'Grains':
        icon = Icons.grain;
        color = Colors.amber;
        break;
      case 'Pantry':
        icon = Icons.kitchen;
        color = Colors.brown;
        break;
      case 'Spices':
        icon = Icons.spa;
        color = Colors.purple;
        break;
      default:
        icon = Icons.shopping_basket;
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Future<void> _exportToReminders(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(weeklyMealPlanProvider.notifier)
        .exportToReminders();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Exported to Apple Reminders!'
              : '❌ Export failed. Please grant Reminders access in Settings.',
        ),
        backgroundColor:
            success ? AppColors.primaryGreen : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _shareList(
    BuildContext context,
    WidgetRef ref,
    Map<String, AggregatedIngredient> shoppingList,
    Rect sharePositionOrigin,
  ) async {
    final service = ref.read(shoppingListServiceProvider);
    final text = service.formatAsText(shoppingList);

    await Share.share(
      text,
      subject: '🛒 45min Shopping List',
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
