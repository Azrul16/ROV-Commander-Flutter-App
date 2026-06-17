import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

import '../core/constants.dart';
import '../models/rov_status.dart';
import '../screens/full_screen_video_screen.dart';

class VideoStreamCard extends StatefulWidget {
  const VideoStreamCard({
    super.key,
    required this.videoUrl,
    required this.status,
    required this.onRetry,
  });

  final String videoUrl;
  final RovStatus? status;
  final VoidCallback onRetry;

  @override
  State<VideoStreamCard> createState() => _VideoStreamCardState();
}

class _VideoStreamCardState extends State<VideoStreamCard> {
  int _reloadKey = 0;

  void _retry() {
    setState(() => _reloadKey++);
    widget.onRetry();
  }

  void _fullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenVideoScreen(
          videoUrl: widget.videoUrl,
          status: widget.status,
          reloadKey: _reloadKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraConnected = widget.status?.camera.connected ?? false;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Icon(
                  cameraConnected ? Icons.videocam : Icons.videocam_off,
                  color: cameraConnected ? AppColors.success : AppColors.danger,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cameraConnected ? 'Live camera feed' : 'Camera offline',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _FrameBadge(frameCount: widget.status?.camera.frameCount ?? 0),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cameraConnected && widget.videoUrl.isNotEmpty)
                  Mjpeg(
                    key: ValueKey('${widget.videoUrl}-$_reloadKey'),
                    stream: widget.videoUrl,
                    isLive: true,
                    fit: BoxFit.cover,
                    loading: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    error: (context, error, stack) => _VideoPlaceholder(
                      icon: Icons.videocam_off,
                      text: 'Camera stream unavailable',
                      onRetry: _retry,
                    ),
                  )
                else
                  _VideoPlaceholder(
                    icon: Icons.videocam_off,
                    text: 'Camera unavailable',
                    onRetry: _retry,
                  ),
                _VideoOverlay(status: widget.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Full screen',
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _fullscreen,
                ),
                IconButton(
                  tooltip: 'Retry stream',
                  icon: const Icon(Icons.replay),
                  onPressed: _retry,
                ),
                const Spacer(),
                Text(
                  widget.videoUrl.isEmpty ? 'No stream URL' : widget.videoUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameBadge extends StatelessWidget {
  const _FrameBadge({required this.frameCount});

  final int frameCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          '$frameCount frames',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _VideoOverlay extends StatelessWidget {
  const _VideoOverlay({required this.status});

  final RovStatus? status;

  @override
  Widget build(BuildContext context) {
    final mode = (status?.vehicle.mode ?? 'manual').toUpperCase();
    final movement = (status?.vehicle.movement ?? 'stopped').toUpperCase();
    final objectText = status?.camera.objectDetectionEnabled == true
        ? (status?.camera.objectDetected == true
              ? 'OBJECT DETECTED'
              : 'SCAN CLEAR')
        : 'OBJECT DETECTION OFF';
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Pill(text: 'Mode: $mode'),
          _Pill(text: 'Movement: $movement'),
          _Pill(text: objectText),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({
    required this.icon,
    required this.text,
    required this.onRetry,
  });

  final IconData icon;
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050A0C),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Colors.white54),
            const SizedBox(height: 10),
            Text(text),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
