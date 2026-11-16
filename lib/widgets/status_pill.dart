import 'package:flutter/material.dart';
import 'package:water_tank_controller/core/app_colors.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.active,
    this.activeColor = AppColors.success,
    this.inactiveColor = AppColors.surfaceLight,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? activeColor : inactiveColor).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (active ? activeColor : inactiveColor).withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? activeColor : AppColors.textSecondary,
        ),
      ),
    );
  }
}
