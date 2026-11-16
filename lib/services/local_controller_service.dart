import 'package:water_tank_controller/models/connection_info.dart';
import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
import 'package:water_tank_controller/services/controller_service.dart';

class LocalControllerService implements ControllerService {
  LocalControllerService(this._api, this._ip);

  final ControllerApiService _api;
  final String _ip;

  @override
  Future<({ControllerStatus status, ConnectionInfo connection})> fetchStatus() =>
      _api.getStatus(_ip);

  @override
  Future<void> startPump() => _api.startPump(_ip);

  @override
  Future<void> stopPump() => _api.stopPump(_ip);

  @override
  Future<void> resetLockout() => _api.resetLockout(_ip);
}
