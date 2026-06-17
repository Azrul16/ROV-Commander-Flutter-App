import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/rov_status.dart';
import 'status_card.dart';

class ModeSwitchCard extends StatelessWidget {
  const ModeSwitchCard({
    super.key,
    required this.status,
    required this.busy,
    required this.onManual,
    required this.onAutopilot,
  });

  final RovStatus? status;
  final bool busy;
  final VoidCallback onManual;
  final VoidCallback onAutopilot;

  @override
  Widget build(BuildContext context) {
    final mode = status?.vehicle.mode ?? 'manual';
    final autopilot = mode == 'autopilot';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  autopilot ? Icons.route : Icons.gamepad,
                  color: autopilot ? AppColors.warning : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  autopilot ? 'AUTONOMOUS' : 'OPERATOR',
                  style: TextStyle(
                    color: autopilot ? AppColors.warning : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'manual',
                  icon: Icon(Icons.gamepad),
                  label: Text('MANUAL'),
                ),
                ButtonSegment(
                  value: 'autopilot',
                  icon: Icon(Icons.route),
                  label: Text('AUTOPILOT'),
                ),
              ],
              selected: {mode == 'autopilot' ? 'autopilot' : 'manual'},
              onSelectionChanged: busy
                  ? null
                  : (selection) {
                      final next = selection.first;
                      if (next == mode) {
                        return;
                      }
                      if (next == 'autopilot') {
                        onAutopilot();
                      } else {
                        onManual();
                      }
                    },
            ),
            if (autopilot) ...[
              const SizedBox(height: 12),
              MetricRow(
                label: 'Autopilot action',
                value: status?.vehicle.autopilotAction ?? 'inactive',
              ),
              MetricRow(
                label: 'Decision reason',
                value: status?.vehicle.reason ?? 'No reason reported',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
