/// 와이드 스크린 (가로형) 레이아웃
library;

import 'package:flutter/material.dart';

import 'build_preview_block.dart';

class BuildWideLayout extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const BuildWideLayout({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Row(
      children: [
        // 왼쪽 영역 (강의 화면 미리보기 + 강의 시작)
        Expanded(
          flex: 6, // 전체의 60%
          child: Column(
            children: [
              // 강의 화면 미리보기
              Expanded(
                flex: 7, // 왼쪽 영역의 70%
                child: BuildPreviewBlock(
                  title: '강의 화면 미리보기',
                  screenWidth: screenWidth * 0.6,
                  screenHeight: screenHeight * 0.7,
                ),
              ),
              SizedBox(height: screenHeight * 0.02), // 2% 간격
              // 강의 시작
              Expanded(
                flex: 3, // 왼쪽 영역의 30%
                child: BuildPreviewBlock(
                  title: '강의 시작',
                  screenWidth: screenWidth * 0.6,
                  screenHeight: screenHeight * 0.3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.02), // 2% 간격
        // 오른쪽 영역 (빈 공간)
        Expanded(
          flex: 4, // 전체의 40%
          child: BuildPreviewBlock(
            title: '',
            screenWidth: screenWidth * 0.4,
            screenHeight: screenHeight,
            showTitle: false,
          ),
        ),
      ],
    );
  }
}
