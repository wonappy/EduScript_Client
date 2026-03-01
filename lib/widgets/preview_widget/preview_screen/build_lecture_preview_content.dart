import 'package:client/core/styles/color_core.dart';
import 'package:client/providers/language_setting_provider.dart';
import 'package:flutter/material.dart';
import '../../../providers/subtitle_style_provider.dart';
import 'package:provider/provider.dart';

/// ### 강의 화면 미리보기 컨텐츠
class BuildLecturePreviewContent extends StatelessWidget {
  const BuildLecturePreviewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<LanguageSettingProvider>();
    final languages = settings.selectedOutputLanguages;
    final styles = context.watch<SubtitleStyleProvider>();

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
            color: AppColors.blackColor, // Colors.grey[800], //배경 색상 지정
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scaleFactor,
            vertical: 20 * scaleFactor,
          ),
          child: Column(
            mainAxisAlignment: styles.getAlignment(),
            children: [
              for (int i = 0; i < languages.length; i++)
                Column(
                  children: [
                    SizedBox(height: 15 * scaleFactor), //자막 간 간격 지정
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scaleFactor,
                        vertical: 7 * scaleFactor,
                      ),
                      width: screenWidth * 0.95,
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.2,
                      ),
                      // 최대 자막 컨테이너 높이
                      decoration: BoxDecoration(
                        color: styles.getBackgroundColor().withValues(
                          // 자막 배경 색상 지정
                          alpha:
                          styles.getBackgroundOpacity(), //자막 배경 불투명도 지정
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        settings.getPreviewText(languages[i]), // 자막 내용 지정
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: styles.getFontColor(), // 자막 글자 색상 지정
                          fontSize:
                          styles.getFontSize(screenWidth) *
                              scaleFactor, //자막 글자 크기 지정
                          fontWeight: styles.getFontWeight(),
                          fontStyle: styles.getFontStyle(),
                          textBaseline: null,
                        ),
                      ),
                    ),
                    SizedBox(height: 15 * scaleFactor),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
