import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/data_persistence_service.dart';
import '../../../core/constants/app_colors.dart';

/// Settings screen for data backup and persistence management
class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  bool _isCheckingIntegrity = false;
  DataIntegrityReport? _lastIntegrityReport;

  @override
  void initState() {
    super.initState();
    // Perform initial data integrity check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performIntegrityCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Data Management'),
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataIntegritySection(),
            const SizedBox(height: 24),
            _buildPersistenceInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataIntegritySection() {
    return Card(
      color: AppColors.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Integrity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_lastIntegrityReport != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lastIntegrityReport!.isHealthy 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _lastIntegrityReport!.isHealthy 
                        ? AppColors.success 
                        : AppColors.error,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _lastIntegrityReport!.isHealthy 
                              ? Icons.check_circle 
                              : Icons.warning,
                          color: _lastIntegrityReport!.isHealthy 
                              ? AppColors.success 
                              : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _lastIntegrityReport!.isHealthy 
                              ? 'Data integrity is healthy'
                              : 'Data integrity issues found',
                          style: TextStyle(
                            color: _lastIntegrityReport!.isHealthy 
                                ? AppColors.success 
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastIntegrityReport!.summary,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCheckingIntegrity ? null : _performIntegrityCheck,
                icon: _isCheckingIntegrity 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.health_and_safety),
                label: Text(_isCheckingIntegrity 
                    ? 'Checking...' 
                    : 'Check Data Integrity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      color: AppColors.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Backup',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Export your training data, food logs, meal plans, and preferences to a backup file.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportData,
                icon: _isExporting 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup),
                label: Text(_isExporting ? 'Exporting...' : 'Create Backup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreSection() {
    return Card(
      color: AppColors.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Restore',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Import data from a previously created backup file. This will merge with existing data.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _importData,
                icon: _isImporting 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                label: Text(_isImporting ? 'Importing...' : 'Restore from Backup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCleanupSection() {
    return Card(
      color: AppColors.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Cleanup',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Remove old data to free up storage space. This will delete records older than 1 year.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cleanupOldData,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Clean Up Old Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersistenceInfoSection() {
    return Card(
      color: AppColors.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Persistence Info',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Auto-backup', 'Every 5 minutes', Icons.schedule),
            _buildInfoRow('Database', 'SQLite (Local)', Icons.storage),
            _buildInfoRow('Data retention', '2 years default', Icons.history),
            _buildInfoRow('Encryption', 'None (Local only)', Icons.security),
            const SizedBox(height: 16),
            const Text(
              'All your data is stored locally on your device and never sent to external servers.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _performIntegrityCheck() async {
    setState(() {
      _isCheckingIntegrity = true;
    });

    try {
      final persistenceService = ref.read(dataPersistenceServiceProvider);
      final report = await persistenceService.verifyDataIntegrity();
      
      setState(() {
        _lastIntegrityReport = report;
        _isCheckingIntegrity = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(report.isHealthy 
                ? '✅ Data integrity check passed'
                : '⚠️ Data integrity issues found'),
            backgroundColor: report.isHealthy ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCheckingIntegrity = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Data integrity check failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}