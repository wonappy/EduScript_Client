// 대기 화면
import 'package:client/core/styles/color_core.dart';
import 'package:flutter/material.dart';
import '../widgets/preview_widget/build_preview_block.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: AppColors.whiteColor2,
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.015), // 화면 크기의 1.5%를 패딩으로
        child: Row(
          children: [
            // 왼쪽 영역 (미리보기 화면 & 플레이버튼)
            Expanded(
              flex: 7, // 전체의 70%
              child: Column(
                children: [
                  // 강의 화면 미리보기
                  Expanded(
                    flex: 8, // 왼쪽 영역의 80%
                    child: BuildPreviewBlock(
                      title: '화면 미리보기',
                      screenWidth: screenWidth * 0.6,
                      screenHeight: screenHeight * 0.7,
                    ),
                  ),
                  SizedBox(height: 18), // 2% 간격
                  // 강의 시작
                  Expanded(
                    flex: 2, // 왼쪽 영역의 20%
                    child: BuildPreviewBlock(
                      title: '',
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
                width: screenWidth * 0.04,
              ),
            ),

            // 오른쪽 영역 (자막 설정)
            Expanded(
              flex: 3, // 전체의 30%
              child: BuildPreviewBlock(
                title: '언어 설정',
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
