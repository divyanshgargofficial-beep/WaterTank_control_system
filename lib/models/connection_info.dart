enum ConnectionMode { local, cloud, disconnected }

class ConnectionInfo {
  const ConnectionInfo({
    required this.mode,
    required this.endpoint,
    required this.latencyMs,
    this.statusMessage,
  });

  final ConnectionMode mode;
  final String endpoint;
  final int latencyMs;
  final String? statusMessage;

  String get label => switch (mode) {
    ConnectionMode.local => 'Local Wi-Fi ($endpoint)',
    ConnectionMode.cloud => 'Render Cloud ($endpoint)',
    ConnectionMode.disconnected => 'Offline',
  };
}
