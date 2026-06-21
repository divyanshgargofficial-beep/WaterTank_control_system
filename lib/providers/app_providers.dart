import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/models/controller_snapshot.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/models/history_event.dart';
import 'package:water_tank_controller/repositories/controller_repository.dart';
import 'package:water_tank_controller/repositories/history_repository.dart';
import 'package:water_tank_controller/repositories/settings_repository.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
import 'package:water_tank_controller/services/notification_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(),
);
final dioProvider = Provider((ref) => Dio());
final apiServiceProvider = Provider(
  (ref) => ControllerApiService(ref.watch(dioProvider)),
);
final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);
final historyRepositoryProvider = Provider(
  (ref) => HistoryRepository(ref.watch(sharedPreferencesProvider)),
);
final controllerRepositoryProvider = Provider(
  (ref) => ControllerRepository(
    ref.watch(apiServiceProvider),
    ref.watch(sharedPreferencesProvider),
  ),
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
    ref.invalidate(controllerControllerProvider);
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
  Timer? _timer;
  ControllerStatus? _previousStatus;
  bool _wasOnline = false;

  @override
  ControllerSnapshot build() {
    ref.onDispose(() => _timer?.cancel());
    final cached = ref.watch(controllerRepositoryProvider).loadCachedStatus();
    _previousStatus = cached;
    _schedulePolling();
    unawaited(refresh());
    return ControllerSnapshot(status: cached, online: false, syncing: true);
  }

  void _schedulePolling() {
    _timer?.cancel();
    final settings = ref.read(settingsControllerProvider);
    _timer = Timer.periodic(
      Duration(seconds: settings.refreshIntervalSeconds),
      (_) => refresh(),
    );
  }

  Future<void> refresh() async {
    final settings = ref.read(settingsControllerProvider);
    state = state.copyWith(syncing: true, clearError: true);
    try {
      final status = await ref
          .read(controllerRepositoryProvider)
          .fetchStatus(settings.controllerIp);
      final restored = !_wasOnline;
      state = ControllerSnapshot(status: status, online: true, syncing: false);
      await _recordTransitions(_previousStatus, status, restored: restored);
      _previousStatus = status;
      _wasOnline = true;
    } catch (error) {
      if (_wasOnline) {
        await _addEvent(
          HistoryEventType.connectionLost,
          'Connection lost',
          'Controller Offline',
          'The water tank controller is unreachable.',
        );
      }
      _wasOnline = false;
      state = state.copyWith(
        online: false,
        syncing: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> startPump() async {
    await ref
        .read(controllerRepositoryProvider)
        .startPump(ref.read(settingsControllerProvider).controllerIp);
    await refresh();
  }

  Future<void> stopPump() async {
    await ref
        .read(controllerRepositoryProvider)
        .stopPump(ref.read(settingsControllerProvider).controllerIp);
    await refresh();
  }

  Future<void> resetLockout() async {
    await ref
        .read(controllerRepositoryProvider)
        .resetLockout(ref.read(settingsControllerProvider).controllerIp);
    await _addEvent(
      HistoryEventType.lockoutReset,
      'Lockout reset',
      'Lockout Reset',
      'Pump lockout has been cleared.',
    );
    await refresh();
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
          enabled: ref.read(settingsControllerProvider).notificationsEnabled,
        );
  }

  String _friendlyError(Object error) {
    if (error is DioException) return 'Unable to reach controller';
    return error.toString();
  }
}
