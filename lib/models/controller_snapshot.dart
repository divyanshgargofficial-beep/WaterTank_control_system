import 'package:water_tank_controller/models/controller_status.dart';

class ControllerSnapshot {
  const ControllerSnapshot({
    required this.status,
    required this.online,
    required this.syncing,
    this.errorMessage,
  });

  final ControllerStatus? status;
  final bool online;
  final bool syncing;
  final String? errorMessage;

  ControllerSnapshot copyWith({
    ControllerStatus? status,
    bool? online,
    bool? syncing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ControllerSnapshot(
      status: status ?? this.status,
      online: online ?? this.online,
      syncing: syncing ?? this.syncing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
