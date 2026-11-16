import 'package:flutter/material.dart';
import 'package:water_tank_controller/core/app_colors.dart';

class OceanBackground extends StatelessWidget {
  const OceanBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF030712),
                Color(0xFF0B192C),
                Color(0xFF1E3E62),
              ],
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
