import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/theme_controller.dart';

enum VideoAspectRatio { portrait9x16, landscape16x9, square }

extension VideoAspectRatioExtension on VideoAspectRatio {
  double get value {
    switch (this) {
      case VideoAspectRatio.portrait9x16:
        return 9 / 16;
      case VideoAspectRatio.landscape16x9:
        return 16 / 9;
      case VideoAspectRatio.square:
        return 1.0;
    }
  }

  double get displayHeight {
    switch (this) {
      case VideoAspectRatio.portrait9x16:
        return 300;
      case VideoAspectRatio.landscape16x9:
        return 200;
      case VideoAspectRatio.square:
        return 250;
    }
  }
  double get displayWidth {
    switch (this) {
      case VideoAspectRatio.portrait9x16:
        return 170;
      case VideoAspectRatio.landscape16x9:
        return 320;
      case VideoAspectRatio.square:
        return 250;
    }
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final double? height;
  final bool autoPlay;
  final bool showControls;
  final VideoAspectRatio? aspectRatio;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.height,
    this.autoPlay = true,
    this.showControls = true,
    this.aspectRatio,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  late VideoAspectRatio _aspectRatio;

  @override
  void initState() {
    super.initState();
    _aspectRatio = widget.aspectRatio ?? VideoAspectRatio.portrait9x16;
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _aspectRatio = _getAspectRatioFromController();
        });
      }

      if (widget.autoPlay) {
        _controller.play();
        _controller.setLooping(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  VideoAspectRatio _getAspectRatioFromController() {
    final aspectRatio = _controller.value.aspectRatio;
    if (aspectRatio < 0.8) return VideoAspectRatio.portrait9x16;
    if (aspectRatio > 1.2) return VideoAspectRatio.landscape16x9;
    return VideoAspectRatio.square;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: _aspectRatio.displayHeight,
        color: AppColors.softStone,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
              SizedBox(height: AppSpacing.sm),
              Text('Failed to load video', style: TextStyle(color: AppColors.mutedSlate)),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: widget.height ?? _aspectRatio.displayHeight,
        color: AppColors.ink,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.canvasWhite),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = widget.height ?? constraints.maxHeight;
        
        double videoWidth;
        double videoHeight;
        
        if (_aspectRatio.value > maxWidth / maxHeight) {
          videoWidth = maxWidth;
          videoHeight = maxWidth / _aspectRatio.value;
        } else {
          videoHeight = maxHeight;
          videoWidth = maxHeight * _aspectRatio.value;
        }
        
        return Container(
          color: AppColors.ink,
          child: Center(
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  if (widget.showControls) _VideoControls(controller: _controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onVideoProgress);
  }

  void _onVideoProgress() {
    if (mounted && _showControls) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final position = value.position;
    final duration = value.duration;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  if (value.isPlaying) {
                    widget.controller.pause();
                  } else {
                    widget.controller.play();
                  }
                  setState(() {});
                },
                icon: Icon(
                  value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppColors.canvasWhite,
                  size: 56,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: AppColors.canvasWhite, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: position.inMilliseconds.toDouble(),
                        min: 0,
                        max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                        onChanged: (val) {
                          widget.controller.seekTo(Duration(milliseconds: val.toInt()));
                        },
                        activeColor: AppColors.canvasWhite,
                        inactiveColor: AppColors.canvasWhite.withValues(alpha: 0.3),
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: AppColors.canvasWhite, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final double height;
  final double? width;
  final VoidCallback? onTap;
  final VideoAspectRatio aspectRatio;

  const VideoThumbnail({
    super.key,
    required this.videoUrl,
    this.height = 120,
    this.width,
    this.onTap,
    this.aspectRatio = VideoAspectRatio.portrait9x16,
  });

  String _getCloudinaryThumbnailUrl(String videoUrl) {
    if (videoUrl.contains('cloudinary.com')) {
      try {
        final parts = videoUrl.split('/upload/');
        if (parts.length == 2) {
          final transforms = 'so_0,vc_auto';
          return '${parts[0]}/upload/$transforms/${parts[1]}';
        }
      } catch (_) {}
    }
    return videoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final displayHeight = aspectRatio == VideoAspectRatio.portrait9x16 ? height * 1.4 : height;
    final thumbnailUrl = _getCloudinaryThumbnailUrl(videoUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: displayHeight,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.softStone,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.ink,
                child: const Icon(Icons.videocam, color: AppColors.mutedSlate, size: 40),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.softStone,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
            Container(
              color: AppColors.cohereBlack.withValues(alpha: 0.3),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: AppColors.canvasWhite,
                size: 48,
              ),
            ),
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cohereBlack.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: AppColors.canvasWhite, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      aspectRatio == VideoAspectRatio.portrait9x16 ? '9:16' : '16:9',
                      style: const TextStyle(
                        color: AppColors.canvasWhite,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
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
