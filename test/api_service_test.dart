import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rov/services/api_service.dart';

void main() {
  group('ApiService.health', () {
    test('accepts an empty successful health response', () async {
      final service = ApiService(dio: _dioRespondingWith(''));

      final health = await service.health('http://rov.local:5000');

      expect(health.online, isTrue);
      expect(health.defaultMode, 'manual');
    });

    test('accepts a plain text successful health response', () async {
      final service = ApiService(dio: _dioRespondingWith('OK'));

      final health = await service.health('http://rov.local:5000');

      expect(health.online, isTrue);
    });

    test('accepts JSON health details without a status field', () async {
      final service = ApiService(
        dio: _dioRespondingWith(
          '{"default_mode":"auto","camera_connected":true}',
          contentType: Headers.jsonContentType,
        ),
      );

      final health = await service.health('http://rov.local:5000');

      expect(health.online, isTrue);
      expect(health.defaultMode, 'auto');
      expect(health.cameraConnected, isTrue);
    });
  });

  group('ApiService documented FastAPI contract', () {
    test('parses the documented status response', () async {
      final service = ApiService(
        dio: _dioRespondingWith(
          jsonEncode({
            'vehicle': {
              'mode': 'manual',
              'movement': 'stopped',
              'speed': 0.5,
              'emergency_stop': false,
              'autopilot_action': 'inactive',
              'reason': 'manual mode',
              'updated_at': 1781645000.123,
            },
            'sonar': {
              'left_cm': 58.4,
              'center_cm': 74.2,
              'right_cm': 43.9,
              'obstacle_present': false,
              'updated_at': 1781645000.123,
            },
            'arduino': {
              'connected': true,
              'water_raw': 430,
              'water_detected': true,
              'soil_raw': 387,
              'soil_wet': true,
              'error': null,
              'updated_at': 1781645000.123,
            },
            'camera': {
              'connected': true,
              'frame_count': 5423,
              'object_detected': false,
              'object_detection_enabled': false,
              'updated_at': 1781645000.123,
            },
            'server_time': 1781645000.456,
          }),
          contentType: Headers.jsonContentType,
        ),
      );

      final status = await service.status('http://192.168.1.193:8000');

      expect(status.vehicle.mode, 'manual');
      expect(status.vehicle.speed, 0.5);
      expect(status.sonar.centerCm, 74.2);
      expect(status.arduino.waterDetected, isTrue);
      expect(status.camera.frameCount, 5423);
      expect(status.serverTime, 1781645000.456);
    });

    test('sends documented POST endpoints and JSON bodies', () async {
      final adapter = _RecordingResponseAdapter('{}', Headers.jsonContentType);
      final service = ApiService(dio: Dio()..httpClientAdapter = adapter);

      await service.setMode('http://192.168.1.193:8000', 'autopilot');
      await service.control('http://192.168.1.193:8000', 'forward', 0.5);
      await service.emergencyStop('http://192.168.1.193:8000');
      await service.clearEmergency('http://192.168.1.193:8000');

      expect(adapter.requests, [
        _CapturedRequest('POST', '/mode', {'mode': 'autopilot'}),
        _CapturedRequest('POST', '/control', {
          'command': 'forward',
          'speed': 0.5,
        }),
        const _CapturedRequest('POST', '/emergency-stop', null),
        const _CapturedRequest('POST', '/emergency-clear', null),
      ]);
    });
  });
}

Dio _dioRespondingWith(
  String body, {
  String contentType = Headers.textPlainContentType,
}) {
  return Dio()..httpClientAdapter = _StaticResponseAdapter(body, contentType);
}

class _StaticResponseAdapter extends _RecordingResponseAdapter {
  _StaticResponseAdapter(super.body, super.contentType);
}

class _RecordingResponseAdapter implements HttpClientAdapter {
  _RecordingResponseAdapter(this.body, this.contentType);

  final String body;
  final String contentType;
  final requests = <_CapturedRequest>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _CapturedRequest(
        options.method,
        options.path,
        await _readJsonBody(requestStream),
      ),
    );
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<Map<String, dynamic>?> _readJsonBody(
  Stream<Uint8List>? requestStream,
) async {
  if (requestStream == null) {
    return null;
  }
  final bytes = await requestStream.expand((chunk) => chunk).toList();
  if (bytes.isEmpty) {
    return null;
  }
  return (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
}

class _CapturedRequest {
  const _CapturedRequest(this.method, this.path, this.body);

  final String method;
  final String path;
  final Map<String, dynamic>? body;

  @override
  bool operator ==(Object other) {
    return other is _CapturedRequest &&
        other.method == method &&
        other.path == path &&
        _mapsEqual(other.body, body);
  }

  @override
  int get hashCode =>
      Object.hash(method, path, Object.hashAll(body?.entries ?? []));

  @override
  String toString() => '$method $path $body';
}

bool _mapsEqual(Map<String, dynamic>? left, Map<String, dynamic>? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
