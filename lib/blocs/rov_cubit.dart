import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/constants.dart';
import '../core/url_helper.dart';
import '../models/health_status.dart';
import '../models/rov_status.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum StartupDestination { loading, setup, dashboard }

enum ConnectionStateKind { connecting, online, offline, serverError }

class RovState {
  const RovState({
    this.startupDestination = StartupDestination.loading,
    this.connectionState = ConnectionStateKind.connecting,
    this.baseUrl,
    this.lastSavedBaseUrl,
    this.setupError,
    this.dashboardError,
    this.status,
    this.health,
    this.isConnecting = false,
    this.isSendingCommand = false,
    this.isPolling = false,
  });

  final StartupDestination startupDestination;
  final ConnectionStateKind connectionState;
  final String? baseUrl;
  final String? lastSavedBaseUrl;
  final String? setupError;
  final String? dashboardError;
  final RovStatus? status;
  final HealthStatus? health;
  final bool isConnecting;
  final bool isSendingCommand;
  final bool isPolling;

  String get videoUrl => baseUrl == null ? '' : '$baseUrl/video';

  bool get canUseManualControls =>
      connectionState == ConnectionStateKind.online &&
      status?.vehicle.mode == 'manual' &&
      status?.vehicle.emergencyStop != true &&
      !isSendingCommand;

  RovState copyWith({
    StartupDestination? startupDestination,
    ConnectionStateKind? connectionState,
    String? baseUrl,
    String? lastSavedBaseUrl,
    String? setupError,
    String? dashboardError,
    RovStatus? status,
    HealthStatus? health,
    bool? isConnecting,
    bool? isSendingCommand,
    bool? isPolling,
    bool clearBaseUrl = false,
    bool clearSetupError = false,
    bool clearDashboardError = false,
    bool clearStatus = false,
    bool clearHealth = false,
  }) {
    return RovState(
      startupDestination: startupDestination ?? this.startupDestination,
      connectionState: connectionState ?? this.connectionState,
      baseUrl: clearBaseUrl ? null : baseUrl ?? this.baseUrl,
      lastSavedBaseUrl: lastSavedBaseUrl ?? this.lastSavedBaseUrl,
      setupError: clearSetupError ? null : setupError ?? this.setupError,
      dashboardError: clearDashboardError
          ? null
          : dashboardError ?? this.dashboardError,
      status: clearStatus ? null : status ?? this.status,
      health: clearHealth ? null : health ?? this.health,
      isConnecting: isConnecting ?? this.isConnecting,
      isSendingCommand: isSendingCommand ?? this.isSendingCommand,
      isPolling: isPolling ?? this.isPolling,
    );
  }
}

class RovCubit extends Cubit<RovState> {
  RovCubit({
    ApiService? api,
    StorageService? preferences,
    Connectivity? connectivity,
  }) : _api = api ?? ApiService(),
       _preferences = preferences ?? StorageService(),
       _connectivity = connectivity ?? Connectivity(),
       super(const RovState());

  static const pollInterval = ApiConstants.pollInterval;

  final ApiService _api;
  final StorageService _preferences;
  final Connectivity _connectivity;

  bool _activeMovement = false;
  Timer? _pollTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  StartupDestination get startupDestination => state.startupDestination;
  ConnectionStateKind get connectionState => state.connectionState;
  String? get baseUrl => state.baseUrl;
  String? get lastSavedBaseUrl => state.lastSavedBaseUrl;
  String? get setupError => state.setupError;
  String? get dashboardError => state.dashboardError;
  RovStatus? get status => state.status;
  HealthStatus? get health => state.health;
  bool get isConnecting => state.isConnecting;
  bool get isSendingCommand => state.isSendingCommand;
  bool get isPolling => state.isPolling;
  String get videoUrl => state.videoUrl;
  bool get canUseManualControls => state.canUseManualControls;

  Future<void> bootstrap() async {
    _safeEmit(
      state.copyWith(
        startupDestination: StartupDestination.loading,
        connectionState: ConnectionStateKind.connecting,
      ),
    );

    final saved = await _preferences.loadBaseUrl();
    if (saved == null || saved.isEmpty) {
      _safeEmit(
        state.copyWith(
          startupDestination: StartupDestination.setup,
          connectionState: ConnectionStateKind.offline,
          lastSavedBaseUrl: saved,
        ),
      );
      return;
    }

    _safeEmit(
      state.copyWith(
        baseUrl: saved,
        lastSavedBaseUrl: saved,
        startupDestination: StartupDestination.dashboard,
        connectionState: ConnectionStateKind.online,
        clearSetupError: true,
        clearDashboardError: true,
        clearHealth: true,
      ),
    );
    startMonitoring();
  }

  Future<bool> connect(String rawAddress) async {
    _safeEmit(
      state.copyWith(
        isConnecting: true,
        connectionState: ConnectionStateKind.connecting,
        clearSetupError: true,
      ),
    );

    try {
      final normalized = UrlHelper.normalizeBaseUrl(rawAddress);
      await _preferences.saveBaseUrl(normalized);
      _safeEmit(
        state.copyWith(
          baseUrl: normalized,
          lastSavedBaseUrl: normalized,
          startupDestination: StartupDestination.dashboard,
          connectionState: ConnectionStateKind.online,
          isConnecting: false,
          clearSetupError: true,
          clearDashboardError: true,
          clearHealth: true,
        ),
      );
      startMonitoring();
      return true;
    } on FormatException catch (error) {
      _safeEmit(
        state.copyWith(
          setupError: error.message,
          connectionState: ConnectionStateKind.serverError,
          isConnecting: false,
        ),
      );
      return false;
    } catch (_) {
      _safeEmit(
        state.copyWith(
          setupError:
              'Unable to connect to the ROV server. Make sure the Raspberry Pi is powered on and both devices are connected to the same Wi-Fi network.',
          connectionState: ConnectionStateKind.offline,
          isConnecting: false,
        ),
      );
      return false;
    }
  }

  void startMonitoring() {
    _pollTimer?.cancel();
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        _markDisconnected('Phone network connection is unavailable.');
      } else if (state.baseUrl != null) {
        refreshStatus();
      }
    });
    refreshStatus();
  }

  Future<void> refreshStatus() async {
    final baseUrl = state.baseUrl;
    if (state.isPolling || baseUrl == null) {
      return;
    }

    _safeEmit(
      state.copyWith(
        isPolling: true,
        connectionState: state.status == null
            ? ConnectionStateKind.connecting
            : state.connectionState,
      ),
    );

    try {
      final next = await _api.status(baseUrl);
      _safeEmit(
        state.copyWith(
          status: next,
          connectionState: ConnectionStateKind.online,
          isPolling: false,
          clearDashboardError: true,
        ),
      );
    } catch (_) {
      await _stopIfMoving();
      _markDisconnected('Server connection lost.');
      _safeEmit(state.copyWith(isPolling: false));
    } finally {
      if (!isClosed && state.baseUrl != null) {
        _pollTimer?.cancel();
        _pollTimer = Timer(pollInterval, refreshStatus);
      }
    }
  }

  Future<void> setMode(String mode) async {
    final baseUrl = state.baseUrl;
    if (baseUrl == null || state.isSendingCommand) {
      return;
    }
    _safeEmit(state.copyWith(isSendingCommand: true));
    try {
      if (mode == 'manual') {
        await _api.control(baseUrl, 'stop', 0);
      }
      await _api.setMode(baseUrl, mode);
      if (mode != 'manual') {
        await _api.control(baseUrl, 'stop', 0);
      }
      _activeMovement = false;
      await refreshStatus();
    } catch (_) {
      await _stopIfMoving();
      _safeEmit(state.copyWith(dashboardError: 'Mode change failed.'));
    } finally {
      _safeEmit(state.copyWith(isSendingCommand: false));
    }
  }

  Future<void> startMovement(String command, {double speed = 0.5}) async {
    final baseUrl = state.baseUrl;
    if (!state.canUseManualControls || baseUrl == null) {
      return;
    }
    _activeMovement = true;
    _safeEmit(state.copyWith(isSendingCommand: true));
    try {
      await _api.control(baseUrl, command, speed);
      await refreshStatus();
    } catch (_) {
      _safeEmit(state.copyWith(dashboardError: 'Movement command failed.'));
      await stopMovement(force: true);
    } finally {
      _safeEmit(state.copyWith(isSendingCommand: false));
    }
  }

  Future<void> stopMovement({bool force = false}) async {
    final baseUrl = state.baseUrl;
    if (baseUrl == null || (!_activeMovement && !force)) {
      return;
    }
    _activeMovement = false;
    try {
      await _api.control(baseUrl, 'stop', 0);
      await refreshStatus();
    } catch (_) {
      _markDisconnected('Server connection lost.');
      _safeEmit(
        state.copyWith(
          dashboardError: 'Stop command failed. Check the ROV connection.',
        ),
      );
    }
  }

  Future<void> emergencyStop() async {
    final baseUrl = state.baseUrl;
    if (baseUrl == null) {
      return;
    }
    _activeMovement = false;
    _safeEmit(state.copyWith(isSendingCommand: true));
    try {
      HapticFeedback.heavyImpact();
      await _api.emergencyStop(baseUrl);
      await refreshStatus();
    } catch (_) {
      _markDisconnected('Server connection lost.');
      _safeEmit(
        state.copyWith(
          dashboardError:
              'Emergency stop failed. Check the ROV connection immediately.',
        ),
      );
    } finally {
      _safeEmit(state.copyWith(isSendingCommand: false));
    }
  }

  Future<void> clearEmergency() async {
    final baseUrl = state.baseUrl;
    if (baseUrl == null) {
      return;
    }
    _safeEmit(state.copyWith(isSendingCommand: true));
    try {
      await _api.clearEmergency(baseUrl);
      await refreshStatus();
    } catch (_) {
      _safeEmit(
        state.copyWith(dashboardError: 'Unable to clear emergency stop.'),
      );
    } finally {
      _safeEmit(state.copyWith(isSendingCommand: false));
    }
  }

  Future<void> changeServer() async {
    await shutdownDashboard(stopVehicle: true);
    _safeEmit(state.copyWith(startupDestination: StartupDestination.setup));
  }

  Future<void> shutdownDashboard({bool stopVehicle = true}) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (stopVehicle) {
      await _stopIfMoving(force: true);
    }
  }

  void handleAppLifecycle(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.detached ||
        lifecycleState == AppLifecycleState.hidden) {
      _stopIfMoving(force: true);
    }
  }

  Future<void> _stopIfMoving({bool force = false}) async {
    final baseUrl = state.baseUrl;
    if (baseUrl == null || (!_activeMovement && !force)) {
      return;
    }
    _activeMovement = false;
    try {
      await _api.control(baseUrl, 'stop', 0);
    } catch (_) {
      // A lost link is already surfaced by the caller.
    }
  }

  void _markDisconnected(String message) {
    _safeEmit(
      state.copyWith(
        connectionState: ConnectionStateKind.offline,
        dashboardError: message,
      ),
    );
  }

  void _safeEmit(RovState nextState) {
    if (!isClosed) {
      emit(nextState);
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }
}
