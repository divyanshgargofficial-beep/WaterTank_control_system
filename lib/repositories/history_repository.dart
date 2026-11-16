import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/models/history_event.dart';

class HistoryRepository {
  HistoryRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _historyKey = 'controller.history.v1';
  static const _maxEvents = 100;

  List<HistoryEvent> load() {
    final raw = _preferences.getStringList(_historyKey);
    if (raw == null) return [];
    return raw
        .map((item) => HistoryEvent.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<List<HistoryEvent>> add(HistoryEvent event) async {
    final current = load();
    final updated = [event, ...current].take(_maxEvents).toList();
    await _preferences.setStringList(
      _historyKey,
      updated.map((item) => jsonEncode(item.toJson())).toList(),
    );
    return updated;
  }

  Future<void> clear() async {
    await _preferences.remove(_historyKey);
  }
}
