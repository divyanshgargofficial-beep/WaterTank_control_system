import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/models/history_event.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/utils/time_formatters.dart';
import 'package:water_tank_controller/widgets/empty_state.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(historyControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'History',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (events.isNotEmpty)
                IconButton(
                  tooltip: 'Clear history',
                  onPressed: () =>
                      ref.read(historyControllerProvider.notifier).clear(),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? const EmptyState(
                  icon: Icons.timeline_rounded,
                  title: 'No events yet',
                  subtitle:
                      'Pump, lockout, tank, and connection events will appear here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  itemCount: events.length,
                  itemBuilder: (context, index) => _TimelineTile(
                    event: events[index],
                    isLast: index == events.length - 1,
                  ),
                ),
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});

  final HistoryEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.type);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.message,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat(
                      'MMM d, yyyy - h:mm:ss a',
                    ).format(event.timestamp),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  if (event.runtimeSeconds > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Runtime: ${formatDurationSeconds(event.runtimeSeconds)}',
                      style: TextStyle(color: color),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _eventColor(HistoryEventType type) {
    return switch (type) {
      HistoryEventType.pumpStarted => AppColors.success,
      HistoryEventType.pumpStopped => AppColors.danger,
      HistoryEventType.tankFull => AppColors.primary,
      HistoryEventType.lockoutActivated => AppColors.warning,
      HistoryEventType.lockoutReset => AppColors.secondary,
      HistoryEventType.connectionLost => AppColors.warning,
      HistoryEventType.connectionRestored => AppColors.success,
    };
  }
}
