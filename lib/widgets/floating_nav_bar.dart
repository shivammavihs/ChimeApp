import 'package:flutter/material.dart';


class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1B24).withValues(alpha: 0.85), // dark translucent grey
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(Icons.alarm_rounded, false),
          _buildNavIcon(Icons.language_rounded, false),
          _buildNavIcon(Icons.timer_outlined, false),
          _buildNavIcon(Icons.hourglass_bottom_rounded, true), // Selected: Hourglass
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, bool isSelected) {
    if (isSelected) {
      return Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2E2B35), // capsule background for selected
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF90CAF9), // sky-blue for selected
          size: 24,
        ),
      );
    }

    return Container(
      width: 60,
      height: 40,
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.5),
        size: 24,
      ),
    );
  }
}
