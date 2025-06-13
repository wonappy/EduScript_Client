/// title에 맞는 content 반환
library;

import 'package:flutter/material.dart';

import 'build_control_button.dart';

class BuildLecturePlayBarContent extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const BuildLecturePlayBarContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 설정 버튼
          BuildControlButton(
            icon: Icons.settings,
            label: '설정',
            screenWidth: screenWidth,
            onTap: () {
              // 설정 기능 구현
              debugPrint('설정 버튼 클릭');
            },
          ),
          // 강의 시작 버튼
          BuildControlButton(
            icon: Icons.play_circle_filled,
            label: '강의 시작',
            screenWidth: screenWidth,
            isPrimary: true,
            onTap: () {
              // 강의 시작 기능 구현
              debugPrint('강의 시작 버튼 클릭');
            },
          ),
          // 테스트 버튼
          BuildControlButton(
            icon: Icons.mic_rounded,
            label: '음성 테스트',
            screenWidth: screenWidth,
            onTap: () {
              // 음성 테스트 기능 구현
              debugPrint('음성 테스트 버튼 클릭');
            },
          ),
        ],
      ),
    );
  }
}
