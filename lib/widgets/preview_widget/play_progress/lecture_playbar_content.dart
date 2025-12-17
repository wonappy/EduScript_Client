// UI - 재생, 취소, 일시정지 버튼 컴포넌트들

import 'package:client/core/styles/color_core.dart';
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
        horizontal: screenWidth * 0.01,
        vertical: screenWidth * 0.01,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteColor1, // Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // 더 연한 그림자
            blurRadius: 10,
            spreadRadius: 1, // 그림자 확산
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //취소 버튼 (재생 중일 때만 표시)
          if (hasStarted) ...[
            buildControlIcon(
              icon: Icons.close,
              onTap: onCancel,
              screenWidth: screenWidth,
              backgroundColor: AppColors.redColor,
              borderColor: null,
              iconColor: AppColors.whiteColor1,
            ),
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
            buildControlIcon(
              icon: Icons.stop,
              onTap: onStop,
              screenWidth: screenWidth,
              backgroundColor: AppColors.grayColor,
              borderColor: null,
              iconColor: AppColors.whiteColor1,
            ),
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
      child: Container(
        width: screenWidth * 0.05,
        height: screenWidth * 0.05,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              AppColors
                  .blueColor2, // AppColors.whiteColor1, // AppColors.blueColor2, //Colors.black87,
          // border: Border.all(
          //   color: null,  // 테두리 색상
          //   width: 1.0,                  // 테두리 두께 (선택사항)
          // ),
          shape: BoxShape.rectangle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // 더 연한 그림자
              blurRadius: 10,
              spreadRadius: 1, // 그림자 확산
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          // 아이콘 흰색
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: screenWidth * 0.04,
          // isPlaying ? Icons.pause : Icons.play_arrow,
          // color: AppColors.blueColor2,
          // size: screenWidth * 0.05,
        ),
      ),
    );
  }

  // 컨트롤 아이콘 (취소, 정지 버튼)
  static Widget buildControlIcon({
    required IconData icon,
    required VoidCallback onTap,
    required double screenWidth,
    Color? backgroundColor,
    Color? borderColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.05,
        height: screenWidth * 0.05,
        decoration: BoxDecoration(
          color: backgroundColor,
          border:
              borderColor != null
                  ? Border.all(color: borderColor, width: 1.0)
                  : null, // borderColor가 null이면 테두리 없음
          borderRadius: BorderRadius.circular(12),
          shape: BoxShape.rectangle,
        ),
        //padding: EdgeInsets.all(screenWidth * 0.02),
        child: Center(
          child: Icon(icon, color: iconColor, size: screenWidth * 0.04),
        ),
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
