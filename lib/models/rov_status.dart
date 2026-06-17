class RovStatus {
  const RovStatus({
    required this.vehicle,
    required this.sonar,
    required this.arduino,
    required this.camera,
    this.serverTime,
  });

  factory RovStatus.fromJson(Map<String, dynamic> json) {
    return RovStatus(
      vehicle: VehicleStatus.fromJson(
        (json['vehicle'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      sonar: SonarStatus.fromJson(
        (json['sonar'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      arduino: ArduinoStatus.fromJson(
        (json['arduino'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      camera: CameraStatus.fromJson(
        (json['camera'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      serverTime: (json['server_time'] as num?)?.toDouble(),
    );
  }

  final VehicleStatus vehicle;
  final SonarStatus sonar;
  final ArduinoStatus arduino;
  final CameraStatus camera;
  final double? serverTime;
}

class VehicleStatus {
  const VehicleStatus({
    required this.mode,
    required this.movement,
    required this.speed,
    required this.emergencyStop,
    required this.autopilotAction,
    required this.reason,
    this.updatedAt,
  });

  factory VehicleStatus.fromJson(Map<String, dynamic> json) {
    return VehicleStatus(
      mode: json['mode']?.toString() ?? 'manual',
      movement: json['movement']?.toString() ?? 'stopped',
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      emergencyStop: json['emergency_stop'] == true,
      autopilotAction: json['autopilot_action']?.toString() ?? 'inactive',
      reason: json['reason']?.toString() ?? '',
      updatedAt: (json['updated_at'] as num?)?.toDouble(),
    );
  }

  final String mode;
  final String movement;
  final double speed;
  final bool emergencyStop;
  final String autopilotAction;
  final String reason;
  final double? updatedAt;
}

class SonarStatus {
  const SonarStatus({
    this.leftCm,
    this.centerCm,
    this.rightCm,
    required this.obstaclePresent,
    this.updatedAt,
  });

  factory SonarStatus.fromJson(Map<String, dynamic> json) {
    return SonarStatus(
      leftCm: (json['left_cm'] as num?)?.toDouble(),
      centerCm: (json['center_cm'] as num?)?.toDouble(),
      rightCm: (json['right_cm'] as num?)?.toDouble(),
      obstaclePresent: json['obstacle_present'] == true,
      updatedAt: (json['updated_at'] as num?)?.toDouble(),
    );
  }

  final double? leftCm;
  final double? centerCm;
  final double? rightCm;
  final bool obstaclePresent;
  final double? updatedAt;
}

class ArduinoStatus {
  const ArduinoStatus({
    required this.connected,
    this.waterRaw,
    required this.waterDetected,
    this.soilRaw,
    required this.soilWet,
    this.error,
    this.updatedAt,
  });

  factory ArduinoStatus.fromJson(Map<String, dynamic> json) {
    return ArduinoStatus(
      connected: json['connected'] == true,
      waterRaw: (json['water_raw'] as num?)?.toInt(),
      waterDetected: json['water_detected'] == true,
      soilRaw: (json['soil_raw'] as num?)?.toInt(),
      soilWet: json['soil_wet'] == true,
      error: json['error']?.toString(),
      updatedAt: (json['updated_at'] as num?)?.toDouble(),
    );
  }

  final bool connected;
  final int? waterRaw;
  final bool waterDetected;
  final int? soilRaw;
  final bool soilWet;
  final String? error;
  final double? updatedAt;
}

class CameraStatus {
  const CameraStatus({
    required this.connected,
    required this.frameCount,
    required this.objectDetected,
    required this.objectDetectionEnabled,
    this.updatedAt,
  });

  factory CameraStatus.fromJson(Map<String, dynamic> json) {
    return CameraStatus(
      connected: json['connected'] == true,
      frameCount: (json['frame_count'] as num?)?.toInt() ?? 0,
      objectDetected: json['object_detected'] == true,
      objectDetectionEnabled: json['object_detection_enabled'] == true,
      updatedAt: (json['updated_at'] as num?)?.toDouble(),
    );
  }

  final bool connected;
  final int frameCount;
  final bool objectDetected;
  final bool objectDetectionEnabled;
  final double? updatedAt;
}
