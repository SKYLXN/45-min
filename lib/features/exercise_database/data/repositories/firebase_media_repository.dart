import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

/// Repository for fetching exercise media from Firebase
class FirebaseMediaRepository {
  final FirebaseFirestore _firestore;

  FirebaseMediaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch video URLs for an exercise by its Firebase document ID
  /// 
  /// [firebaseId] - The document ID in Firestore (e.g., "327")
  /// [preferredGender] - "male" or "female" (defaults to "male")
  /// [preferredAngle] - "front" or "side" (defaults to "front")
  /// 
  /// Returns the most suitable video or null if not found
  Future<FirebaseVideo?> getExerciseVideo({
    required String firebaseId,
    String preferredGender = 'male',
    String preferredAngle = 'front',
  }) async {
    try {
      final doc = await _firestore
          .collection('exercises')
          .doc(firebaseId)
          .get();

      if (!doc.exists) {
        print('⚠️  Exercise $firebaseId not found in Firebase');
        return null;
      }

      final data = doc.data();
      if (data == null || !data.containsKey('videos')) {
        print('⚠️  No videos field for exercise $firebaseId');
        return null;
      }

      final videos = (data['videos'] as List<dynamic>)
          .map((v) => FirebaseVideo.fromJson(v as Map<String, dynamic>))
          .toList();

      if (videos.isEmpty) {
        print('⚠️  Videos array empty for exercise $firebaseId');
        return null;
      }

      // Priority 1: Exact match (gender + angle)
      final exactMatch = videos.where(
        (v) => v.gender == preferredGender && v.angle == preferredAngle,
      ).firstOrNull;

      if (exactMatch != null) return exactMatch;

      // Priority 2: Same gender, different angle
      final sameGender = videos.where(
        (v) => v.gender == preferredGender,
      ).firstOrNull;

      if (sameGender != null) return sameGender;

      // Priority 3: Any angle with preferred angle
      final sameAngle = videos.where(
        (v) => v.angle == preferredAngle,
      ).firstOrNull;

      if (sameAngle != null) return sameAngle;

      // Fallback: First available video
      return videos.first;
    } catch (e) {
      print('❌ Error fetching video for $firebaseId: $e');
      return null;
    }
  }

  /// Fetch ALL videos for an exercise (useful for multi-angle view)
  Future<List<FirebaseVideo>> getAllExerciseVideos(String firebaseId) async {
    try {
      final doc = await _firestore
          .collection('exercises')
          .doc(firebaseId)
          .get();

      if (!doc.exists || doc.data() == null) return [];

      final data = doc.data()!;
      if (!data.containsKey('videos')) return [];

      return (data['videos'] as List<dynamic>)
          .map((v) => FirebaseVideo.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching all videos for $firebaseId: $e');
      return [];
    }
  }

  /// Batch fetch videos for multiple exercises (efficient for workout view)
  Future<Map<String, FirebaseVideo?>> batchGetVideos({
    required List<String> firebaseIds,
    String preferredGender = 'male',
    String preferredAngle = 'front',
  }) async {
    final results = <String, FirebaseVideo?>{};

    try {
      // Firestore batching (max 10 queries at a time for performance)
      for (var i = 0; i < firebaseIds.length; i += 10) {
        final batch = firebaseIds.skip(i).take(10).toList();
        
        final futures = batch.map((id) => getExerciseVideo(
          firebaseId: id,
          preferredGender: preferredGender,
          preferredAngle: preferredAngle,
        ));

        final videos = await Future.wait(futures);
        
        for (var j = 0; j < batch.length; j++) {
          results[batch[j]] = videos[j];
        }
      }
    } catch (e) {
      print('❌ Batch video fetch error: $e');
    }

    return results;
  }
}
