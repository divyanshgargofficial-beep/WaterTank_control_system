enum ConnectionMode { local, cloud }

extension ConnectionModeLabels on ConnectionMode {
  String get label {
    return switch (this) {
      ConnectionMode.local => 'Local Connection',
      ConnectionMode.cloud => 'Cloud Connection',
    };
  }
}

class ConnectionInfo {
  const ConnectionInfo({
    required this.mode,
    required this.qualityPercent,
    required this.endpoint,
    required this.switchedAt,
  });

  final ConnectionMode mode;
  final int qualityPercent;
  final String endpoint;
  final DateTime switchedAt;

  String get qualityLabel {
    if (qualityPercent >= 85) return 'Excellent';
    if (qualityPercent >= 65) return 'Good';
    if (qualityPercent >= 35) return 'Fair';
    return 'Weak';
  }
}
