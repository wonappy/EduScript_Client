//화면 공유 + 자막
//대기 화면
import 'package:flutter/material.dart';

import '../core/styles/colors_core.dart';
import '../widgets/preview_widget/build_narrow_layout.dart';
import '../widgets/preview_widget/build_wide_layout.dart';

class SharedWithSubtitlesScreen extends StatelessWidget {
  const SharedWithSubtitlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // 반응형 레이아웃을 위한 비율 계산
    final bool isWideScreen = screenWidth > screenHeight * 1.5;

    return Scaffold(
      backgroundColor: backgroundcolorOnWord, // 회색 배경
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.015), // 화면 크기의 1.5%를 패딩으로
        child:
            isWideScreen //반응형 레이아웃 출력
                ? BuildWideLayout(
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                )
                : BuildNarrowLayout(
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                ),
      ),
    );
  }
}
