//대기 화면 -> 개별 블록 위젯 생성
library;

import 'package:client/core/styles/color_core.dart';
import 'package:client/core/styles/size_core.dart';
import 'package:flutter/material.dart';
import 'package:client/core/styles/size_core.dart';
import 'package:client/widgets/preview_widget/get_block_content.dart';


class BuildPreviewBlock extends StatelessWidget {
  final String? title;
  final double screenWidth;
  final double screenHeight;
  final bool showTitle;

  const BuildPreviewBlock({
    super.key,
    this.title,
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
        if (showTitle && title!.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(left: 1, bottom: screenHeight * 0.01),
            child: Row(
              children: [
                Icon(
                  Icons.desktop_windows,
                  color: AppColors.blueColor2,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  title ?? '',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: AppSizes.titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        // 블록 영역
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent, // 연한 회색
              borderRadius: BorderRadius.circular(
                AppSizes.baseRadius,
              ), // 반응형 모서리
              border: Border.all(color: Colors.transparent),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withValues(alpha: 0.1),
              //     blurRadius: 4,
              //     offset: const Offset(2, 2),
              //   ),
              // ],
            ),
            child: GetBlockContent(
              title: title!,
              screenHeight: screenHeight,
              screenWidth: screenWidth,
            ),
          ),
        ),
      ],
    );
  }
}
