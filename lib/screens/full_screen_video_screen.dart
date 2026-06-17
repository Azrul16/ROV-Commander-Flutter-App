import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

import '../models/rov_status.dart';

class FullScreenVideoScreen extends StatelessWidget {
  const FullScreenVideoScreen({
    super.key,
    required this.videoUrl,
    required this.status,
    required this.reloadKey,
  });

  final String videoUrl;
  final RovStatus? status;
  final int reloadKey;

  @override
  Widget build(BuildContext context) {
    final cameraConnected = status?.camera.connected ?? false;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: cameraConnected && videoUrl.isNotEmpty
                  ? Mjpeg(
                      key: ValueKey('fullscreen-$videoUrl-$reloadKey'),
                      stream: videoUrl,
                      isLive: true,
                      fit: BoxFit.contain,
                      loading: (_) => const CircularProgressIndicator(),
                      error: (context, error, stack) =>
                          const Text('Camera stream unavailable'),
                    )
                  : const Text('Camera unavailable'),
            ),
            _FullscreenOverlay(status: status),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenOverlay extends StatelessWidget {
  const _FullscreenOverlay({required this.status});

  final RovStatus? status;

  @override
  Widget build(BuildContext context) {
    final mode = (status?.vehicle.mode ?? 'manual').toUpperCase();
    final movement = (status?.vehicle.movement ?? 'stopped').toUpperCase();
    return Positioned(
      left: 12,
      right: 72,
      bottom: 12,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _OverlayPill(text: 'Mode: $mode'),
          _OverlayPill(text: 'Movement: $movement'),
          _OverlayPill(text: 'Frames ${status?.camera.frameCount ?? 0}'),
        ],
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.text});

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
