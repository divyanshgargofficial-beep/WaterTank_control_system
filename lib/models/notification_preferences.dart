import 'package:water_tank_controller/models/app_user.dart';
import 'package:water_tank_controller/models/history_event.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.masterEnabled,
    required this.adminEnabled,
    required this.familyEnabled,
  });

  final bool masterEnabled;
  final bool adminEnabled;
  final bool familyEnabled;

  bool allows(UserRole role, HistoryEventType type) {
    if (!masterEnabled) return false;
    if (role == UserRole.administrator && !adminEnabled) return false;
    if (role == UserRole.familyMember && !familyEnabled) return false;
    return true;
  }
}
