import 'package:equatable/equatable.dart';

/// Segmental body composition analysis (left/right arms, legs, torso)
/// Used to detect muscle imbalances
class SegmentalAnalysis extends Equatable {
  final String id;
  final String bodyMetricsId;
  final double leftArm; // muscle mass in kg
  final double rightArm; // muscle mass in kg
  final double leftLeg; // muscle mass in kg
  final double rightLeg; // muscle mass in kg
  final double torso; // muscle mass in kg
  final DateTime timestamp;

  const SegmentalAnalysis({
    required this.id,
    required this.bodyMetricsId,
    required this.leftArm,
    required this.rightArm,
    required this.leftLeg,
    required this.rightLeg,
    required this.torso,
    required this.timestamp,
  });

  factory SegmentalAnalysis.fromJson(Map<String, dynamic> json) {
    return SegmentalAnalysis(
      id: json['id'] as String,
      bodyMetricsId: json['body_metrics_id'] as String,
      leftArm: (json['left_arm'] as num).toDouble(),
      rightArm: (json['right_arm'] as num).toDouble(),
      leftLeg: (json['left_leg'] as num).toDouble(),
      rightLeg: (json['right_leg'] as num).toDouble(),
      torso: (json['torso'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body_metrics_id': bodyMetricsId,
      'left_arm': leftArm,
      'right_arm': rightArm,
      'left_leg': leftLeg,
      'right_leg': rightLeg,
      'torso': torso,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  SegmentalAnalysis copyWith({
    String? id,
    String? bodyMetricsId,
    double? leftArm,
    double? rightArm,
    double? leftLeg,
    double? rightLeg,
    double? torso,
    DateTime? timestamp,
  }) {
    return SegmentalAnalysis(
      id: id ?? this.id,
      bodyMetricsId: bodyMetricsId ?? this.bodyMetricsId,
      leftArm: leftArm ?? this.leftArm,
      rightArm: rightArm ?? this.rightArm,
      leftLeg: leftLeg ?? this.leftLeg,
      rightLeg: rightLeg ?? this.rightLeg,
      torso: torso ?? this.torso,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Calculate arm imbalance percentage (0-100)
  double get armImbalancePercent {
    final larger = leftArm > rightArm ? leftArm : rightArm;
    final smaller = leftArm < rightArm ? leftArm : rightArm;
    if (larger == 0) return 0;
    return ((larger - smaller) / larger) * 100;
  }

  /// Calculate leg imbalance percentage (0-100)
  double get legImbalancePercent {
    final larger = leftLeg > rightLeg ? leftLeg : rightLeg;
    final smaller = leftLeg < rightLeg ? leftLeg : rightLeg;
    if (larger == 0) return 0;
    return ((larger - smaller) / larger) * 100;
  }

  /// Check if there's significant arm imbalance (>5%)
  bool get hasArmImbalance => armImbalancePercent > 5.0;

  /// Check if there's significant leg imbalance (>5%)
  bool get hasLegImbalance => legImbalancePercent > 5.0;

  /// Total muscle mass across all segments
  double get totalMuscle => leftArm + rightArm + leftLeg + rightLeg + torso;

  @override
  List<Object?> get props => [
        id,
        bodyMetricsId,
        leftArm,
        rightArm,
        leftLeg,
        rightLeg,
        torso,
        timestamp,
      ];
}
