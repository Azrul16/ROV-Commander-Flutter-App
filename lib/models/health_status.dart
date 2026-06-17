class HealthStatus {
  const HealthStatus({
    required this.online,
    required this.defaultMode,
    required this.cameraConnected,
    required this.arduinoConnected,
    this.sonarUpdatedAt,
  });

  factory HealthStatus.reachable() {
    return const HealthStatus(
      online: true,
      defaultMode: 'manual',
      cameraConnected: false,
      arduinoConnected: false,
    );
  }

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    return HealthStatus(
      online:
          rawStatus == true ||
          {
            'online',
            'ok',
            'healthy',
            'up',
          }.contains(rawStatus?.toString().toLowerCase()),
      defaultMode: json['default_mode']?.toString() ?? 'manual',
      cameraConnected: json['camera_connected'] == true,
      arduinoConnected: json['arduino_connected'] == true,
      sonarUpdatedAt: (json['sonar_updated_at'] as num?)?.toDouble(),
    );
  }

  final bool online;
  final String defaultMode;
  final bool cameraConnected;
  final bool arduinoConnected;
  final double? sonarUpdatedAt;
}
