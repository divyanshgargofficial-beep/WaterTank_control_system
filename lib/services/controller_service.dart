import 'package:water_tank_controller/models/controller_status.dart';

abstract class ControllerService {
  String get endpoint;

  Future<ControllerStatus> fetchStatus();
  Future<void> startPump();
  Future<void> stopPump();
  Future<void> resetLockout();
}
