import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/models/app_user.dart';
import 'package:water_tank_controller/models/connection_info.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';
import 'package:water_tank_controller/widgets/runtime_display.dart';
import 'package:water_tank_controller/widgets/status_pill.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final user = ref.watch(authControllerProvider).session!.user;
    final snapshot = ref.watch(controllerControllerProvider);
    final status = snapshot.status;
    final connection = snapshot.connection;
    final updated = status == null
        ? 'Never'
        : DateFormat('MMM d, h:mm:ss a').format(status.receivedAt);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(controllerControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Water Tank Controller',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.role.label} - ${connection?.mode.label ?? 'Connecting'}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Refresh',
                onPressed: () =>
                    ref.read(controllerControllerProvider.notifier).refresh(),
                icon: snapshot.syncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Sign out',
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          if (!snapshot.online)
            GlassCard(
              margin: const EdgeInsets.only(top: 18),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.warning),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Controller offline. Showing the last cached state.',
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(controllerControllerProvider.notifier)
                        .refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          GlassCard(
            margin: const EdgeInsets.only(top: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    StatusPill(
                      label: snapshot.online
                          ? connection?.mode.label ?? 'Online'
                          : 'Offline',
                      color: snapshot.online
                          ? AppColors.success
                          : AppColors.warning,
                      icon: snapshot.online
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      pulse: snapshot.online,
                    ),
                    StatusPill(
                      label: connection == null
                          ? 'Quality Unknown'
                          : '${connection.qualityLabel} ${connection.qualityPercent}%',
                      color: connection == null
                          ? AppColors.muted
                          : AppColors.secondary,
                      icon: Icons.network_check_rounded,
                      pulse: snapshot.online,
                    ),
                    StatusPill(
                      label: status?.pumpRunning == true
                          ? 'Pump On'
                          : 'Pump Off',
                      color: status?.pumpRunning == true
                          ? AppColors.success
                          : AppColors.muted,
                      icon: Icons.water_drop_rounded,
                      pulse: status?.pumpRunning == true,
                    ),
                    StatusPill(
                      label: status?.lockout == true ? 'Lockout' : 'Ready',
                      color: status?.lockout == true
                          ? AppColors.danger
                          : AppColors.primary,
                      icon: status?.lockout == true
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Tank Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _TankMeter(full: status?.tankFull == true),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: RuntimeDisplay(
                        label: 'Current Runtime',
                        seconds: status?.currentRuntimeSeconds ?? 0,
                        large: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RuntimeDisplay(
                        label: 'Total Runtime',
                        seconds: status?.totalRuntimeSeconds ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  label: 'Connection Mode',
                  value: connection?.mode.label ?? 'Detecting',
                ),
                _InfoRow(
                  label: 'Connection Quality',
                  value: connection == null
                      ? 'Unknown'
                      : '${connection.qualityLabel} (${connection.qualityPercent}%)',
                ),
                _InfoRow(
                  label: 'Controller Online',
                  value: snapshot.online ? 'Yes' : 'No',
                ),
                _InfoRow(
                  label: 'Live Sync',
                  value: snapshot.syncing
                      ? 'Syncing'
                      : snapshot.online
                      ? 'Live'
                      : 'Paused',
                ),
                _InfoRow(label: 'Last Updated', value: updated),
                _InfoRow(
                  label: 'Wi-Fi Reported',
                  value: status?.wifiConnected == true
                      ? 'Connected'
                      : 'Unknown',
                ),
                _InfoRow(label: 'Local IP', value: settings.controllerIp),
                _InfoRow(label: 'Cloud URL', value: settings.cloudUrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TankMeter extends StatelessWidget {
  const _TankMeter({required this.full});

  final bool full;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        color: Colors.black.withValues(alpha: 0.16),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            height: full ? 134 : 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
          ),
          Center(
            child: Text(
              full ? 'FULL' : 'FILLING / READY',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
