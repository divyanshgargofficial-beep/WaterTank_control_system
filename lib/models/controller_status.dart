class ControllerStatus {
  const ControllerStatus({
    required this.pumpRunning,
    required this.tankFull,
    required this.lockout,
    required this.currentRuntimeSeconds,
    required this.totalRuntimeSeconds,
    required this.wifiConnected,
    required this.receivedAt,
    this.deviceName,
    this.firmwareVersion,
    this.wifiRSSI,
  });

  final bool pumpRunning;
  final bool tankFull;
  final bool lockout;
  final int currentRuntimeSeconds;
  final int totalRuntimeSeconds;
  final bool wifiConnected;
  final DateTime receivedAt;
  final String? deviceName;
  final String? firmwareVersion;
  final int? wifiRSSI;

  factory ControllerStatus.fromJson(Map<String, dynamic> json) {
    return ControllerStatus(
      pumpRunning: json['pumpRunning'] == true,
      tankFull: json['tankFull'] == true,
      lockout: json['lockout'] == true,
      currentRuntimeSeconds:
          (json['currentRuntimeSeconds'] as num?)?.toInt() ?? 0,
      totalRuntimeSeconds: (json['totalRuntimeSeconds'] as num?)?.toInt() ?? 0,
      wifiConnected: json['wifiConnected'] == true,
      receivedAt:
          DateTime.tryParse('${json['receivedAt'] ?? ''}') ?? DateTime.now(),
      deviceName: _stringOrNull(json['deviceName']),
      firmwareVersion: _stringOrNull(json['firmwareVersion']),
      wifiRSSI: (json['wifiRSSI'] as num?)?.toInt(),
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
      'deviceName': deviceName,
      'firmwareVersion': firmwareVersion,
      'wifiRSSI': wifiRSSI,
    };
  }

  ControllerStatus copyWith({
    bool? pumpRunning,
    bool? tankFull,
    bool? lockout,
    int? currentRuntimeSeconds,
    int? totalRuntimeSeconds,
    bool? wifiConnected,
    DateTime? receivedAt,
    String? deviceName,
    String? firmwareVersion,
    int? wifiRSSI,
  }) {
    return ControllerStatus(
      pumpRunning: pumpRunning ?? this.pumpRunning,
      tankFull: tankFull ?? this.tankFull,
      lockout: lockout ?? this.lockout,
      currentRuntimeSeconds:
          currentRuntimeSeconds ?? this.currentRuntimeSeconds,
      totalRuntimeSeconds: totalRuntimeSeconds ?? this.totalRuntimeSeconds,
      wifiConnected: wifiConnected ?? this.wifiConnected,
      receivedAt: receivedAt ?? this.receivedAt,
      deviceName: deviceName ?? this.deviceName,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      wifiRSSI: wifiRSSI ?? this.wifiRSSI,
    );
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
      deviceName: _stringOrNull(json['deviceName']),
      firmwareVersion: _stringOrNull(json['firmwareVersion']),
      wifiRSSI: (json['wifiRSSI'] as num?)?.toInt(),
    );
  }

  static String? _stringOrNull(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }
}
