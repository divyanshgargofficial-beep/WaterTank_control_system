enum HistoryEventType {
  pumpStarted,
  pumpStopped,
  tankFull,
  lockoutActivated,
  lockoutReset,
  connectionRestored,
  connectionLost,
  cloudConnected,
  cloudDisconnected,
}

class HistoryEvent {
  const HistoryEvent({
    required this.type,
    required this.timestamp,
    required this.message,
    this.runtimeSeconds = 0,
  });

  final HistoryEventType type;
  final DateTime timestamp;
  final String message;
  final int runtimeSeconds;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'runtimeSeconds': runtimeSeconds,
    };
  }

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      type: HistoryEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HistoryEventType.pumpStopped,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String,
      runtimeSeconds: (json['runtimeSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
