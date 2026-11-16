import 'package:flutter/material.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/utils/time_formatters.dart';

class RuntimeDisplay extends StatelessWidget {
  const RuntimeDisplay({
    super.key,
    required this.label,
    required this.seconds,
    this.isLive = false,
  });

  final String label;
  final int seconds;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (isLive) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          TimeFormatters.formatSeconds(seconds),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
