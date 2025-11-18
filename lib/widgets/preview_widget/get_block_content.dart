/// title에 맞는 content 반환
library;

import 'package:client/widgets/preview_widget/play_progress/build_lecture_playbar_content.dart';
import 'package:client/widgets/preview_widget/preview_screen/buil_lecture_preview_overlay_content.dart';
import 'package:client/widgets/preview_widget/preview_screen/build_lecture_preview_content.dart';
import 'package:client/widgets/preview_widget/subtitle_setting/build_overlay_subtitle_setting_content.dart';
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

    // (Provider) 자막 설정 상태 받아오기
    // read가 아닌 watch로 불러와야 Provider의 상태 변화를 바로 감지함
    final subtitleSettings = context.watch<SubtitleSettingsProvider>();

    switch (title) {
      // [1] 미리보기 화면
      case '화면 미리보기':
        if (subtitleSettings.screenSharedEnabled) {
          //오버레이 모드
          return BuildLecturePreviewOverlayContent();
        } else {
          //기본 자막창 모드
          return BuildLecturePreviewContent();
        }
      // [2] 플레이 바 (재생 버튼)
      case '':
        return BuildLecturePlayBarContent(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        );
      default:
        // [3] 자막 설정 화면
        // - 화면 공유 모드
        if (subtitleSettings.screenSharedEnabled) {
          return BuildOverlaySubtitleSettingContent(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          );
        }
        // - 자막 ONLY 모드 (화면 공유 모드 OFF)
        else {
          return BuildSubtitleSettingContent(
              screenWidth: screenWidth,
              screenHeight: screenHeight
          );
        }
    }
  }
}
