/// 강의 화면 미리보기 컨텐츠
library;

import 'package:client/core/styles/color_core.dart';
import 'package:flutter/material.dart';

import '../subtitle_setting_provider.dart';
import 'package:provider/provider.dart';

class BuildLecturePreviewContent extends StatelessWidget {
  const BuildLecturePreviewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SubtitleSettingsProvider>();
    final languages = settings.selectedOutputLanguages;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        return Container(
          width: screenWidth,
          height: screenHeight,
          decoration: BoxDecoration(
            color: AppColors.blackColor,// Colors.grey[800], //배경 색상 지정
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            mainAxisAlignment: settings.getAlignment(),
            children: [
              for (int i = 0; i < languages.length; i++)
                Column(
                  children: [
                    SizedBox(height: 15), //자막 간 간격 지정
                    //이전 자막
                    Text(
                      Provider.of<SubtitleSettingsProvider>(
                        context,
                        listen: false,
                      ).getOutputLanguage(languages[i]),
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    SizedBox(height: 7),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      width: screenWidth * 0.95,
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.5,
                      ),
                      //최대 자막 컨테이너 높이
                      decoration: BoxDecoration(
                        color: settings.getBackgroundColor().withValues(
                          //자막 배경 색상 지정
                          alpha:
                              settings.getBackgroundOpacity() *
                              0.6, //자막 배경 불투명도 지정
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        settings.getPreviewText(languages[i]), //자막 내용 지정
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: settings.getFontColor(), //자막 글자 색상 지정
                          fontSize: settings.getFontSize(
                            screenWidth,
                          ), //자막 글자 크기 지정
                          fontWeight: settings.getFontWeight(),
                          fontStyle: settings.getFontStyle(),
                          textBaseline: null,
                        ),
                      ),
                    ),
                    SizedBox(height: 5), //자막 간 간격 지정
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      width: screenWidth * 0.95,
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.2,
                      ),
                      // 최대 자막 컨테이너 높이
                      decoration: BoxDecoration(
                        color: settings.getBackgroundColor().withValues(
                          // 자막 배경 색상 지정
                          alpha:
                              settings.getBackgroundOpacity(), //자막 배경 불투명도 지정
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        settings.getPreviewText(languages[i]), // 자막 내용 지정
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: settings.getFontColor(), // 자막 글자 색상 지정
                          fontSize: settings.getFontSize(
                            screenWidth,
                          ), //자막 글자 크기 지정
                          fontWeight: settings.getFontWeight(),
                          fontStyle: settings.getFontStyle(),
                          textBaseline: null,
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
