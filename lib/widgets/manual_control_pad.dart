import 'package:flutter/material.dart';

import '../core/constants.dart';

class ManualControlPad extends StatelessWidget {
  const ManualControlPad({
    super.key,
    required this.enabled,
    required this.onStart,
    required this.onStop,
  });

  final bool enabled;
  final Future<void> Function(String command, {double speed}) onStart;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Manual Control',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(
                  enabled ? Icons.lock_open : Icons.lock,
                  size: 18,
                  color: enabled ? Colors.greenAccent : Colors.white38,
                ),
                const SizedBox(width: 6),
                Text(
                  enabled ? 'Enabled' : 'Locked',
                  style: TextStyle(
                    color: enabled ? AppColors.success : Colors.white54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 232,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          child: _DriveButton(
                            icon: Icons.keyboard_arrow_up,
                            label: 'Forward',
                            command: 'forward',
                            enabled: enabled,
                            onStart: onStart,
                            onStop: onStop,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _DriveButton(
                            icon: Icons.keyboard_arrow_left,
                            label: 'Left',
                            command: 'left',
                            enabled: enabled,
                            onStart: onStart,
                            onStop: onStop,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StopButton(enabled: enabled, onStop: onStop),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DriveButton(
                            icon: Icons.keyboard_arrow_right,
                            label: 'Right',
                            command: 'right',
                            enabled: enabled,
                            onStart: onStart,
                            onStop: onStop,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          child: _DriveButton(
                            icon: Icons.keyboard_arrow_down,
                            label: 'Backward',
                            command: 'backward',
                            enabled: enabled,
                            onStart: onStart,
                            onStop: onStop,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriveButton extends StatelessWidget {
  const _DriveButton({
    required this.icon,
    required this.label,
    required this.command,
    required this.enabled,
    required this.onStart,
    required this.onStop,
  });

  final IconData icon;
  final String label;
  final String command;
  final bool enabled;
  final Future<void> Function(String command, {double speed}) onStart;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: enabled ? (_) => onStart(command) : null,
      onPointerUp: enabled ? (_) => onStop() : null,
      onPointerCancel: enabled ? (_) => onStop() : null,
      child: Tooltip(
        message: label,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.45,
          duration: const Duration(milliseconds: 160),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: enabled
                  ? AppColors.cardElevated
                  : AppColors.cardElevated.withValues(alpha: 0.7),
              border: Border.all(
                color: enabled
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : Colors.white12,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 38, color: AppColors.primary),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.enabled, required this.onStop});

  final bool enabled;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Stop',
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger.withValues(alpha: 0.88),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: enabled ? onStop : null,
        child: const Icon(Icons.stop),
      ),
    );
  }
}
