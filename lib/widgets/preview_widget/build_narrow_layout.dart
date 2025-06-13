/// 좁은 스크린 (세로형) 레이아웃
library;

import 'package:client/widgets/preview_widget/build_preview_block.dart';
import 'package:flutter/material.dart';

class BuildNarrowLayout extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const BuildNarrowLayout({
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

    return Column(
      children: [
        // 강의 화면 미리보기
        Expanded(
          flex: 5, // 전체의 50%
          child: BuildPreviewBlock(
            title: '강의 화면 미리보기',
            screenWidth: screenWidth,
            screenHeight: screenHeight * 0.5,
          ),
        ),
        SizedBox(height: screenHeight * 0.02), // 2% 간격
        // 강의 시작
        Expanded(
          flex: 2, // 전체의 20%
          child: BuildPreviewBlock(
            title: '강의 시작',
            screenWidth: screenWidth,
            screenHeight: screenHeight * 0.2,
          ),
        ),
        SizedBox(height: screenHeight * 0.02), // 2% 간격
        // 하단 빈 공간
        Expanded(
          flex: 3, // 전체의 30%
          child: BuildPreviewBlock(
            title: '',
            screenWidth: screenWidth,
            screenHeight: screenHeight * 0.3,
            showTitle: false,
          ),
        ),
      ],
    );
  }
}
