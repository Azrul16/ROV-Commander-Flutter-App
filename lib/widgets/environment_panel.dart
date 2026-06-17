import 'package:flutter/material.dart';

import '../models/rov_status.dart';
import 'status_card.dart';

class EnvironmentPanel extends StatelessWidget {
  const EnvironmentPanel({super.key, required this.environment});

  final ArduinoStatus? environment;

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
                  Icons.water_drop,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Environment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MetricRow(
              label: 'Arduino',
              value: environment?.connected == true
                  ? 'Connected'
                  : 'Disconnected',
            ),
            MetricRow(
              label: 'Water detected',
              value: environment?.waterDetected == true ? 'Yes' : 'No',
            ),
            MetricRow(
              label: 'Water raw',
              value: environment?.waterRaw?.toString() ?? 'Unavailable',
            ),
            MetricRow(
              label: 'Soil condition',
              value: environment?.soilWet == true ? 'Wet' : 'Dry',
            ),
            MetricRow(
              label: 'Soil raw',
              value: environment?.soilRaw?.toString() ?? 'Unavailable',
            ),
            if (environment?.error != null)
              MetricRow(label: 'Error', value: environment!.error!),
          ],
        ),
      ),
    );
  }
}
