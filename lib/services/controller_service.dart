import 'package:water_tank_controller/models/connection_info.dart';
import 'package:water_tank_controller/models/controller_status.dart';

abstract interface class ControllerService {
  Future<({ControllerStatus status, ConnectionInfo connection})> fetchStatus();
  Future<void> startPump();
  Future<void> stopPump();
  Future<void> resetLockout();
}
