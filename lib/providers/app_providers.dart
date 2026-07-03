import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/models/app_user.dart';
import 'package:water_tank_controller/models/auth_state.dart';
import 'package:water_tank_controller/models/controller_snapshot.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/models/history_event.dart';
import 'package:water_tank_controller/models/notification_preferences.dart';
import 'package:water_tank_controller/repositories/auth_repository.dart';
import 'package:water_tank_controller/repositories/controller_repository.dart';
import 'package:water_tank_controller/repositories/history_repository.dart';
import 'package:water_tank_controller/repositories/settings_repository.dart';
import 'package:water_tank_controller/services/connection_manager.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
import 'package:water_tank_controller/services/notification_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(),
);
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);
final dioProvider = Provider((ref) {
  final settings = ref.watch(settingsControllerProvider);
  final timeout = Duration(seconds: settings.connectionTimeoutSeconds);
  return Dio(
    BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: const {
        Headers.acceptHeader: 'application/json',
        'connection': 'close',
      },
    ),
  );
});
final apiServiceProvider = Provider(
  (ref) => ControllerApiService(ref.watch(dioProvider)),
);
final connectionManagerProvider = Provider(
  (ref) => ConnectionManager(ref.watch(apiServiceProvider)),
);
final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(secureStorageProvider)),
);
final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);
final historyRepositoryProvider = Provider(
  (ref) => HistoryRepository(ref.watch(sharedPreferencesProvider)),
);
final controllerRepositoryProvider = Provider(
  (ref) => ControllerRepository(
    ref.watch(connectionManagerProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
final historyControllerProvider =
    NotifierProvider<HistoryController, List<HistoryEvent>>(
      HistoryController.new,
    );
final controllerControllerProvider =
    NotifierProvider<ControllerController, ControllerSnapshot>(
      ControllerController.new,
    );

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(AppSettings settings) async {
    state = settings;
    await ref.read(settingsRepositoryProvider).save(settings);
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(_restore());
    return const AuthState.loading();
  }

  Future<void> _restore() async {
    final repository = ref.read(authRepositoryProvider);
    final session = await repository.restoreSession();
    final users = await repository.loadUsers();
    state = AuthState(loading: false, users: users, session: session);
  }

  Future<void> login(String userId, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(userId, password);
      final users = await ref.read(authRepositoryProvider).loadUsers();
      state = AuthState(loading: false, users: users, session: session);
    } catch (error) {
      final users = await ref.read(authRepositoryProvider).loadUsers();
      state = AuthState(
        loading: false,
        users: users,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    final users = await ref.read(authRepositoryProvider).loadUsers();
    state = AuthState(loading: false, users: users);
  }

  Future<void> changePassword(String userId, String password) async {
    await ref.read(authRepositoryProvider).changePassword(userId, password);
    final users = await ref.read(authRepositoryProvider).loadUsers();
    state = state.copyWith(users: users);
  }

  Future<void> addUser({
    required String name,
    required UserRole role,
    required String password,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .addUser(name: name, role: role, password: password);
    final users = await ref.read(authRepositoryProvider).loadUsers();
    state = state.copyWith(users: users);
  }

  Future<void> removeUser(String userId) async {
    await ref.read(authRepositoryProvider).removeUser(userId);
    final users = await ref.read(authRepositoryProvider).loadUsers();
    state = state.copyWith(users: users);
  }
}

class HistoryController extends Notifier<List<HistoryEvent>> {
  @override
  List<HistoryEvent> build() => ref.watch(historyRepositoryProvider).load();

  Future<void> add(HistoryEvent event) async {
    state = await ref.read(historyRepositoryProvider).add(event);
  }

  Future<void> clear() async {
    await ref.read(historyRepositoryProvider).clear();
    state = [];
  }
}

class ControllerController extends Notifier<ControllerSnapshot> {
  static const _offlineFailureThreshold = 3;

  Timer? _timer;
  ControllerStatus? _previousStatus;
  bool _wasOnline = false;
  bool _requestInFlight = false;
  bool _refreshQueued = false;
  bool _commandInFlight = false;
  int _consecutiveFailures = 0;
  bool _disposed = false;

  @override
  ControllerSnapshot build() {
    debugPrint('[ControllerPolling] provider created');
    ref.onDispose(() {
      debugPrint('[ControllerPolling] provider disposed');
      _disposed = true;
      _timer?.cancel();
    });
    final cached = ref.watch(controllerRepositoryProvider).loadCachedStatus();
    _previousStatus = cached;
    unawaited(Future<void>.microtask(() => refresh(reason: 'initial')));
    return ControllerSnapshot(
      status: cached,
      online: false,
      syncing: true,
      connection: null,
    );
  }

  void _scheduleNextPoll() {
    if (_disposed) return;
    _timer?.cancel();
    final settings = ref.read(settingsControllerProvider);
    final interval = Duration(
      seconds: settings.refreshIntervalSeconds.clamp(3, 15),
    );
    debugPrint('[ControllerPolling] next poll in ${interval.inSeconds}s');
    _timer = Timer(interval, () => unawaited(refresh(reason: 'timer')));
  }

  Future<void> refresh({String reason = 'manual'}) async {
    if (_commandInFlight) {
      debugPrint(
        '[ControllerPolling] skipped refresh while command is in flight ($reason)',
      );
      _refreshQueued = true;
      return;
    }
    if (_requestInFlight) {
      debugPrint(
        '[ControllerPolling] skipped duplicate refresh; request already in flight ($reason)',
      );
      _refreshQueued = true;
      return;
    }

    _timer?.cancel();
    _requestInFlight = true;
    final settings = ref.read(settingsControllerProvider);
    debugPrint(
      '[ControllerPolling] request start reason=$reason ip=${settings.controllerIp}',
    );

    state = state.copyWith(syncing: true, clearError: true);
    try {
      final result = await ref
          .read(controllerRepositoryProvider)
          .fetchStatus(settings);
      final status = result.status;
      if (_disposed) return;
      debugPrint(
        '[ControllerPolling] request success mode=${result.connection.mode.name}',
      );
      _consecutiveFailures = 0;
      final restored = !_wasOnline;
      state = ControllerSnapshot(
        status: status,
        online: true,
        syncing: false,
        connection: result.connection,
      );
      await _recordTransitions(_previousStatus, status, restored: restored);
      _previousStatus = status;
      if (!_wasOnline) {
        debugPrint('[ControllerPolling] online transition');
      }
      _wasOnline = true;
    } catch (error) {
      if (_disposed) return;
      _consecutiveFailures++;
      debugPrint(
        '[ControllerPolling] request failure count=$_consecutiveFailures error=$error',
      );
      final shouldGoOffline = _consecutiveFailures >= _offlineFailureThreshold;
      if (_wasOnline && shouldGoOffline) {
        debugPrint('[ControllerPolling] offline transition');
        await _addEvent(
          HistoryEventType.connectionLost,
          'Connection lost',
          'Controller Offline',
          'The water tank controller is unreachable.',
        );
      }
      if (shouldGoOffline) {
        _wasOnline = false;
      }
      state = state.copyWith(
        online: shouldGoOffline ? false : state.online,
        syncing: false,
        errorMessage: _friendlyError(error),
      );
    } finally {
      _requestInFlight = false;
      if (_disposed) {
        _refreshQueued = false;
      } else if (_refreshQueued) {
        _refreshQueued = false;
        unawaited(refresh(reason: 'queued'));
      } else {
        _scheduleNextPoll();
      }
    }
  }

  Future<void> startPump() async {
    await _runCommand(
      label: 'startPump',
      command: (settings) =>
          ref.read(controllerRepositoryProvider).startPump(settings),
    );
  }

  Future<void> stopPump() async {
    await _runCommand(
      label: 'stopPump',
      command: (settings) =>
          ref.read(controllerRepositoryProvider).stopPump(settings),
    );
  }

  Future<void> resetLockout() async {
    await _runCommand(
      label: 'resetLockout',
      command: (settings) =>
          ref.read(controllerRepositoryProvider).resetLockout(settings),
    );
    await _addEvent(
      HistoryEventType.lockoutReset,
      'Lockout reset',
      'Lockout Reset',
      'Pump lockout has been cleared.',
    );
  }

  Future<void> _runCommand({
    required String label,
    required Future<void> Function(AppSettings settings) command,
  }) async {
    _timer?.cancel();
    _commandInFlight = true;
    debugPrint('[ControllerPolling] command start $label');
    try {
      await _waitForIdleStatusRequest();
      await command(ref.read(settingsControllerProvider));
      debugPrint('[ControllerPolling] command success $label');
    } catch (error) {
      debugPrint('[ControllerPolling] command failure $label error=$error');
      rethrow;
    } finally {
      _commandInFlight = false;
      await refresh(reason: label);
    }
  }

  Future<void> _waitForIdleStatusRequest() async {
    const maxWait = Duration(seconds: 6);
    const step = Duration(milliseconds: 100);
    final started = DateTime.now();
    while (_requestInFlight && DateTime.now().difference(started) < maxWait) {
      await Future<void>.delayed(step);
    }
    if (_requestInFlight) {
      throw StateError('Timed out waiting for the active status request.');
    }
  }

  Future<void> _recordTransitions(
    ControllerStatus? previous,
    ControllerStatus current, {
    required bool restored,
  }) async {
    if (restored) {
      await _addEvent(
        HistoryEventType.connectionRestored,
        'Connection restored',
        'Controller Online',
        'Live sync with the controller is restored.',
      );
    }
    if (previous == null) return;
    if (!previous.pumpRunning && current.pumpRunning) {
      await _addEvent(
        HistoryEventType.pumpStarted,
        'Pump started',
        'Pump Started',
        'Water pump is now running.',
      );
    }
    if (previous.pumpRunning && !current.pumpRunning) {
      await _addEvent(
        HistoryEventType.pumpStopped,
        'Pump stopped',
        'Pump Stopped',
        'Water pump has stopped.',
        runtimeSeconds: current.currentRuntimeSeconds,
      );
    }
    if (!previous.tankFull && current.tankFull) {
      await _addEvent(
        HistoryEventType.tankFull,
        'Tank full',
        'Tank Full',
        'The tank full condition is active.',
      );
    }
    if (!previous.lockout && current.lockout) {
      await _addEvent(
        HistoryEventType.lockoutActivated,
        'Lockout activated',
        'Lockout Activated',
        'Pump start is locked until reset.',
      );
    }
  }

  Future<void> _addEvent(
    HistoryEventType type,
    String message,
    String title,
    String body, {
    int runtimeSeconds = 0,
  }) async {
    await ref
        .read(historyControllerProvider.notifier)
        .add(
          HistoryEvent(
            type: type,
            timestamp: DateTime.now(),
            message: message,
            runtimeSeconds: runtimeSeconds,
          ),
        );
    await ref
        .read(notificationServiceProvider)
        .show(
          id: type.index,
          title: title,
          body: body,
          enabled: _notificationsAllowed(type),
        );
  }

  bool _notificationsAllowed(HistoryEventType type) {
    final settings = ref.read(settingsControllerProvider);
    final user = ref.read(authControllerProvider).session?.user;
    final role = user?.role ?? UserRole.administrator;
    return NotificationPreferences(
      masterEnabled: settings.notificationsEnabled,
      adminEnabled: settings.adminNotificationsEnabled,
      familyEnabled: settings.familyNotificationsEnabled,
    ).allows(role, type);
  }

  String _friendlyError(Object error) {
    if (error is DioException) return 'Unable to reach controller';
    return error.toString();
  }
}
