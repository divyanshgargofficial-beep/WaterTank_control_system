import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/models/connection_info.dart';

class ControllerSnapshot {
  const ControllerSnapshot({
    required this.status,
    required this.online,
    required this.syncing,
    required this.connection,
    this.errorMessage,
  });

  final ControllerStatus? status;
  final bool online;
  final bool syncing;
  final ConnectionInfo? connection;
  final String? errorMessage;

  ControllerSnapshot copyWith({
    ControllerStatus? status,
    bool? online,
    bool? syncing,
    ConnectionInfo? connection,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ControllerSnapshot(
      status: status ?? this.status,
      online: online ?? this.online,
      syncing: syncing ?? this.syncing,
      connection: connection ?? this.connection,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
