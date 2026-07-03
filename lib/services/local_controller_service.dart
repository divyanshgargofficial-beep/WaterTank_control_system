import 'package:water_tank_controller/models/controller_status.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
import 'package:water_tank_controller/services/controller_service.dart';

class LocalControllerService implements ControllerService {
  LocalControllerService(this._api, this.controllerIp);

  final ControllerApiService _api;
  final String controllerIp;

  @override
  String get endpoint => 'http://$controllerIp';

  @override
  Future<ControllerStatus> fetchStatus() => _api.fetchStatus(endpoint);

  @override
  Future<void> startPump() => _api.startPump(endpoint);

  @override
  Future<void> stopPump() => _api.stopPump(endpoint);

  @override
  Future<void> resetLockout() => _api.resetLockout(endpoint);
}
