class ControllerStatus {
  const ControllerStatus({
    required this.pumpRunning,
    required this.tankFull,
    required this.lockout,
    required this.currentRuntimeSeconds,
    required this.totalRuntimeSeconds,
    required this.wifiConnected,
    required this.firmwareVersion,
    required this.cloudOnline,
    required this.lastCloudCommandStatusCode,
    required this.lastCloudStatusCode,
    required this.lastCloudAckStatusCode,
    required this.lastCloudCommandAgeMs,
    required this.receivedAt,
  });

  final bool pumpRunning;
  final bool tankFull;
  final bool lockout;
  final int currentRuntimeSeconds;
  final int totalRuntimeSeconds;
  final bool wifiConnected;
  final String firmwareVersion;
  final bool cloudOnline;
  final int lastCloudCommandStatusCode;
  final int lastCloudStatusCode;
  final int lastCloudAckStatusCode;
  final int lastCloudCommandAgeMs;
  final DateTime receivedAt;

  factory ControllerStatus.fromJson(
    Map<String, dynamic> json, {
    DateTime? receivedAt,
  }) {
    return ControllerStatus(
      pumpRunning: json['pumpRunning'] as bool? ?? false,
      tankFull: json['tankFull'] as bool? ?? false,
      lockout: json['lockout'] as bool? ?? false,
      currentRuntimeSeconds: (json['currentRuntimeSeconds'] as num?)?.toInt() ?? 0,
      totalRuntimeSeconds: (json['totalRuntimeSeconds'] as num?)?.toInt() ?? 0,
      wifiConnected: json['wifiConnected'] as bool? ?? false,
      firmwareVersion: json['firmwareVersion'] as String? ?? 'unknown',
      cloudOnline: json['cloudOnline'] as bool? ?? false,
      lastCloudCommandStatusCode:
          (json['lastCloudCommandStatusCode'] as num?)?.toInt() ?? 0,
      lastCloudStatusCode: (json['lastCloudStatusCode'] as num?)?.toInt() ?? 0,
      lastCloudAckStatusCode:
          (json['lastCloudAckStatusCode'] as num?)?.toInt() ?? 0,
      lastCloudCommandAgeMs:
          (json['lastCloudCommandAgeMs'] as num?)?.toInt() ?? 0,
      receivedAt: receivedAt ?? DateTime.now(),
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
      'firmwareVersion': firmwareVersion,
      'cloudOnline': cloudOnline,
      'lastCloudCommandStatusCode': lastCloudCommandStatusCode,
      'lastCloudStatusCode': lastCloudStatusCode,
      'lastCloudAckStatusCode': lastCloudAckStatusCode,
      'lastCloudCommandAgeMs': lastCloudCommandAgeMs,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }

  ControllerStatus copyWith({
    bool? pumpRunning,
    bool? tankFull,
    bool? lockout,
    int? currentRuntimeSeconds,
    int? totalRuntimeSeconds,
    bool? wifiConnected,
    String? firmwareVersion,
    bool? cloudOnline,
    int? lastCloudCommandStatusCode,
    int? lastCloudStatusCode,
    int? lastCloudAckStatusCode,
    int? lastCloudCommandAgeAgeMs,
    DateTime? receivedAt,
  }) {
    return ControllerStatus(
      pumpRunning: pumpRunning ?? this.pumpRunning,
      tankFull: tankFull ?? this.tankFull,
      lockout: lockout ?? this.lockout,
      currentRuntimeSeconds:
          currentRuntimeSeconds ?? this.currentRuntimeSeconds,
      totalRuntimeSeconds: totalRuntimeSeconds ?? this.totalRuntimeSeconds,
      wifiConnected: wifiConnected ?? this.wifiConnected,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      cloudOnline: cloudOnline ?? this.cloudOnline,
      lastCloudCommandStatusCode:
          lastCloudCommandStatusCode ?? this.lastCloudCommandStatusCode,
      lastCloudStatusCode: lastCloudStatusCode ?? this.lastCloudStatusCode,
      lastCloudAckStatusCode:
          lastCloudAckStatusCode ?? this.lastCloudAckStatusCode,
      lastCloudCommandAgeMs:
          lastCloudCommandAgeMs ?? this.lastCloudCommandAgeMs,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}
