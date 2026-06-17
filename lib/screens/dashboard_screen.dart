import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants.dart';
import '../models/rov_status.dart';
import '../blocs/rov_cubit.dart';
import '../widgets/emergency_stop_button.dart';
import '../widgets/manual_control_pad.dart';
import '../widgets/mode_switch_card.dart';
import '../widgets/status_card.dart';
import '../widgets/video_stream_card.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<RovCubit>().shutdownDashboard();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<RovCubit>().handleAppLifecycle(state);
  }

  Future<void> _confirmAutopilot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable autopilot mode?'),
        content: const Text(
          'The ROV will move automatically using the left, center and right sonar sensors. Keep the emergency stop button available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<RovCubit>().setMode('autopilot');
    }
  }

  Future<void> _confirmClearEmergency() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear emergency stop?'),
        content: const Text(
          'Make sure the area around the ROV is safe before re-enabling movement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<RovCubit>().clearEmergency();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RovCubit, RovState>(
      builder: (context, state) {
        final controller = context.read<RovCubit>();
        final status = state.status;
        final pages = [
          _LivePage(controller: controller, status: status),
          _ControlPage(
            controller: controller,
            status: status,
            onManual: () => controller.setMode('manual'),
            onAutopilot: _confirmAutopilot,
            onClearEmergency: _confirmClearEmergency,
          ),
          _TelemetryPage(status: status),
          _SystemsPage(controller: controller, status: status),
        ];

        return Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ROV Commander',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  controller.baseUrl ?? 'No server',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: controller.refreshStatus,
              ),
              IconButton(
                tooltip: 'Change server',
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.videocam_outlined),
                selectedIcon: Icon(Icons.videocam),
                label: 'Live',
              ),
              NavigationDestination(
                icon: Icon(Icons.gamepad_outlined),
                selectedIcon: Icon(Icons.gamepad),
                label: 'Control',
              ),
              NavigationDestination(
                icon: Icon(Icons.monitor_heart_outlined),
                selectedIcon: Icon(Icons.monitor_heart),
                label: 'Telemetry',
              ),
              NavigationDestination(
                icon: Icon(Icons.memory_outlined),
                selectedIcon: Icon(Icons.memory),
                label: 'Systems',
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, AppColors.backgroundDeep],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                    child: Column(
                      children: [
                        ConnectionBanner(
                          state: controller.connectionState,
                          message: controller.dashboardError,
                        ),
                        if (status?.vehicle.emergencyStop == true)
                          const EmergencyBanner(),
                        if (status?.vehicle.mode == 'autopilot')
                          const AutopilotBanner(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refreshStatus,
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: pages,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                    child: EmergencyStopButton(
                      emergencyActive: status?.vehicle.emergencyStop == true,
                      busy: controller.isSendingCommand,
                      onStop: controller.emergencyStop,
                      onClear: _confirmClearEmergency,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LivePage extends StatelessWidget {
  const _LivePage({required this.controller, required this.status});

  final RovCubit controller;
  final RovStatus? status;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
      children: [
        _CommandHeader(status: status),
        const SizedBox(height: 12),
        VideoStreamCard(
          videoUrl: controller.videoUrl,
          status: status,
          onRetry: controller.refreshStatus,
        ),
        const SizedBox(height: 12),
        _QuickMetrics(status: status),
      ],
    );
  }
}

class _ControlPage extends StatelessWidget {
  const _ControlPage({
    required this.controller,
    required this.status,
    required this.onManual,
    required this.onAutopilot,
    required this.onClearEmergency,
  });

  final RovCubit controller;
  final RovStatus? status;
  final VoidCallback onManual;
  final VoidCallback onAutopilot;
  final VoidCallback onClearEmergency;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
      children: [
        ModeSwitchCard(
          status: status,
          busy: controller.isSendingCommand,
          onManual: onManual,
          onAutopilot: onAutopilot,
        ),
        const SizedBox(height: 12),
        ManualControlPad(
          enabled: controller.canUseManualControls,
          onStart: controller.startMovement,
          onStop: () => controller.stopMovement(),
        ),
        const SizedBox(height: 12),
        _SafetyPanel(status: status, onClearEmergency: onClearEmergency),
      ],
    );
  }
}

class _TelemetryPage extends StatelessWidget {
  const _TelemetryPage({required this.status});

  final RovStatus? status;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
      children: [
        _SectionHeader(
          icon: Icons.monitor_heart,
          title: 'Telemetry',
          subtitle: 'Live sensor readings and movement state',
        ),
        const SizedBox(height: 12),
        TelemetryGrid(status: status),
      ],
    );
  }
}

class _SystemsPage extends StatelessWidget {
  const _SystemsPage({required this.controller, required this.status});

  final RovCubit controller;
  final RovStatus? status;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
      children: [
        _SectionHeader(
          icon: Icons.memory,
          title: 'Systems',
          subtitle: controller.baseUrl ?? 'No active server',
        ),
        const SizedBox(height: 12),
        _SystemGrid(controller: controller, status: status),
      ],
    );
  }
}

class _CommandHeader extends StatelessWidget {
  const _CommandHeader({required this.status});

  final RovStatus? status;

  @override
  Widget build(BuildContext context) {
    final vehicle = status?.vehicle;
    final sonar = status?.sonar;
    final healthColor = status == null
        ? AppColors.warning
        : vehicle?.emergencyStop == true
        ? AppColors.danger
        : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(Icons.radar, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ROV Commander',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _StatusChip(
                          icon: Icons.settings_remote,
                          label: (vehicle?.mode ?? 'manual').toUpperCase(),
                          color: vehicle?.mode == 'autopilot'
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
                        _StatusChip(
                          icon: Icons.near_me,
                          label: (vehicle?.movement ?? 'stopped').toUpperCase(),
                          color: AppColors.violet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _SignalBadge(online: status != null, color: healthColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniSonarBar(label: 'L', value: sonar?.leftCm),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniSonarBar(label: 'C', value: sonar?.centerCm),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniSonarBar(label: 'R', value: sonar?.rightCm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSonarBar extends StatelessWidget {
  const _MiniSonarBar({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final color = _distanceColor(value, centerSensor: false);
    final normalized = value == null ? 0.0 : (value!.clamp(0, 100) / 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              value == null ? '-- cm' : '${value!.toStringAsFixed(0)} cm',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: normalized,
            color: color,
            backgroundColor: AppColors.border.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  const _QuickMetrics({required this.status});

  final RovStatus? status;

  @override
  Widget build(BuildContext context) {
    final sonar = status?.sonar;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.42,
      children: [
        _MetricTile(
          icon: Icons.sensors,
          label: 'Center sonar',
          value: sonar?.centerCm == null
              ? '--'
              : '${sonar!.centerCm!.toStringAsFixed(1)} cm',
          accent: _distanceColor(sonar?.centerCm, centerSensor: true),
        ),
        _MetricTile(
          icon: Icons.water_drop,
          label: 'Water',
          value: status?.arduino.waterDetected == true ? 'Detected' : 'Clear',
          accent: status?.arduino.waterDetected == true
              ? Colors.orangeAccent
              : Colors.greenAccent,
        ),
        _MetricTile(
          icon: Icons.grass,
          label: 'Soil',
          value: status?.arduino.soilWet == true ? 'Wet' : 'Dry',
          accent: status?.arduino.soilWet == true
              ? const Color(0xFF64D2FF)
              : Colors.white70,
        ),
        _MetricTile(
          icon: Icons.camera_alt,
          label: 'Camera',
          value: status?.camera.connected == true ? 'Online' : 'Offline',
          accent: status?.camera.connected == true
              ? Colors.greenAccent
              : Colors.redAccent,
        ),
      ],
    );
  }
}

class _SafetyPanel extends StatelessWidget {
  const _SafetyPanel({required this.status, required this.onClearEmergency});

  final RovStatus? status;
  final VoidCallback onClearEmergency;

  @override
  Widget build(BuildContext context) {
    final emergency = status?.vehicle.emergencyStop == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.health_and_safety,
              title: 'Safety',
              subtitle: 'Movement locks and emergency state',
              compact: true,
            ),
            const SizedBox(height: 12),
            MetricRow(
              label: 'Emergency stop',
              value: emergency ? 'Active' : 'Clear',
            ),
            MetricRow(
              label: 'Movement',
              value: status?.vehicle.movement.toUpperCase() ?? 'UNKNOWN',
            ),
            MetricRow(
              label: 'Mode',
              value: status?.vehicle.mode.toUpperCase() ?? 'UNKNOWN',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: emergency ? onClearEmergency : null,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Clear Emergency'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemGrid extends StatelessWidget {
  const _SystemGrid({required this.controller, required this.status});

  final RovCubit controller;
  final RovStatus? status;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: [
        _MetricTile(
          icon: Icons.cloud_done,
          label: 'Server',
          value: switch (controller.connectionState) {
            ConnectionStateKind.online => 'Online',
            ConnectionStateKind.connecting => 'Connecting',
            ConnectionStateKind.offline => 'Offline',
            ConnectionStateKind.serverError => 'Error',
          },
          accent: controller.connectionState == ConnectionStateKind.online
              ? Colors.greenAccent
              : Colors.redAccent,
        ),
        _MetricTile(
          icon: Icons.memory,
          label: 'Arduino',
          value: status?.arduino.connected == true ? 'Connected' : 'Offline',
          accent: status?.arduino.connected == true
              ? Colors.greenAccent
              : Colors.redAccent,
        ),
        _MetricTile(
          icon: Icons.videocam,
          label: 'Camera',
          value: status?.camera.connected == true ? 'Connected' : 'Offline',
          accent: status?.camera.connected == true
              ? Colors.greenAccent
              : Colors.redAccent,
        ),
        _MetricTile(
          icon: Icons.center_focus_strong,
          label: 'Detection',
          value: status?.camera.objectDetectionEnabled == true
              ? (status?.camera.objectDetected == true ? 'Object' : 'Clear')
              : 'Disabled',
          accent: status?.camera.objectDetected == true
              ? Colors.orangeAccent
              : const Color(0xFF00D1B2),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D1B2), size: compact ? 22 : 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SignalBadge extends StatelessWidget {
  const _SignalBadge({required this.online, Color? color})
    : color = color ?? Colors.greenAccent;

  final bool online;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = online ? color : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            online ? Icons.bolt : Icons.priority_high,
            color: resolvedColor,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            online ? 'READY' : 'LOCKED',
            style: TextStyle(
              color: resolvedColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Color _distanceColor(double? distance, {required bool centerSensor}) {
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
