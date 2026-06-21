import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/models/history_event.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/utils/time_formatters.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);
    final status = ref.watch(controllerControllerProvider).status;
    final stopEvents = history
        .where(
          (event) =>
              event.type == HistoryEventType.pumpStopped &&
              event.runtimeSeconds > 0,
        )
        .toList();
    final totalTracked = stopEvents.fold<int>(
      0,
      (sum, event) => sum + event.runtimeSeconds,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Statistics',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Firmware Total',
                  value: formatDurationSeconds(
                    status?.totalRuntimeSeconds ?? 0,
                  ),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Tracked Sessions',
                  value: '${stopEvents.length}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pump Usage',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 210,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 54,
                    sections: [
                      PieChartSectionData(
                        value: ((status?.totalRuntimeSeconds ?? 0) + 1)
                            .toDouble(),
                        title: 'Run',
                        color: AppColors.primary,
                        radius: 58,
                      ),
                      PieChartSectionData(
                        value: 86400,
                        title: 'Idle',
                        color: Colors.white.withValues(alpha: 0.08),
                        radius: 48,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Runtime Trends',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _spots(stopEvents),
                        isCurved: true,
                        color: AppColors.secondary,
                        barWidth: 4,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.secondary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daily Runtime: ${formatDurationSeconds(totalTracked)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              Text(
                'Weekly Runtime: ${formatDurationSeconds(totalTracked)}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<FlSpot> _spots(List<HistoryEvent> events) {
    if (events.isEmpty) return const [FlSpot(0, 0), FlSpot(1, 0), FlSpot(2, 0)];
    final recent = events.take(7).toList().reversed.toList();
    return [
      for (var i = 0; i < recent.length; i++)
        FlSpot(i.toDouble(), recent[i].runtimeSeconds / 60),
    ];
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
