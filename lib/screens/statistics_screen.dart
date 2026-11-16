import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/utils/time_formatters.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(controllerControllerProvider).status;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Pump Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Runtime Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Current Session Runtime'),
                  trailing: Text(
                    TimeFormatters.formatSeconds(
                      status?.currentRuntimeSeconds ?? 0,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Lifetime Total Pump Runtime'),
                  trailing: Text(
                    TimeFormatters.formatSeconds(
                      status?.totalRuntimeSeconds ?? 0,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
