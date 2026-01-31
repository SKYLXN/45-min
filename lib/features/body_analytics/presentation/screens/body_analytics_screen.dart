import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';

// Import the actual analytics dashboard screen
import 'analytics_dashboard_screen.dart';

/// Wrapper class for routing - delegates to the real analytics dashboard
class BodyAnalyticsScreen extends StatelessWidget {
  const BodyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Return the actual analytics dashboard implementation
    return const AnalyticsDashboardScreen();
  }
}
