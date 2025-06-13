/// 재생 부분 컨트롤 버튼 위젯
library;

import 'package:flutter/material.dart';

import '../../../core/global_core.dart';

class BuildControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double screenWidth;
  final VoidCallback onTap;
  final bool isPrimary;

  const BuildControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.screenWidth,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenWidth * 0.015,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.blue[600] : Colors.grey[600],
          borderRadius: BorderRadius.circular(screenWidth * 0.01),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: screenWidth * 0.04),
            SizedBox(height: screenWidth * 0.005),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: getResponsiveFontSize(screenWidth) * 0.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
