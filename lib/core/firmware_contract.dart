class FirmwareContract {
  FirmwareContract._();

  static const defaultControllerIp = '192.168.1.13';
  static const statusPath = '/api/status';
  static const startPumpPath = '/api/pump/on';
  static const stopPumpPath = '/api/pump/off';
  static const resetLockoutPath = '/api/pump/reset';

  static const statusFields = [
    'pumpRunning',
    'tankFull',
    'lockout',
    'currentRuntimeSeconds',
    'totalRuntimeSeconds',
    'wifiConnected',
  ];
}
