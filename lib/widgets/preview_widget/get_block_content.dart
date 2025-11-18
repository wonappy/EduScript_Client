/// title에 맞는 content 반환
library;

import 'package:client/widgets/preview_widget/play_progress/build_lecture_playbar_content.dart';
import 'package:client/widgets/preview_widget/preview_screen/buil_lecture_preview_overlay_content.dart';
import 'package:client/widgets/preview_widget/preview_screen/build_lecture_preview_content.dart';
import 'package:client/widgets/preview_widget/subtitle_setting/build_subtitle_setting_content.dart';
import 'package:client/widgets/preview_widget/subtitle_setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final subtitleSettings = context.watch<SubtitleSettingsProvider>();

    switch (title) {
      case '화면 미리보기':
        if (subtitleSettings.screenSharedEnabled) {
          //오버레이 모드
          return BuildLecturePreviewOverlayContent();
        } else {
          //기본 자막창 모드
          return BuildLecturePreviewContent();
        }
      case '':
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
