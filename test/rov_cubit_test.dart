import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rov/blocs/rov_cubit.dart';
import 'package:rov/models/health_status.dart';
import 'package:rov/models/rov_status.dart';
import 'package:rov/services/api_service.dart';
import 'package:rov/services/storage_service.dart';

void main() {
  late ConnectivityPlatform originalConnectivityPlatform;

  setUp(() {
    originalConnectivityPlatform = ConnectivityPlatform.instance;
    ConnectivityPlatform.instance = _FakeConnectivityPlatform();
  });

  tearDown(() {
    ConnectivityPlatform.instance = originalConnectivityPlatform;
  });

  test('connect opens the dashboard without calling health', () async {
    final api = _FakeApiService();
    final preferences = _FakeStorageService();
    final cubit = RovCubit(
      api: api,
      preferences: preferences,
      connectivity: Connectivity(),
    );

    final connected = await cubit.connect('192.168.1.193');
    await pumpEventQueue();
    await cubit.close();

    expect(connected, isTrue);
    expect(api.healthCalls, 0);
    expect(preferences.savedBaseUrl, 'http://192.168.1.193:8000');
    expect(cubit.state.startupDestination, StartupDestination.dashboard);
    expect(cubit.state.baseUrl, 'http://192.168.1.193:8000');
  });
}

class _FakeApiService extends ApiService {
  _FakeApiService() : super(dio: Dio());

  int healthCalls = 0;

  @override
  Future<HealthStatus> health(String baseUrl) {
    healthCalls += 1;
    throw StateError('health should not be called while connecting');
  }

  @override
  Future<RovStatus> status(String baseUrl) async {
    return const RovStatus(
      vehicle: VehicleStatus(
        mode: 'manual',
        movement: 'stopped',
        speed: 0,
        emergencyStop: false,
        autopilotAction: 'inactive',
        reason: '',
      ),
      sonar: SonarStatus(obstaclePresent: false),
      arduino: ArduinoStatus(
        connected: false,
        waterDetected: false,
        soilWet: false,
      ),
      camera: CameraStatus(
        connected: false,
        frameCount: 0,
        objectDetected: false,
        objectDetectionEnabled: false,
      ),
    );
  }
}

class _FakeStorageService extends StorageService {
  String? savedBaseUrl;

  @override
  Future<String?> loadBaseUrl() async => savedBaseUrl;

  @override
  Future<void> saveBaseUrl(String baseUrl) async {
    savedBaseUrl = baseUrl;
  }
}

class _FakeConnectivityPlatform extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.wifi];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _controller.stream;
  }
}
