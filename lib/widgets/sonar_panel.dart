import 'package:flutter/material.dart';

import '../models/rov_status.dart';
import 'status_card.dart';

class SonarPanel extends StatelessWidget {
  const SonarPanel({super.key, required this.sonar});

  final SonarStatus? sonar;

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
                Icon(
                  Icons.sensors,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sonar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
      ),
    );
  }
}
