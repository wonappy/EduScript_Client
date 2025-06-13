/// 강의 화면 미리보기 컨텐츠
library;

import 'package:flutter/material.dart';

import '../../../core/global_core.dart';

class BuildLecturePreviewContent extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const BuildLecturePreviewContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_outlined,
            size: screenWidth * 0.08,
            color: Colors.grey[600],
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            '카메라 준비 중...',
            style: TextStyle(
              fontSize: getResponsiveFontSize(screenWidth) * 0.8,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
