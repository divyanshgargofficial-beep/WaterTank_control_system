import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/models/app_user.dart';
import 'package:water_tank_controller/models/connection_info.dart';
import 'package:water_tank_controller/models/controller_snapshot.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
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
    final isAdmin = user.role == UserRole.administrator;
    final updated = status == null
        ? 'Never'
        : DateFormat('MMM d, h:mm:ss a').format(status.receivedAt);

    return RefreshIndicator(
      color: AppColors.secondary,
      backgroundColor: AppColors.deepSea,
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
                      'Water\nTank Control',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 0.92,
                        letterSpacing: -1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.role.label} - ${connection?.mode.label ?? 'Connecting'}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              _RoundIconButton(
                tooltip: 'Refresh',
                onPressed: () =>
                    ref.read(controllerControllerProvider.notifier).refresh(),
                child: snapshot.syncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
              ),
              const SizedBox(width: 8),
              _RoundIconButton(
                tooltip: 'Sign out',
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                child: const Icon(Icons.logout_rounded),
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
            padding: const EdgeInsets.all(22),
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
                _ConnectionPreferenceSelector(settings: settings),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tank Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      status?.tankFull == true ? 'FULL' : 'READY',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                  label: 'Device Name',
                  value: status?.deviceName ?? 'Home Water Tank',
                ),
                _InfoRow(
                  label: 'Firmware Version',
                  value: status?.firmwareVersion ?? 'Unknown',
                ),
                _InfoRow(
                  label: 'Wi-Fi Reported',
                  value: status?.wifiConnected == true
                      ? 'Connected'
                      : 'Unknown',
                ),
                _InfoRow(
                  label: 'Signal Strength',
                  value: status?.wifiRSSI == null
                      ? 'Unknown'
                      : '${status!.wifiRSSI} dBm',
                ),
                _InfoRow(label: 'Local IP', value: settings.controllerIp),
                _InfoRow(label: 'Cloud URL', value: settings.cloudUrl),
              ],
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 18),
            _DashboardControls(snapshot: snapshot),
          ],
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.12),
                blurRadius: 18,
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ConnectionPreferenceSelector extends ConsumerWidget {
  const _ConnectionPreferenceSelector({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connection Mode',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SegmentedButton<ConnectionPreference>(
          segments: const [
            ButtonSegment(
              value: ConnectionPreference.auto,
              label: Text('Auto'),
              icon: Icon(Icons.hub_rounded),
            ),
            ButtonSegment(
              value: ConnectionPreference.local,
              label: Text('Local'),
              icon: Icon(Icons.router_rounded),
            ),
            ButtonSegment(
              value: ConnectionPreference.cloud,
              label: Text('Cloud'),
              icon: Icon(Icons.cloud_rounded),
            ),
          ],
          selected: {settings.connectionPreference},
          onSelectionChanged: (value) async {
            final next = settings.copyWith(connectionPreference: value.first);
            await ref.read(settingsControllerProvider.notifier).update(next);
            ref.read(connectionManagerProvider).resetRouting();
            ref
                .read(controllerControllerProvider.notifier)
                .prepareForModeChange();
            await ref
                .read(controllerControllerProvider.notifier)
                .refresh(reason: 'mode switch');
          },
        ),
        const SizedBox(height: 8),
        Text(
          settings.connectionPreference.description,
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _DashboardControls extends ConsumerStatefulWidget {
  const _DashboardControls({required this.snapshot});

  final ControllerSnapshot snapshot;

  @override
  ConsumerState<_DashboardControls> createState() => _DashboardControlsState();
}

class _DashboardControlsState extends ConsumerState<_DashboardControls> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.snapshot.status;
    final offline = !widget.snapshot.online;
    final canStart =
        !offline && status?.pumpRunning != true && status?.lockout != true;
    final canStop = !offline && status?.pumpRunning == true;
    final canReset = !offline && status?.lockout == true;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pump Controls',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _ControlButton(
            label: 'Start Pump',
            icon: Icons.play_arrow_rounded,
            color: AppColors.success,
            enabled: canStart && !_busy,
            busy: _busy,
            onPressed: () => _run(
              () => ref.read(controllerControllerProvider.notifier).startPump(),
              'Pump started',
            ),
          ),
          const SizedBox(height: 10),
          _ControlButton(
            label: 'Stop Pump',
            icon: Icons.stop_rounded,
            color: AppColors.danger,
            enabled: canStop && !_busy,
            busy: _busy,
            onPressed: () => _run(
              () => ref.read(controllerControllerProvider.notifier).stopPump(),
              'Pump stopped',
            ),
          ),
          const SizedBox(height: 10),
          _ControlButton(
            label: 'Reset Lockout',
            icon: Icons.lock_reset_rounded,
            color: AppColors.primary,
            enabled: canReset && !_busy,
            busy: _busy,
            onPressed: () => _run(
              () => ref
                  .read(controllerControllerProvider.notifier)
                  .resetLockout(),
              'Lockout reset',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() command, String message) async {
    setState(() => _busy = true);
    try {
      await command();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        final text = error is ControllerLockoutException
            ? error.message
            : 'Command failed: $error';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: enabled ? onPressed : null,
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _TankMeter extends StatelessWidget {
  const _TankMeter({required this.full});

  final bool full;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.black.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            height: full ? 158 : 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.lagoon,
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.32),
                  blurRadius: 34,
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: full ? 146 : 60,
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.26),
              ),
            ),
          ),
          Center(
            child: Text(
              full ? 'WATER FULL' : 'BREEZE READY',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
