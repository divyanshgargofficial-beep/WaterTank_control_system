class ControllerStatus {
  const ControllerStatus({
    required this.pumpRunning,
    required this.tankFull,
    required this.lockout,
    required this.currentRuntimeSeconds,
    required this.totalRuntimeSeconds,
    required this.wifiConnected,
    required this.receivedAt,
  });

  final bool pumpRunning;
  final bool tankFull;
  final bool lockout;
  final int currentRuntimeSeconds;
  final int totalRuntimeSeconds;
  final bool wifiConnected;
  final DateTime receivedAt;

  factory ControllerStatus.fromJson(Map<String, dynamic> json) {
    return ControllerStatus(
      pumpRunning: json['pumpRunning'] == true,
      tankFull: json['tankFull'] == true,
      lockout: json['lockout'] == true,
      currentRuntimeSeconds:
          (json['currentRuntimeSeconds'] as num?)?.toInt() ?? 0,
      totalRuntimeSeconds: (json['totalRuntimeSeconds'] as num?)?.toInt() ?? 0,
      wifiConnected: json['wifiConnected'] == true,
      receivedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pumpRunning': pumpRunning,
      'tankFull': tankFull,
      'lockout': lockout,
      'currentRuntimeSeconds': currentRuntimeSeconds,
      'totalRuntimeSeconds': totalRuntimeSeconds,
      'wifiConnected': wifiConnected,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }

  factory ControllerStatus.fromCache(Map<String, dynamic> json) {
    return ControllerStatus(
      pumpRunning: json['pumpRunning'] == true,
      tankFull: json['tankFull'] == true,
      lockout: json['lockout'] == true,
      currentRuntimeSeconds:
          (json['currentRuntimeSeconds'] as num?)?.toInt() ?? 0,
      totalRuntimeSeconds: (json['totalRuntimeSeconds'] as num?)?.toInt() ?? 0,
      wifiConnected: json['wifiConnected'] == true,
      receivedAt: DateTime.tryParse('${json['receivedAt']}') ?? DateTime.now(),
    );
  }
}
