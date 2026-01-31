import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/body_analytics_repository.dart';
import '../../providers/body_analytics_provider.dart';
import '../../../../core/models/body_metrics.dart';

/// Progress chart screen for viewing metric trends
class ProgressChartScreen extends ConsumerStatefulWidget {
  final String metricName;
  final String metricDisplayName;
  final String unit;
  final Color color;
  final IconData icon;

  const ProgressChartScreen({
    super.key,
    required this.metricName,
    required this.metricDisplayName,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  ConsumerState<ProgressChartScreen> createState() => _ProgressChartScreenState();
}

class _ProgressChartScreenState extends ConsumerState<ProgressChartScreen> {
  String _selectedPeriod = '1 week';
  List<BodyMetrics> _metrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final repository = ref.read(bodyAnalyticsRepositoryProvider);
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedPeriod) {
        case '1 week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '1 month':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '3 months':
          startDate = now.subtract(const Duration(days: 90));
          break;
        case '6 months':
          startDate = now.subtract(const Duration(days: 180));
          break;
        case '1 year':
          startDate = now.subtract(const Duration(days: 365));
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }
      
      final metrics = await repository.getMetricsHistory(
        start: startDate,
        end: now,
      );
      
      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _getMetricValue(BodyMetrics metric) {
    switch (widget.metricName.toLowerCase()) {
      case 'weight':
        return metric.weight;
      case 'bodyfat':
        return metric.bodyFat;
      case 'skeletalmuscle':
        return metric.skeletalMuscle;
      case 'bmi':
        return metric.bmi;
      case 'bmr':
        return metric.bmr.toDouble();
      case 'leanbodymass':
      case 'lean_body_mass':
        return metric.leanBodyMass ?? metric.calculatedLeanBodyMass;
      case 'waistcircumference':
      case 'waist_circumference':
        return metric.waistCircumference ?? 0.0;
      case 'height':
        return metric.height ?? 0.0;
      default:
        return 0;
    }
  }

  List<FlSpot> _createSpots() {
    if (_metrics.isEmpty) return [];
    
    // Sort by date (oldest first for chart)
    final sortedMetrics = List<BodyMetrics>.from(_metrics)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return sortedMetrics.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = _getMetricValue(entry.value);
      return FlSpot(index, value);
    }).toList();
  }

  double get _minY {
    if (_metrics.isEmpty) return 0;
    final values = _metrics.map(_getMetricValue).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    return min * 0.95; // 5% padding below
  }

  double get _maxY {
    if (_metrics.isEmpty) return 100;
    final values = _metrics.map(_getMetricValue).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return max * 1.05; // 5% padding above
  }

  String _formatValue(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = _metrics.isNotEmpty ? _getMetricValue(_metrics.first) : 0.0;
    final oldestValue = _metrics.length > 1 ? _getMetricValue(_metrics.last) : currentValue;
    final change = oldestValue != 0 ? ((currentValue - oldestValue) / oldestValue) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.metricDisplayName} Progress',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today, color: AppColors.textPrimary),
            color: AppColors.cardBackground,
            onSelected: (period) {
              setState(() => _selectedPeriod = period);
              _loadData();
            },
            itemBuilder: (context) => [
              '1 week',
              '1 month',
              '3 months', 
              '6 months',
              '1 year',
            ].map((period) => PopupMenuItem(
              value: period,
              child: Text(
                period,
                style: TextStyle(
                  color: _selectedPeriod == period 
                    ? AppColors.primaryGreen 
                    : AppColors.textPrimary,
                  fontWeight: _selectedPeriod == period 
                    ? FontWeight.bold 
                    : FontWeight.normal,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current value card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.15),
                          widget.color.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.color.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current ${widget.metricDisplayName}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatValue(currentValue),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                widget.unit,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_metrics.length > 1) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 20,
                                color: change > 0 ? AppColors.success : AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${change.abs().toStringAsFixed(1)}% over $_selectedPeriod',
                                style: TextStyle(
                                  color: change > 0 ? AppColors.success : AppColors.error,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Chart
                  Text(
                    'Trend over $_selectedPeriod',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_metrics.isEmpty)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.show_chart,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No data available for this period',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (_maxY - _minY) > 0 ? (_maxY - _minY) / 4 : 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: AppColors.borderColor,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval: (_maxY - _minY) > 0 ? (_maxY - _minY) / 4 : 1,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    _formatValue(value),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: (_metrics.length > 1) ? (_metrics.length - 1) / 3 : 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < _metrics.length) {
                                    final metric = _metrics.reversed.toList()[index];
                                    return Text(
                                      DateFormat('MMM d').format(metric.timestamp),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          minY: _minY,
                          maxY: _maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _createSpots(),
                              isCurved: true,
                              gradient: LinearGradient(colors: [
                                widget.color.withOpacity(0.8),
                                widget.color,
                              ]),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) =>
                                    FlDotCirclePainter(
                                  radius: 4,
                                  color: widget.color,
                                  strokeWidth: 2,
                                  strokeColor: AppColors.cardBackground,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    widget.color.withOpacity(0.2),
                                    widget.color.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}