/// 강의 화면 미리보기 (오버레이 모드) 컨텐츠
library;

import 'package:client/core/styles/color_core.dart';
import 'package:flutter/material.dart';

import '../subtitle_setting_provider.dart';
import 'package:provider/provider.dart';

class BuildLecturePreviewOverlayContent extends StatelessWidget {
  const BuildLecturePreviewOverlayContent({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SubtitleSettingsProvider>();
    final languages = settings.selectedOutputLanguages;

    const double referenceScreenWidth = 800.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final double scaleFactor = screenWidth / referenceScreenWidth;

        return Container(
          width: screenWidth,
          height: screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[200]!, Colors.purple[100]!],
            ), //배경 색상 지정 (그라데이션 -> 예시 바탕화면)
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 0.05 * screenWidth,
            vertical: 20 * scaleFactor,
          ),
          //자막 설정
          child: Column(
            mainAxisAlignment: settings.getAlignment(),
            crossAxisAlignment: settings.getHorizontalAlignment(),
            children: [
              for (int i = 0; i < languages.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 10 * scaleFactor),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * scaleFactor,
                      vertical: 7 * scaleFactor,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: screenWidth * 0.95,
                      maxHeight: screenHeight * 0.2,
                    ),
                    // 최대 자막 컨테이너 높이
                    decoration: BoxDecoration(
                      color: Colors.black, //자막 배경 색상 ; 검정색 지정
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      settings.getPreviewText(languages[i]), // 자막 내용 지정
                      textAlign: TextAlign.left, // 자막 왼쪽 정렬
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            settings.getFontSize(screenWidth) *
                            scaleFactor, //자막 글자 크기 지정
                        fontStyle: settings.getFontStyle(),
                        height: 1.2,
                        textBaseline: null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
