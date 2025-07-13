// UI - 재생, 취소, 일시정지 버튼 컴포넌트들

import 'package:client/core/styles/size_core.dart';
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
    bool hasStarted = false, // 강의가 시작되었는지 여부
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //취소 버튼 (재생 중일 때만 표시)
          if (hasStarted) ...[
            buildControlIcon(icon: Icons.close, onTap: onCancel),
            SizedBox(width: screenWidth * 0.03),
          ],

          // 메인 재생/일시정지 버튼
          buildMainPlayButton(
            isPlaying: isPlaying,
            onTap: onPlayPause,
            screenWidth: screenWidth,
          ),

          // 강의 종료 버튼 (재생이 시작된 후에는 항상 표시)
          if (hasStarted) ...[
            SizedBox(width: screenWidth * 0.03),
            buildControlIcon(icon: Icons.stop, onTap: onStop),
          ],

          SizedBox(width: screenWidth * 0.04),

          // 시간 표시
          buildTimeDisplay(displayTime: displayTime, screenWidth: screenWidth),
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
      child: Icon(
        isPlaying ? Icons.pause_circle : Icons.play_circle,
        color: Colors.black,
        size: AppSizes.largeIconSize,
      ),
    );
  }

  // 컨트롤 아이콘 (취소, 정지 버튼)
  static Widget buildControlIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.basePadding),
        child: Icon(icon, color: Colors.black87, size: AppSizes.largeIconSize),
      ),
    );
  }

  // 시간 표시
  static Widget buildTimeDisplay({
    required String displayTime,
    required double screenWidth,
  }) {
    return Text(
      displayTime,
      style: TextStyle(
        fontSize: AppSizes.largeFontSize,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}
