import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../data/services/firebase_exercise_service.dart';

/// Smart video player that fetches and streams exercise videos from Firebase
class SmartVideoPlayer extends StatefulWidget {
  final String? firebaseExerciseId; // Document ID (preferred)
  final String? firebaseExerciseName; // Fallback to name lookup
  final String gender;
  final String angle;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartVideoPlayer({
    super.key,
    this.firebaseExerciseId,
    this.firebaseExerciseName,
    this.gender = 'male',
    this.angle = 'front',
    this.placeholder,
    this.errorWidget,
  }) : assert(firebaseExerciseId != null || firebaseExerciseName != null,
            'Must provide either firebaseExerciseId or firebaseExerciseName');

  @override
  State<SmartVideoPlayer> createState() => _SmartVideoPlayerState();
}

class _SmartVideoPlayerState extends State<SmartVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  final _firebaseService = FirebaseExerciseService();

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Determine lookup method
      final idOrName = widget.firebaseExerciseId ?? widget.firebaseExerciseName!;
      final useId = widget.firebaseExerciseId != null;
      
      print('🎥 SmartVideoPlayer loading video:');
      print('   ID: ${widget.firebaseExerciseId}');
      print('   Name: ${widget.firebaseExerciseName}');
      print('   Using ID lookup: $useId');
      
      // Fetch video URL from Firebase
      final url = await _firebaseService.getExerciseVideoUrl(
        idOrName,
        useId: useId,
        gender: widget.gender,
        angle: widget.angle,
      );

      print('   Fetched URL: $url');

      if (url == null) {
        print('   ❌ No URL returned from Firebase');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Video not found';
        });
        return;
      }

      // Initialize video player
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();

      // Initialize Chewie (video player UI)
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        aspectRatio: 16 / 9,
        showControls: true,
        placeholder: widget.placeholder ??
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        errorBuilder: (context, errorMessage) {
          return widget.errorWidget ??
              Container(
                color: Colors.grey[900],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_off,
                      color: Colors.white54,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video unavailable',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading video: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load video';
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            height: 200,
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    if (_errorMessage != null || _chewieController == null) {
      return widget.errorWidget ??
          Container(
            height: 200,
            color: Colors.grey[900],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.videocam_off,
                  color: Colors.white54,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Video not available',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}

/// Compact version for lists
class SmartVideoThumbnail extends StatefulWidget {
  final String firebaseExerciseName;
  final String gender;
  final String angle;
  final double height;

  const SmartVideoThumbnail({
    super.key,
    required this.firebaseExerciseName,
    this.gender = 'male',
    this.angle = 'front',
    this.height = 120,
  });

  @override
  State<SmartVideoThumbnail> createState() => _SmartVideoThumbnailState();
}

class _SmartVideoThumbnailState extends State<SmartVideoThumbnail> {
  String? _thumbnailUrl;
  bool _isLoading = true;
  final _firebaseService = FirebaseExerciseService();

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final url = await _firebaseService.getExerciseVideoUrl(
        widget.firebaseExerciseName,
        gender: widget.gender,
        angle: widget.angle,
      );

      if (mounted) {
        setState(() {
          _thumbnailUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _thumbnailUrl != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Video thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _thumbnailUrl!,
                        height: widget.height,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallback();
                        },
                      ),
                    ),
                    // Play icon overlay
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                )
              : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center,
            color: Colors.white54,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            widget.firebaseExerciseName,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
