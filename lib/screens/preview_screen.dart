// 대기 화면
import 'package:client/core/styles/color_core.dart';
import 'package:flutter/material.dart';

import '../widgets/preview_widget/build_preview_block.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: AppColors.whiteColor1, // 🔴 배경색
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.015), // 화면 크기의 1.5%를 패딩으로
        child: Row(
          children: [
            // 왼쪽 영역 (강의 화면 미리보기 + 강의 시작)
            Expanded(
              flex: 7, // 전체의 60%
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
                  SizedBox(height: 18), // 2% 간격
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
            SizedBox(
              height: screenHeight * 0.98, // 세로 길이
              child: VerticalDivider(
                color: Color(0xFF707070),
                thickness: 2.0,
                width: screenWidth * 0.04, // 선+좌우 간격 포함한 너비
              ),
            ),
            // 오른쪽 영역 (빈 공간)
            Expanded(
              flex: 3, // 전체의 40%
              child: BuildPreviewBlock(
                title: '',
                screenWidth: screenWidth * 0.4,
                screenHeight: screenHeight,
                showTitle: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
