import 'package:flutter/material.dart';

class EmergencyStopButton extends StatelessWidget {
  const EmergencyStopButton({
    super.key,
    required this.emergencyActive,
    required this.busy,
    required this.onStop,
    required this.onClear,
  });

  final bool emergencyActive;
  final bool busy;
  final VoidCallback onStop;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(58),
            ),
            onPressed: busy ? null : onStop,
            icon: const Icon(Icons.warning_amber),
            label: const Text('EMERGENCY STOP', textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
            ),
            onPressed: emergencyActive && !busy ? onClear : null,
            child: const Text('Clear Emergency', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
