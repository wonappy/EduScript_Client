// UI - 재생, 취소, 일시정지 버튼 컴포넌트들

import 'package:flutter/material.dart';

class LecturePlayBarComponents {
  // 메인 플레이바 컨테이너
  static Widget buildPlayBarContainer({
    required double screenWidth,
    required bool isPlaying,
    required String displayTime,
    required VoidCallback onPlayPause,
    required VoidCallback onCancel,
    required VoidCallback onStop,
    required double Function(double) getResponsiveFontSize,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(screenWidth * 0.01),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 취소 버튼 (재생 중일 때만 표시)
          if (isPlaying) ...[
            buildControlIcon(
              icon: Icons.close,
              onTap: onCancel,
              screenWidth: screenWidth,
            ),
            SizedBox(width: screenWidth * 0.03),
          ],

          // 메인 재생/일시정지 버튼
          buildMainPlayButton(
            isPlaying: isPlaying,
            onTap: onPlayPause,
            screenWidth: screenWidth,
          ),

          // 강의 종료 버튼 (재생 중일 때만 표시)
          if (isPlaying) ...[
            SizedBox(width: screenWidth * 0.03),
            buildControlIcon(
              icon: Icons.stop,
              onTap: onStop,
              screenWidth: screenWidth,
            ),
          ],

          SizedBox(width: screenWidth * 0.04),

          // 시간 표시
          buildTimeDisplay(
            displayTime: displayTime,
            screenWidth: screenWidth,
            getResponsiveFontSize: getResponsiveFontSize,
          ),
        ],
      ),
    );
  }

  // 메인 재생/일시정지 버튼
  static Widget buildMainPlayButton({
    required bool isPlaying,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.12,
        height: screenWidth * 0.12,
        decoration: const BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: screenWidth * 0.06,
        ),
      ),
    );
  }

  // 컨트롤 아이콘 (취소, 정지 버튼)
  static Widget buildControlIcon({
    required IconData icon,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: Icon(icon, color: Colors.black87, size: screenWidth * 0.05),
      ),
    );
  }

  // 시간 표시
  static Widget buildTimeDisplay({
    required String displayTime,
    required double screenWidth,
    required double Function(double) getResponsiveFontSize,
  }) {
    return Text(
      displayTime,
      style: TextStyle(
        fontSize: getResponsiveFontSize(screenWidth) * 0.8,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}
