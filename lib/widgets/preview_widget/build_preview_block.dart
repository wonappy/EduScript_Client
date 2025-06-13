//대기 화면 -> 개별 블록 위젯 생성
library;

import 'package:flutter/material.dart';

import '../../core/global_core.dart';
import '../../core/styles/colors_core.dart';
import 'get_block_content.dart';

class BuildPreviewBlock extends StatelessWidget {
  final String title;
  final double screenWidth;
  final double screenHeight;
  final bool showTitle;

  const BuildPreviewBlock({
    super.key,
    required this.title,
    required this.screenWidth,
    required this.screenHeight,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 표시
        if (showTitle && title.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              left: screenWidth * 0.01,
              bottom: screenHeight * 0.01,
            ),
            child: Text(
              title,
              style: TextStyle(
                color: previewOnWord,
                fontSize: getResponsiveFontSize(screenWidth),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        // 블록 영역
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0), // 연한 회색
              borderRadius: BorderRadius.circular(
                screenWidth * 0.008,
              ), // 반응형 모서리
              border: Border.all(color: const Color(0xFFC0C0C0), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: GetBlockContent(
              title: title,
              screenHeight: screenHeight,
              screenWidth: screenWidth,
            ),
          ),
        ),
      ],
    );
  }
}
