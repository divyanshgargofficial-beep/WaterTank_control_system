import 'package:flutter/material.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/utils/time_formatters.dart';

class RuntimeDisplay extends StatelessWidget {
  const RuntimeDisplay({
    super.key,
    required this.label,
    required this.seconds,
    this.large = false,
  });

  final String label;
  final int seconds;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = large
        ? Theme.of(context).textTheme.displaySmall
        : Theme.of(context).textTheme.headlineSmall;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: seconds.toDouble(), end: seconds.toDouble()),
      duration: const Duration(milliseconds: 450),
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              formatDurationSeconds(value.round()),
              style: style?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        );
      },
    );
  }
}
