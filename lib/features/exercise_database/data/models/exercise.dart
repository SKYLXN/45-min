import 'package:equatable/equatable.dart';

/// Firebase video model
class FirebaseVideo extends Equatable {
  final String url;
  final String angle; // 'front', 'side'
  final String gender; // 'male', 'female'
  final String filename;

  const FirebaseVideo({
    required this.url,
    required this.angle,
    required this.gender,
    required this.filename,
  });

  factory FirebaseVideo.fromJson(Map<String, dynamic> json) {
    return FirebaseVideo(
      url: json['url'] as String,
      angle: json['angle'] as String,
      gender: json['gender'] as String,
      filename: json['filename'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'angle': angle,
      'gender': gender,
      'filename': filename,
    };
  }

  @override
  List<Object?> get props => [url, angle, gender, filename];
}

/// Exercise from the database
class Exercise extends Equatable {
  final String id;
  final String name;
  final String muscleGroup; // Primary muscle group
  final List<String> secondaryMuscles;
  final List<String> equipmentRequired;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final String? videoUrl;
  final String? gifUrl;
  final List<String> instructions;
  final String tempo; // e.g., "3-0-1-0" (eccentric-pause-concentric-pause)
  final bool isCompound; // Compound vs isolation exercise
  final List<String> alternatives; // Alternative exercise IDs
  
  // Firebase integration fields
  final String? firebaseName; // Name to search in Firestore
  final String? firebaseId; // Firestore document ID (if synced)
  final List<FirebaseVideo>? firebaseVideos; // Videos from Firebase Storage

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.secondaryMuscles,
    required this.equipmentRequired,
    required this.difficulty,
    this.videoUrl,
    this.gifUrl,
    required this.instructions,
    required this.tempo,
    required this.isCompound,
    required this.alternatives,
    this.firebaseName,
    this.firebaseId,
    this.firebaseVideos,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroup: json['muscle_group'] as String,
      secondaryMuscles: (json['secondary_muscles'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      equipmentRequired: (json['equipment_required'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      difficulty: json['difficulty'] as String,
      videoUrl: json['video_url'] as String?,
      gifUrl: json['gif_url'] as String?,
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tempo: json['tempo'] as String,
      isCompound: json['is_compound'] as bool,
      alternatives: (json['alternatives'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      // Extract Firebase ID from mapping (mapped_raw.id from MuscleWiki)
      firebaseId: json['mapped_raw'] != null 
          ? (json['mapped_raw']['id'] as int?)?.toString()
          : json['firebase_id'] as String?,
      firebaseName: json['firebase_name'] as String? ?? 
          (json['mapped_raw'] != null ? json['mapped_raw']['name'] as String? : null),
      firebaseVideos: json['firebase_videos'] != null
          ? (json['firebase_videos'] as List<dynamic>)
              .map((v) => FirebaseVideo.fromJson(v as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscle_group': muscleGroup,
      'secondary_muscles': secondaryMuscles,
      'equipment_required': equipmentRequired,
      'difficulty': difficulty,
      'video_url': videoUrl,
      'gif_url': gifUrl,
      'instructions': instructions,
      'tempo': tempo,
      'is_compound': isCompound,
      'alternatives': alternatives,
      'firebase_id': firebaseId,
      'firebase_name': firebaseName,
      'firebase_videos': firebaseVideos?.map((v) => v.toJson()).toList(),
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    List<String>? secondaryMuscles,
    List<String>? equipmentRequired,
    String? difficulty,
    String? videoUrl,
    String? gifUrl,
    List<String>? instructions,
    String? tempo,
    bool? isCompound,
    List<String>? alternatives,
    String? firebaseName,
    String? firebaseId,
    List<FirebaseVideo>? firebaseVideos,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipmentRequired: equipmentRequired ?? this.equipmentRequired,
      difficulty: difficulty ?? this.difficulty,
      videoUrl: videoUrl ?? this.videoUrl,
      gifUrl: gifUrl ?? this.gifUrl,
      instructions: instructions ?? this.instructions,
      tempo: tempo ?? this.tempo,
      isCompound: isCompound ?? this.isCompound,
      alternatives: alternatives ?? this.alternatives,
      firebaseName: firebaseName ?? this.firebaseName,
      firebaseId: firebaseId ?? this.firebaseId,
      firebaseVideos: firebaseVideos ?? this.firebaseVideos,
    );
  }

  /// Check if exercise requires specific equipment
  bool requiresEquipment(String equipment) {
    return equipmentRequired.contains(equipment);
  }

  /// Check if exercise is bodyweight only
  bool get isBodyweightOnly {
    return equipmentRequired.isEmpty || 
           (equipmentRequired.length == 1 && equipmentRequired.first == 'bodyweight');
  }

  /// Parse tempo into components (eccentric, pause1, concentric, pause2)
  List<int> get tempoComponents {
    final parts = tempo.split('-');
    if (parts.length == 4) {
      return parts.map((p) => int.tryParse(p) ?? 0).toList();
    }
    return [3, 0, 1, 0]; // Default tempo
  }

  /// Calculate total time under tension per rep (in seconds)
  int get timeUnderTension {
    final components = tempoComponents;
    return components.reduce((a, b) => a + b);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        muscleGroup,
        secondaryMuscles,
        equipmentRequired,
        difficulty,
        videoUrl,
        gifUrl,
        instructions,
        tempo,
        isCompound,
        alternatives,
        firebaseName,
        firebaseId,
        firebaseVideos,
      ];
}
