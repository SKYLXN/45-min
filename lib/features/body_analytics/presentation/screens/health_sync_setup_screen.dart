import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../body_analytics/data/services/health_service.dart';

/// First-time user screen explaining HealthKit benefits
/// and requesting permissions
class HealthSyncSetupScreen extends StatefulWidget {
  const HealthSyncSetupScreen({super.key});

  @override
  State<HealthSyncSetupScreen> createState() => _HealthSyncSetupScreenState();
}

class _HealthSyncSetupScreenState extends State<HealthSyncSetupScreen> {
  bool _isConnecting = false;
  final _healthService = HealthService();
  
  Future<void> _connectToAppleHealth() async {
    setState(() => _isConnecting = true);
    
    try {
      final granted = await _healthService.requestAuthorization();
      
      if (!mounted) return;
      
      if (granted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Successfully connected to Apple Health!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back or to analytics dashboard
        Navigator.of(context).pop(true);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Permission denied. You can enable it later in Settings.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          color: AppColors.textPrimary,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero illustration
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryGreen.withOpacity(0.2),
                      AppColors.primaryGreen.withOpacity(0.05),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 100,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Connect to Apple Health',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Automatically sync your body metrics, sleep quality, and recovery data for smarter workout recommendations',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Benefits list
              _BenefitTile(
                icon: Icons.sync,
                title: 'Zero Friction Data Collection',
                description: 'Step on your smart scale → Data syncs automatically. No manual uploads needed.',
              ),
              const SizedBox(height: 20),
              _BenefitTile(
                icon: Icons.insights,
                title: 'Smart Recovery Tracking',
                description: 'We analyze your sleep, HRV, and body composition to adjust workout intensity.',
              ),
              const SizedBox(height: 20),
              _BenefitTile(
                icon: Icons.trending_up,
                title: 'Progress Visualization',
                description: 'See your weight, body fat %, and muscle gains charted over time.',
              ),
              const SizedBox(height: 20),
              _BenefitTile(
                icon: Icons.fitness_center,
                title: 'Context-Aware Coaching',
                description: 'Poor sleep last night? We\'ll automatically reduce workout intensity.',
              ),
              const SizedBox(height: 48),
              
              // Connect button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _connectToAppleHealth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.backgroundDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.backgroundDark,
                            ),
                          ),
                        )
                      : const Icon(Icons.favorite, size: 24),
                  label: Text(
                    _isConnecting ? 'Connecting...' : 'Connect Apple Health',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Manual entry fallback
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Or enter data manually later',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Privacy note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your health data stays private and is stored securely on your device.',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
