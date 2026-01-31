import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_constants.dart';
import '../../../../core/models/body_metrics.dart';
import '../../../../core/models/segmental_analysis.dart';

/// Repository for body analytics data (metrics and segmental analysis)
class BodyAnalyticsRepository {
  final DatabaseHelper _dbHelper;

  BodyAnalyticsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ============================================================================
  // Body Metrics Operations
  // ============================================================================

  /// Save body metrics to database
  Future<void> saveBodyMetrics(BodyMetrics metrics) async {
    await _dbHelper.insert(
      DatabaseConstants.tableBodyMetrics,
      metrics.toJson(),
    );
  }

  /// Update existing body metrics in database
  Future<void> updateBodyMetrics(BodyMetrics metrics) async {
    await _dbHelper.update(
      DatabaseConstants.tableBodyMetrics,
      metrics.toJson(),
      '${DatabaseConstants.colId} = ?',
      [metrics.id],
    );
  }

  /// Get latest body metrics for user
  Future<BodyMetrics?> getLatestMetrics({String userId = 'default'}) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableBodyMetrics,
      where: '${DatabaseConstants.colUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseConstants.colTimestamp} DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return BodyMetrics.fromJson(results.first);
  }

  /// Get body metrics by ID
  Future<BodyMetrics?> getMetricsById(String id) async {
    final result = await _dbHelper.getById(
      DatabaseConstants.tableBodyMetrics,
      id,
    );
    
    if (result == null) return null;
    return BodyMetrics.fromJson(result);
  }

  /// Get metrics history within date range
  Future<List<BodyMetrics>> getMetricsHistory({
    String userId = 'default',
    required DateTime start,
    required DateTime end,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableBodyMetrics,
      where: '''
        ${DatabaseConstants.colUserId} = ? AND 
        ${DatabaseConstants.colTimestamp} >= ? AND 
        ${DatabaseConstants.colTimestamp} <= ?
      ''',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: '${DatabaseConstants.colTimestamp} ASC',
    );

    return results.map((json) => BodyMetrics.fromJson(json)).toList();
  }

  /// Get metrics by specific date
  Future<BodyMetrics?> getMetricsByDate(DateTime date, {String userId = 'default'}) async {
    // Normalize to start of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final results = await _dbHelper.query(
      DatabaseConstants.tableBodyMetrics,
      where: '''
        ${DatabaseConstants.colUserId} = ? AND 
        ${DatabaseConstants.colTimestamp} >= ? AND 
        ${DatabaseConstants.colTimestamp} < ?
      ''',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: '${DatabaseConstants.colTimestamp} DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return BodyMetrics.fromJson(results.first);
  }

  /// Get all metrics for user (for charts)
  Future<List<BodyMetrics>> getAllMetrics({String userId = 'default'}) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableBodyMetrics,
      where: '${DatabaseConstants.colUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseConstants.colTimestamp} ASC',
    );

    return results.map((json) => BodyMetrics.fromJson(json)).toList();
  }

  /// Get progression data for specific metric (weight, body_fat, etc.)
  Future<List<Map<String, dynamic>>> getProgressionData({
    String userId = 'default',
    required String metricField,
    int? limit,
  }) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableBodyMetrics,
      where: '${DatabaseConstants.colUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseConstants.colTimestamp} ASC',
      limit: limit,
    );

    return results.map((row) {
      return {
        'timestamp': row[DatabaseConstants.colTimestamp],
        'value': row[metricField],
      };
    }).toList();
  }

  /// Delete body metrics by ID
  Future<void> deleteMetrics(String id) async {
    await _dbHelper.deleteById(DatabaseConstants.tableBodyMetrics, id);
  }

  /// Get metrics count for user
  Future<int> getMetricsCount({String userId = 'default'}) async {
    final count = await _dbHelper.getCount(
      DatabaseConstants.tableBodyMetrics,
      where: '${DatabaseConstants.colUserId} = ?',
      whereArgs: [userId],
    );
    return count ?? 0;
  }

  // ============================================================================
  // Segmental Analysis Operations
  // ============================================================================

  /// Save segmental analysis
  Future<void> saveSegmentalAnalysis(SegmentalAnalysis analysis) async {
    await _dbHelper.insert(
      DatabaseConstants.tableSegmentalAnalysis,
      analysis.toJson(),
    );
  }

  /// Get segmental analysis by body metrics ID
  Future<SegmentalAnalysis?> getSegmentalAnalysisByMetricsId(
    String bodyMetricsId,
  ) async {
    final results = await _dbHelper.query(
      DatabaseConstants.tableSegmentalAnalysis,
      where: '${DatabaseConstants.colBodyMetricsId} = ?',
      whereArgs: [bodyMetricsId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return SegmentalAnalysis.fromJson(results.first);
  }

  /// Get latest segmental analysis (with body metrics ID)
  Future<SegmentalAnalysis?> getLatestSegmentalAnalysis({
    String userId = 'default',
  }) async {
    // Join with body_metrics to filter by user
    final sql = '''
      SELECT sa.* 
      FROM ${DatabaseConstants.tableSegmentalAnalysis} sa
      INNER JOIN ${DatabaseConstants.tableBodyMetrics} bm 
        ON sa.${DatabaseConstants.colBodyMetricsId} = bm.${DatabaseConstants.colId}
      WHERE bm.${DatabaseConstants.colUserId} = ?
      ORDER BY sa.${DatabaseConstants.colTimestamp} DESC
      LIMIT 1
    ''';

    final results = await _dbHelper.rawQuery(sql, [userId]);
    if (results.isEmpty) return null;
    return SegmentalAnalysis.fromJson(results.first);
  }

  /// Get segmental analysis history
  Future<List<SegmentalAnalysis>> getSegmentalAnalysisHistory({
    String userId = 'default',
    required DateTime start,
    required DateTime end,
  }) async {
    final sql = '''
      SELECT sa.* 
      FROM ${DatabaseConstants.tableSegmentalAnalysis} sa
      INNER JOIN ${DatabaseConstants.tableBodyMetrics} bm 
        ON sa.${DatabaseConstants.colBodyMetricsId} = bm.${DatabaseConstants.colId}
      WHERE bm.${DatabaseConstants.colUserId} = ? 
        AND sa.${DatabaseConstants.colTimestamp} >= ?
        AND sa.${DatabaseConstants.colTimestamp} <= ?
      ORDER BY sa.${DatabaseConstants.colTimestamp} ASC
    ''';

    final results = await _dbHelper.rawQuery(
      sql,
      [userId, start.toIso8601String(), end.toIso8601String()],
    );

    return results.map((json) => SegmentalAnalysis.fromJson(json)).toList();
  }

  /// Delete segmental analysis by ID
  Future<void> deleteSegmentalAnalysis(String id) async {
    await _dbHelper.deleteById(DatabaseConstants.tableSegmentalAnalysis, id);
  }

  // ============================================================================
  // Combined Operations
  // ============================================================================

  /// Save body metrics with segmental analysis in transaction
  Future<void> saveBodyMetricsWithSegmental({
    required BodyMetrics metrics,
    required SegmentalAnalysis segmental,
  }) async {
    await _dbHelper.transaction((txn) async {
      await txn.insert(
        DatabaseConstants.tableBodyMetrics,
        metrics.toJson(),
      );
      await txn.insert(
        DatabaseConstants.tableSegmentalAnalysis,
        segmental.toJson(),
      );
    });
  }

  /// Get combined latest data (metrics + segmental)
  Future<Map<String, dynamic>?> getLatestCombinedData({
    String userId = 'default',
  }) async {
    final metrics = await getLatestMetrics(userId: userId);
    if (metrics == null) return null;

    final segmental = await getSegmentalAnalysisByMetricsId(metrics.id);

    return {
      'metrics': metrics,
      'segmental': segmental,
    };
  }

  // ============================================================================
  // Statistics & Analytics
  // ============================================================================

  /// Calculate average metric over period
  Future<double?> getAverageMetric({
    String userId = 'default',
    required String metricField,
    required DateTime start,
    required DateTime end,
  }) async {
    final sql = '''
      SELECT AVG($metricField) as average
      FROM ${DatabaseConstants.tableBodyMetrics}
      WHERE ${DatabaseConstants.colUserId} = ?
        AND ${DatabaseConstants.colTimestamp} >= ?
        AND ${DatabaseConstants.colTimestamp} <= ?
    ''';

    final results = await _dbHelper.rawQuery(
      sql,
      [userId, start.toIso8601String(), end.toIso8601String()],
    );

    if (results.isEmpty || results.first['average'] == null) return null;
    return (results.first['average'] as num).toDouble();
  }

  /// Get metric change percentage (latest vs oldest in period)
  Future<double?> getMetricChangePercent({
    String userId = 'default',
    required String metricField,
    required DateTime start,
    required DateTime end,
  }) async {
    final metrics = await getMetricsHistory(
      userId: userId,
      start: start,
      end: end,
    );

    if (metrics.length < 2) return null;

    final first = metrics.first.toJson()[metricField] as num;
    final last = metrics.last.toJson()[metricField] as num;

    if (first == 0) return null;
    return ((last - first) / first) * 100;
  }
}

// Provider for BodyAnalyticsRepository
final bodyAnalyticsRepositoryProvider = Provider<BodyAnalyticsRepository>((ref) {
  return BodyAnalyticsRepository();
});
