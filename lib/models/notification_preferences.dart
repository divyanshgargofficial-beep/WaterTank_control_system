import 'package:water_tank_controller/models/app_user.dart';
import 'package:water_tank_controller/models/history_event.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.adminEnabled,
    required this.familyEnabled,
    required this.masterEnabled,
  });

  final bool adminEnabled;
  final bool familyEnabled;
  final bool masterEnabled;

  bool allows(UserRole role, HistoryEventType type) {
    if (!masterEnabled) return false;
    if (role == UserRole.administrator) return adminEnabled;
    if (!familyEnabled) return false;
    return switch (type) {
      HistoryEventType.tankFull ||
      HistoryEventType.connectionLost ||
      HistoryEventType.connectionRestored ||
      HistoryEventType.cloudConnected ||
      HistoryEventType.cloudDisconnected ||
      HistoryEventType.pumpStarted ||
      HistoryEventType.pumpStopped => true,
      HistoryEventType.lockoutActivated ||
      HistoryEventType.lockoutReset => false,
    };
  }
}
