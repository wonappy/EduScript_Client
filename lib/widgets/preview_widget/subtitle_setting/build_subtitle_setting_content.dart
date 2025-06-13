/// 자막 언어 및 테마 설정
library;

import 'package:flutter/material.dart';

import '../../../core/global_core.dart';

class BuildSubtitleSettingContent extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const BuildSubtitleSettingContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '추가 기능 영역',
        style: TextStyle(
          fontSize: getResponsiveFontSize(screenWidth) * 0.7,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}
