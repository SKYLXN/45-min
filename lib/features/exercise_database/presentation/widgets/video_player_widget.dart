import 'package:flutter/material.dart';

/// Video/GIF player widget for exercise demonstrations
class VideoPlayerWidget extends StatelessWidget {
  final String? videoUrl;
  final String? gifUrl;
  final String exerciseName;

  const VideoPlayerWidget({
    super.key,
    this.videoUrl,
    this.gifUrl,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0E1A),
            Color(0xFF151B2D),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video/GIF content
          if (gifUrl != null)
            Image.asset(
              gifUrl!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),

          // Play overlay (for videos)
          if (videoUrl != null)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 48,
                  color: Color(0xFF0A0E1A),
                ),
              ),
            ),

          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF151B2D).withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: const Color(0xFF00FF88).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            exerciseName,
            style: TextStyle(
              color: const Color(0xFFB0B8C8).withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Video demonstration coming soon',
            style: TextStyle(
              color: const Color(0xFFB0B8C8).withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
