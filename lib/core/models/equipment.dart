import 'package:equatable/equatable.dart';

/// Equipment types available to the user
enum EquipmentType {
  dumbbells,
  bench,
  pullupBar,
  bodyweight,
  resistanceBands,
  kettlebell,
  other;

  String get displayName {
    switch (this) {
      case EquipmentType.dumbbells:
        return 'Dumbbells';
      case EquipmentType.bench:
        return 'Bench';
      case EquipmentType.pullupBar:
        return 'Pull-up Bar';
      case EquipmentType.bodyweight:
        return 'Bodyweight';
      case EquipmentType.resistanceBands:
        return 'Resistance Bands';
      case EquipmentType.kettlebell:
        return 'Kettlebell';
      case EquipmentType.other:
        return 'Other';
    }
  }
}

/// User's available equipment with specifications
class Equipment extends Equatable {
  final String id;
  final EquipmentType type;
  final double? minWeight; // kg (for adjustable weights)
  final double? maxWeight; // kg
  final bool isAvailable;
  final String? notes;

  const Equipment({
    required this.id,
    required this.type,
    this.minWeight,
    this.maxWeight,
    this.isAvailable = true,
    this.notes,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      type: EquipmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EquipmentType.other,
      ),
      minWeight: json['min_weight'] != null
          ? (json['min_weight'] as num).toDouble()
          : null,
      maxWeight: json['max_weight'] != null
          ? (json['max_weight'] as num).toDouble()
          : null,
      isAvailable: json['is_available'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'min_weight': minWeight,
      'max_weight': maxWeight,
      'is_available': isAvailable,
      'notes': notes,
    };
  }

  Equipment copyWith({
    String? id,
    EquipmentType? type,
    double? minWeight,
    double? maxWeight,
    bool? isAvailable,
    String? notes,
  }) {
    return Equipment(
      id: id ?? this.id,
      type: type ?? this.type,
      minWeight: minWeight ?? this.minWeight,
      maxWeight: maxWeight ?? this.maxWeight,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
    );
  }

  /// Check if equipment supports a specific weight
  bool supportsWeight(double weight) {
    if (minWeight == null || maxWeight == null) return true;
    return weight >= minWeight! && weight <= maxWeight!;
  }

  /// Get weight range display string
  String get weightRangeDisplay {
    if (minWeight == null || maxWeight == null) return '';
    return '${minWeight}kg - ${maxWeight}kg';
  }

  @override
  List<Object?> get props => [
        id,
        type,
        minWeight,
        maxWeight,
        isAvailable,
        notes,
      ];
}
