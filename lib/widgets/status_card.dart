import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/rov_status.dart';
import '../blocs/rov_cubit.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.state,
    required this.message,
  });

  final ConnectionStateKind state;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (state) {
      ConnectionStateKind.online => (
        'Online',
        AppColors.success,
        Icons.check_circle,
      ),
      ConnectionStateKind.connecting => (
        'Connecting',
        AppColors.warning,
        Icons.sync,
      ),
      ConnectionStateKind.offline => (
        'Offline',
        AppColors.danger,
        Icons.cloud_off,
      ),
      ConnectionStateKind.serverError => (
        'Server error',
        AppColors.danger,
        Icons.error,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          if (message != null) ...[
            const SizedBox(width: 10),
            Expanded(child: Text(message!, overflow: TextOverflow.ellipsis)),
          ],
        ],
      ),
    );
  }
}

class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: _AlertBanner(
        color: Color(0xFFD7263D),
        icon: Icons.warning_amber,
        text: 'EMERGENCY STOP ACTIVE',
      ),
    );
  }
}

class AutopilotBanner extends StatelessWidget {
  const AutopilotBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: _AlertBanner(
        color: Color(0xFFFFB020),
        icon: Icons.route,
        text: 'AUTOPILOT ACTIVE',
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class TelemetryGrid extends StatelessWidget {
  const TelemetryGrid({super.key, required this.status});

  final RovStatus? status;

  @override
  Widget build(BuildContext context) {
    final sonar = status?.sonar;
    final arduino = status?.arduino;
    final camera = status?.camera;
    final vehicle = status?.vehicle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth > 520;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: twoColumns ? 2 : 1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: twoColumns ? 1.35 : 1.75,
          children: [
            _TelemetryCard(
              title: 'Sonar',
              icon: Icons.sensors,
              accent: AppColors.primary,
              children: [
                SonarMetric(
                  label: 'Left',
                  value: sonar?.leftCm,
                  centerSensor: false,
                ),
                SonarMetric(
                  label: 'Center',
                  value: sonar?.centerCm,
                  centerSensor: true,
                ),
                SonarMetric(
                  label: 'Right',
                  value: sonar?.rightCm,
                  centerSensor: false,
                ),
                MetricRow(
                  label: 'Obstacle',
                  value: sonar?.obstaclePresent == true ? 'Present' : 'Clear',
                ),
              ],
            ),
            _TelemetryCard(
              title: 'Environment',
              icon: Icons.water_drop,
              accent: AppColors.cyan,
              children: [
                MetricRow(
                  label: 'Water detected',
                  value: arduino?.waterDetected == true ? 'Yes' : 'No',
                ),
                MetricRow(
                  label: 'Water raw',
                  value: arduino?.waterRaw?.toString() ?? 'Unavailable',
                ),
                MetricRow(
                  label: 'Soil condition',
                  value: arduino?.soilWet == true ? 'Wet' : 'Dry',
                ),
                MetricRow(
                  label: 'Soil raw',
                  value: arduino?.soilRaw?.toString() ?? 'Unavailable',
                ),
                if (arduino?.error != null)
                  MetricRow(label: 'Arduino error', value: arduino!.error!),
              ],
            ),
            _TelemetryCard(
              title: 'Vehicle',
              icon: Icons.precision_manufacturing,
              accent: AppColors.violet,
              children: [
                MetricRow(
                  label: 'Mode',
                  value: vehicle?.mode.toUpperCase() ?? 'UNKNOWN',
                ),
                MetricRow(
                  label: 'Movement',
                  value: vehicle?.movement.toUpperCase() ?? 'UNKNOWN',
                ),
                MetricRow(
                  label: 'Speed',
                  value: (vehicle?.speed ?? 0).toStringAsFixed(2),
                ),
                MetricRow(
                  label: 'Emergency',
                  value: vehicle?.emergencyStop == true ? 'Active' : 'Clear',
                ),
              ],
            ),
            _TelemetryCard(
              title: 'Systems',
              icon: Icons.memory,
              accent: AppColors.success,
              children: [
                MetricRow(
                  label: 'Camera',
                  value: camera?.connected == true
                      ? 'Connected'
                      : 'Disconnected',
                ),
                MetricRow(
                  label: 'Arduino',
                  value: arduino?.connected == true
                      ? 'Connected'
                      : 'Disconnected',
                ),
                MetricRow(
                  label: 'Frames',
                  value: camera?.frameCount.toString() ?? '0',
                ),
                MetricRow(
                  label: 'Detection',
                  value: camera?.objectDetectionEnabled == true
                      ? (camera?.objectDetected == true
                            ? 'Object detected'
                            : 'Clear')
                      : 'Disabled',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: accent.withValues(alpha: 0.28)),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class SonarMetric extends StatelessWidget {
  const SonarMetric({
    super.key,
    required this.label,
    required this.value,
    required this.centerSensor,
  });

  final String label;
  final double? value;
  final bool centerSensor;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(value);
    final display = value == null
        ? 'Unavailable'
        : '${value!.toStringAsFixed(1)} cm';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
              Text(
                display,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: value == null ? 0 : value!.clamp(0, 100) / 100,
              color: color,
              backgroundColor: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(double? distance) {
    if (distance == null) {
      return Colors.grey;
    }
    if (distance < 20) {
      return Colors.redAccent;
    }
    if (distance <= 40) {
      return Colors.orangeAccent;
    }
    return Colors.greenAccent;
  }
}
