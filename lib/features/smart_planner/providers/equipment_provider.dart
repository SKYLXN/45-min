import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/models/equipment.dart';

// ============================================================================
// Equipment State
// ============================================================================

class EquipmentState {
  final List<Equipment> userEquipment;
  final bool isLoading;
  final String? error;

  const EquipmentState({
    this.userEquipment = const [],
    this.isLoading = false,
    this.error,
  });

  EquipmentState copyWith({
    List<Equipment>? userEquipment,
    bool? isLoading,
    String? error,
  }) {
    return EquipmentState(
      userEquipment: userEquipment ?? this.userEquipment,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================================================
// Equipment Notifier
// ============================================================================

class EquipmentNotifier extends StateNotifier<EquipmentState> {
  EquipmentNotifier() : super(const EquipmentState());

  static const String _storageKey = 'user_equipment';

  /// Load user's equipment from storage
  Future<void> loadEquipment() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final equipmentJson = prefs.getString(_storageKey);

      if (equipmentJson != null) {
        final List<dynamic> jsonList = jsonDecode(equipmentJson);
        final equipment = jsonList
            .map((json) => Equipment.fromJson(json as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          userEquipment: equipment,
          isLoading: false,
        );
      } else {
        // No equipment saved - start with defaults
        state = state.copyWith(
          userEquipment: _getDefaultEquipment(),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load equipment: $e',
      );
    }
  }

  /// Save user's equipment to storage
  Future<void> saveEquipment(List<Equipment> equipment) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = equipment.map((e) => e.toJson()).toList();
      final equipmentJson = jsonEncode(jsonList);
      await prefs.setString(_storageKey, equipmentJson);

      state = state.copyWith(
        userEquipment: equipment,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save equipment: $e',
      );
    }
  }

  /// Add equipment to user's list
  Future<void> addEquipment(Equipment equipment) async {
    final updated = List<Equipment>.from(state.userEquipment)..add(equipment);
    await saveEquipment(updated);
  }

  /// Remove equipment from user's list
  Future<void> removeEquipment(String equipmentId) async {
    final updated = state.userEquipment
        .where((e) => e.id != equipmentId)
        .toList();
    await saveEquipment(updated);
  }

  /// Update equipment details
  Future<void> updateEquipment(Equipment equipment) async {
    final updated = state.userEquipment.map((e) {
      return e.id == equipment.id ? equipment : e;
    }).toList();
    await saveEquipment(updated);
  }

  /// Toggle equipment availability
  Future<void> toggleEquipment(EquipmentType equipmentType) async {
    final equipment = state.userEquipment.firstWhere(
      (e) => e.type == equipmentType,
      orElse: () => Equipment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: equipmentType,
        isAvailable: false,
      ),
    );

    if (state.userEquipment.any((e) => e.type == equipmentType)) {
      // Update existing
      await updateEquipment(equipment.copyWith(
        isAvailable: !equipment.isAvailable,
      ));
    } else {
      // Add new
      await addEquipment(Equipment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: equipmentType,
        isAvailable: true,
      ));
    }
  }

  /// Get default equipment (bodyweight always available)
  List<Equipment> _getDefaultEquipment() {
    return [
      Equipment(
        id: 'default_bodyweight',
        type: EquipmentType.bodyweight,
        isAvailable: true,
      ),
    ];
  }

  /// Check if equipment is available
  bool hasEquipment(EquipmentType equipmentType) {
    return state.userEquipment.any(
      (e) => e.type == equipmentType && e.isAvailable,
    );
  }

  /// Get available equipment types
  List<EquipmentType> getAvailableTypes() {
    return state.userEquipment
        .where((e) => e.isAvailable)
        .map((e) => e.type)
        .toList();
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Equipment state provider
final equipmentProvider =
    StateNotifierProvider<EquipmentNotifier, EquipmentState>(
  (ref) => EquipmentNotifier()..loadEquipment(),
);

/// Available equipment types provider
final availableEquipmentProvider = Provider<List<EquipmentType>>((ref) {
  final state = ref.watch(equipmentProvider);
  return state.userEquipment
      .where((e) => e.isAvailable)
      .map((e) => e.type)
      .toList();
});

/// Equipment count provider
final equipmentCountProvider = Provider<int>((ref) {
  final state = ref.watch(equipmentProvider);
  return state.userEquipment.where((e) => e.isAvailable).length;
});

/// Check if specific equipment is available
final hasEquipmentProvider = Provider.family<bool, EquipmentType>((ref, type) {
  final state = ref.watch(equipmentProvider);
  return state.userEquipment.any((e) => e.type == type && e.isAvailable);
});

// ============================================================================
// Common Equipment Types
// ============================================================================

class EquipmentTypes {
  static const bodyweight = 'bodyweight';
  static const dumbbells = 'Dumbbells';
  static const bench = 'Bench';
  static const pullUpBar = 'Pull-up Bar';
  static const resistanceBands = 'Resistance Bands';
  static const kettlebell = 'Kettlebell';
  static const barbell = 'Barbell';
  static const cables = 'Cable Machine';
  static const smith = 'Smith Machine';
  static const ezBar = 'EZ Bar';

  static List<String> get all => [
        bodyweight,
        dumbbells,
        bench,
        pullUpBar,
        resistanceBands,
        kettlebell,
        barbell,
        cables,
        smith,
        ezBar,
      ];

  static String getDisplayName(String type) {
    return type == bodyweight ? 'Bodyweight Only' : type;
  }

  static String getIcon(String type) {
    switch (type) {
      case bodyweight:
        return '🏃';
      case dumbbells:
        return '🏋️';
      case bench:
        return '🛏️';
      case pullUpBar:
        return '🤸';
      case resistanceBands:
        return '🎗️';
      case kettlebell:
        return '⚖️';
      case barbell:
        return '💪';
      case cables:
        return '🎰';
      case smith:
        return '🏗️';
      case ezBar:
        return '🎯';
      default:
        return '⚡';
    }
  }
}
