import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

/// Service for fetching exercise data from Firebase Storage
class FirebaseExerciseService {
  final FirebaseFirestore _firestore;

  FirebaseExerciseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // VIDEO OPERATIONS
  // ============================================================================

  /// Get video URL from Firebase by exercise ID or name
  /// 
  /// [exerciseId] - Document ID in Firestore (preferred, from mapped_raw.id)
  /// [exerciseName] - Exact name as stored in Firestore (fallback)
  /// [gender] - 'male' or 'female' (default: 'male')
  /// [angle] - 'front' or 'side' (default: 'front')
  Future<String?> getExerciseVideoUrl(
    String exerciseIdOrName, {
    bool useId = false,
    String gender = 'male',
    String angle = 'front',
  }) async {
    print('🔥 Firebase service called:');
    print('   Lookup: $exerciseIdOrName');
    print('   Using ID: $useId');
    
    try {
      DocumentSnapshot? doc;
      
      if (useId) {
        print('   📍 Direct doc lookup: exercises/$exerciseIdOrName');
        // Direct document lookup by ID (fastest)
        doc = await _firestore
            .collection('exercises')
            .doc(exerciseIdOrName)
            .get();
      } else {
        // Query by name (slower, but backwards compatible)
        final querySnapshot = await _firestore
            .collection('exercises')
            .where('name', isEqualTo: exerciseIdOrName)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          doc = querySnapshot.docs.first;
        }
      }

      if (doc == null || !doc.exists) {
        print('⚠️ Exercise not found in Firebase: $exerciseIdOrName');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;
      
      final videos = data['videos'] as List<dynamic>?;

      if (videos == null || videos.isEmpty) {
        print('⚠️ No videos found for: $exerciseIdOrName');
        return null;
      }

      // Find matching video
      final matchingVideo = videos.firstWhere(
        (v) => v['gender'] == gender && v['angle'] == angle,
        orElse: () => videos.first, // Fallback to first video
      );

      return matchingVideo['url'] as String;
    } catch (e) {
      print('❌ Firebase error fetching video: $e');
      return null;
    }
  }

  /// Get all videos for an exercise
  Future<List<FirebaseVideo>> getExerciseVideos(String exerciseName) async {
    try {
      final querySnapshot = await _firestore
          .collection('exercises')
          .where('name', isEqualTo: exerciseName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      final data = querySnapshot.docs.first.data();
      final videos = data['videos'] as List<dynamic>?;

      if (videos == null) return [];

      return videos
          .map((v) => FirebaseVideo.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Firebase error fetching videos: $e');
      return [];
    }
  }

  // ============================================================================
  // EXERCISE OPERATIONS
  // ============================================================================

  /// Get full exercise data from Firebase
  Future<Map<String, dynamic>?> getExerciseData(String exerciseName) async {
    try {
      final querySnapshot = await _firestore
          .collection('exercises')
          .where('name', isEqualTo: exerciseName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return querySnapshot.docs.first.data();
    } catch (e) {
      print('❌ Firebase error fetching exercise: $e');
      return null;
    }
  }

  /// Search exercises by name (fuzzy search)
  Future<List<Map<String, dynamic>>> searchExercises(String query) async {
    try {
      // Firebase doesn't support full-text search natively
      // We'll do a simple prefix search
      final querySnapshot = await _firestore
          .collection('exercises')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Firebase error searching exercises: $e');
      return [];
    }
  }

  /// Get exercises by category
  Future<List<Map<String, dynamic>>> getExercisesByCategory(
      String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('exercises')
          .where('category', isEqualTo: category)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Firebase error fetching by category: $e');
      return [];
    }
  }

  /// Get exercises by primary muscle
  Future<List<Map<String, dynamic>>> getExercisesByMuscle(
      String muscle) async {
    try {
      final querySnapshot = await _firestore
          .collection('exercises')
          .where('primary_muscles', arrayContains: muscle)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Firebase error fetching by muscle: $e');
      return [];
    }
  }

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  /// Sync all exercises from Firebase (for initial load)
  Future<List<Map<String, dynamic>>> getAllExercises({int limit = 100}) async {
    try {
      final querySnapshot =
          await _firestore.collection('exercises').limit(limit).get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Firebase error fetching all exercises: $e');
      return [];
    }
  }

  /// Get exercise count
  Future<int> getExerciseCount() async {
    try {
      final querySnapshot = await _firestore.collection('exercises').count().get();
      return querySnapshot.count ?? 0;
    } catch (e) {
      print('❌ Firebase error counting exercises: $e');
      return 0;
    }
  }

  // ============================================================================
  // MAPPING HELPERS
  // ============================================================================

  /// Find Firebase exercise name by partial match
  /// Useful for mapping local exercises to Firebase
  Future<String?> findFirebaseName(String localName) async {
    try {
      // Try exact match first
      var querySnapshot = await _firestore
          .collection('exercises')
          .where('name', isEqualTo: localName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['name'] as String;
      }

      // Try case-insensitive search
      // Note: This requires Firestore index and is less efficient
      querySnapshot = await _firestore
          .collection('exercises')
          .get();

      final matches = querySnapshot.docs.where((doc) {
        final name = doc.data()['name'] as String;
        return name.toLowerCase() == localName.toLowerCase();
      });

      if (matches.isNotEmpty) {
        return matches.first.data()['name'] as String;
      }

      return null;
    } catch (e) {
      print('❌ Firebase error finding name: $e');
      return null;
    }
  }

  /// Check if Firebase is available
  Future<bool> isAvailable() async {
    try {
      await _firestore
          .collection('exercises')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print('⚠️ Firebase not available: $e');
      return false;
    }
  }
}
