import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/models/history_event.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/widgets/empty_state.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Event Logs'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () =>
                  ref.read(historyControllerProvider.notifier).clear(),
            ),
        ],
      ),
      body: history.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No Events Yet',
              message: 'Pump runs, lockouts, and connection transitions will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final event = history[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconFor(event.type),
                          color: _colorFor(event.type),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.message,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                event.timestamp.toLocal().toString().substring(0, 19),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(HistoryEventType type) => switch (type) {
    HistoryEventType.pumpStarted => Icons.play_arrow,
    HistoryEventType.pumpStopped => Icons.stop,
    HistoryEventType.tankFull => Icons.water,
    HistoryEventType.lockoutActivated => Icons.lock,
    HistoryEventType.lockoutReset => Icons.lock_open,
    HistoryEventType.connectionRestored => Icons.cloud_done,
    HistoryEventType.connectionLost => Icons.cloud_off,
    HistoryEventType.cloudConnected => Icons.cloud,
    HistoryEventType.cloudDisconnected => Icons.cloud_queue,
  };

  Color _colorFor(HistoryEventType type) => switch (type) {
    HistoryEventType.pumpStarted => AppColors.success,
    HistoryEventType.pumpStopped => AppColors.textSecondary,
    HistoryEventType.tankFull => AppColors.accent,
    HistoryEventType.lockoutActivated => AppColors.error,
    HistoryEventType.lockoutReset => AppColors.warning,
    HistoryEventType.connectionRestored => AppColors.success,
    HistoryEventType.connectionLost => AppColors.error,
    HistoryEventType.cloudConnected => AppColors.primaryLight,
    HistoryEventType.cloudDisconnected => AppColors.textSecondary,
  };
}
