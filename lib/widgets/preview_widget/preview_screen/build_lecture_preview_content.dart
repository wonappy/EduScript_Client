/// 강의 화면 미리보기 컨텐츠
library;

import 'package:flutter/material.dart';

import '../../../models/subtitles_model.dart';

class BuildLecturePreviewContent extends StatelessWidget {
  final Color backgroundColor; // 배경 색상

  final Color subBackgroundColor; //자막 배경 색상
  final double opacitySubBackground; //자막 배경 불투명도

  final Color subWordColor; //자막 글자 색상
  final double subWordFontSize; //자막 글자 크기
  final String subWordFont; //자막 글꼴
  final double subSpacing; //자막 간 간격

  final List<SubtitlesModel> languages; //언어 리스트

  const BuildLecturePreviewContent({
    super.key,
    required this.backgroundColor,
    required this.subBackgroundColor,
    required this.opacitySubBackground,
    required this.subWordColor,
    required this.subWordFontSize,
    required this.subWordFont,
    required this.subSpacing,
    required this.languages,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        return Container(
          width: screenWidth,
          height: screenHeight,
          decoration: BoxDecoration(
            color: backgroundColor, //배경 색상 지정
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              for (int i = 0; i < languages.length; i++)
                Column(
                  children: [
                    SizedBox(height: subSpacing), //자막 간 간격 지정
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
                        color: subBackgroundColor.withValues(
                          //자막 배경 색상 지정
                          alpha: opacitySubBackground, //자막 배경 불투명도 지정
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        languages[i].subtitle, //자막 내용 지정
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: subWordColor, //자막 글자 색상 지정
                          fontSize: subWordFontSize, //자막 글자 크기 지정
                          fontWeight: FontWeight.w700,
                          textBaseline: null,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
