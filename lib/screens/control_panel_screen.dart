import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/services/controller_api_service.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';
import 'package:water_tank_controller/widgets/runtime_display.dart';

class ControlPanelScreen extends ConsumerStatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  ConsumerState<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends ConsumerState<ControlPanelScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(controllerControllerProvider);
    final status = snapshot.status;
    final offline = !snapshot.online;
    final canStart =
        !offline && status?.pumpRunning != true && status?.lockout != true;
    final canStop = !offline && status?.pumpRunning == true;
    final canReset = !offline && status?.lockout == true;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Control Panel',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RuntimeDisplay(
                label: 'Current Runtime',
                seconds: status?.currentRuntimeSeconds ?? 0,
                large: true,
              ),
              const SizedBox(height: 18),
              Text(
                offline
                    ? 'Controller is offline. Commands are disabled until reconnection.'
                    : status?.lockout == true
                    ? 'Pump is locked out. Reset lockout before starting.'
                    : 'Controls are synchronized with the firmware state.',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ActionButton(
          label: 'START PUMP',
          icon: Icons.play_arrow_rounded,
          color: AppColors.success,
          enabled: canStart && !_busy,
          busy: _busy,
          onPressed: () async {
            final confirmed = await _confirmStart();
            if (confirmed) {
              await _runCommand(
                () =>
                    ref.read(controllerControllerProvider.notifier).startPump(),
                'Pump started',
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'STOP PUMP',
          icon: Icons.stop_rounded,
          color: AppColors.danger,
          enabled: canStop && !_busy,
          busy: _busy,
          onPressed: () => _runCommand(
            () => ref.read(controllerControllerProvider.notifier).stopPump(),
            'Pump stopped',
          ),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'RESET LOCKOUT',
          icon: Icons.lock_reset_rounded,
          color: AppColors.primary,
          enabled: canReset && !_busy,
          busy: _busy,
          onPressed: () => _runCommand(
            () =>
                ref.read(controllerControllerProvider.notifier).resetLockout(),
            'Lockout reset',
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmStart() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Start pump?'),
            content: const Text(
              'This will energize the controller relay and start the water pump.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Start'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _runCommand(
    Future<void> Function() command,
    String success,
  ) async {
    setState(() => _busy = true);
    try {
      await command();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_commandErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _commandErrorMessage(Object error) {
    if (error is ControllerLockoutException) return error.message;
    return 'Command failed: $error';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
