import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';

class ControlPanelScreen extends ConsumerWidget {
  const ControlPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(controllerControllerProvider);
    final status = snapshot.status;
    final controller = ref.read(controllerControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Pump Controls')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Column(
                children: [
                  Icon(
                    status?.pumpRunning == true
                        ? Icons.water_drop
                        : Icons.power_settings_new,
                    size: 64,
                    color: status?.pumpRunning == true
                        ? AppColors.primaryLight
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status?.pumpRunning == true
                        ? 'PUMP IS RUNNING'
                        : 'PUMP IS STOPPED',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: status?.pumpRunning == true
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (status?.lockout == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: const Text(
                        'LOCKOUT ACTIVE (Tank Full or Safety Halt)',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (status?.pumpRunning != true && status?.lockout != true)
                        ? () => controller.startPump()
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('START PUMP'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: status?.pumpRunning == true
                        ? () => controller.stopPump()
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('STOP PUMP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.warning),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: status?.lockout == true
                  ? () => controller.resetLockout()
                  : null,
              icon: const Icon(Icons.refresh, color: AppColors.warning),
              label: const Text(
                'CLEAR LOCKOUT',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
