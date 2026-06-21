import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_controller/models/history_event.dart';

class HistoryRepository {
  HistoryRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'historyEvents';

  List<HistoryEvent> load() {
    final raw = _prefs.getStringList(_key) ?? [];
    return raw
        .map(
          (item) =>
              HistoryEvent.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<List<HistoryEvent>> add(HistoryEvent event) async {
    final events = [event, ...load()].take(150).toList();
    await _prefs.setStringList(
      _key,
      events.map((item) => jsonEncode(item.toJson())).toList(),
    );
    return events;
  }

  Future<void> clear() => _prefs.remove(_key);
}
