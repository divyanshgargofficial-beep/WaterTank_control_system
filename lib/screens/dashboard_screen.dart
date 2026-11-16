import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';
import 'package:water_tank_controller/widgets/runtime_display.dart';
import 'package:water_tank_controller/widgets/status_pill.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(controllerControllerProvider);
    final status = snapshot.status;
    final connection = snapshot.connection;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Water Tank Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(controllerControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(controllerControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Row(
                children: [
                  Icon(
                    snapshot.online ? Icons.wifi : Icons.wifi_off,
                    color: snapshot.online
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.online ? 'Online' : 'Offline / Reconnecting',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: snapshot.online
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        if (connection != null)
                          Text(
                            connection.label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (snapshot.syncing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Telemetry',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(
                        label: 'Pump: ${status?.pumpRunning == true ? "RUNNING" : "STOPPED"}',
                        active: status?.pumpRunning == true,
                        activeColor: AppColors.primaryLight,
                      ),
                      StatusPill(
                        label: 'Tank: ${status?.tankFull == true ? "FULL" : "FILLING"}',
                        active: status?.tankFull == true,
                        activeColor: AppColors.accent,
                      ),
                      StatusPill(
                        label: 'Lockout: ${status?.lockout == true ? "ACTIVE" : "INACTIVE"}',
                        active: status?.lockout == true,
                        activeColor: AppColors.error,
                      ),
                      StatusPill(
                        label: 'Wi-Fi: ${status?.wifiConnected == true ? "CONNECTED" : "DISCONNECTED"}',
                        active: status?.wifiConnected == true,
                        activeColor: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: RuntimeDisplay(
                          label: 'Session Runtime',
                          seconds: status?.currentRuntimeSeconds ?? 0,
                          isLive: status?.pumpRunning == true,
                        ),
                      ),
                      Expanded(
                        child: RuntimeDisplay(
                          label: 'Total Lifetime Run',
                          seconds: status?.totalRuntimeSeconds ?? 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
