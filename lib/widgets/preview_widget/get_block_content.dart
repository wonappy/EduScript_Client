/// title에 맞는 content 반환
library;

import 'package:client/widgets/preview_widget/play_progress/build_lecture_playbar_content.dart';
import 'package:client/widgets/preview_widget/preview_screen/build_lecture_preview_content.dart';
import 'package:client/widgets/preview_widget/subtitle_setting/build_subtitle_setting_content.dart';
import 'package:flutter/material.dart';

class GetBlockContent extends StatelessWidget {
  final String title;
  final double screenWidth;
  final double screenHeight;

  const GetBlockContent({
    super.key,
    required this.title,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    switch (title) {
      case '강의 화면 미리보기':
        return BuildLecturePreviewContent(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        );
      case '강의 시작':
        return BuildLecturePlayBarContent(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        );
      default:
        return BuildSubtitleSettingContent(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        );
    }
  }
}
