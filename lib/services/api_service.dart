import 'package:dio/dio.dart';

import '../models/health_status.dart';
import '../models/rov_status.dart';
import 'rov_api_client.dart';

class ApiService {
  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 4),
            ),
          );

  final Dio _dio;
  final Map<String, RovApiClient> _clients = {};

  RovApiClient _client(String baseUrl) {
    return _clients.putIfAbsent(
      baseUrl,
      () => RovApiClient(_dio, baseUrl: baseUrl),
    );
  }

  Map<String, dynamic> _asMap(dynamic data, String label) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    throw FormatException('$label response was empty or invalid.');
  }

  HealthStatus _parseHealth(dynamic data, int? statusCode) {
    if (data is Map<String, dynamic>) {
      return HealthStatus.fromJson(
        data['status'] == null ? {'status': true, ...data} : data,
      );
    }
    if (data is Map) {
      final mapped = data.cast<String, dynamic>();
      return HealthStatus.fromJson(
        mapped['status'] == null ? {'status': true, ...mapped} : mapped,
      );
    }

    final successful =
        statusCode != null && statusCode >= 200 && statusCode < 300;
    if (successful && (data == null || data.toString().trim().isEmpty)) {
      return HealthStatus.reachable();
    }
    if (successful) {
      final value = data.toString().trim().toLowerCase();
      if ({'ok', 'online', 'healthy', 'up', 'true'}.contains(value)) {
        return HealthStatus.reachable();
      }
    }

    throw const FormatException('Health response was empty or invalid.');
  }

  Future<HealthStatus> health(String baseUrl) async {
    final response = await _client(baseUrl).health();
    return _parseHealth(response.data, response.response.statusCode);
  }

  Future<RovStatus> status(String baseUrl) async {
    final response = await _client(baseUrl).status();
    final data = _asMap(response.data, 'Status');
    return RovStatus.fromJson(data);
  }

  Future<SonarStatus> sonar(String baseUrl) async {
    final response = await _client(baseUrl).sonar();
    final data = _asMap(response.data, 'Sonar');
    return SonarStatus.fromJson(data);
  }

  Future<ArduinoStatus> environment(String baseUrl) async {
    final response = await _client(baseUrl).environment();
    final data = _asMap(response.data, 'Environment');
    return ArduinoStatus.fromJson(data);
  }

  Future<void> setMode(String baseUrl, String mode) async {
    await _client(baseUrl).setMode({'mode': mode});
  }

  Future<void> control(String baseUrl, String command, double speed) async {
    await _client(baseUrl).control({'command': command, 'speed': speed});
  }

  Future<void> emergencyStop(String baseUrl) async {
    await _client(baseUrl).emergencyStop();
  }

  Future<void> clearEmergency(String baseUrl) async {
    await _client(baseUrl).clearEmergency();
  }
}
