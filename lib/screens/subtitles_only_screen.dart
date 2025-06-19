//자막 (프롬프트 느낌 ver)
import 'package:client/models/subtitles_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/preview_widget/subtitle_setting_provider.dart';

class SubtitlesOnlyScreen extends StatefulWidget {
  final Color backgroundColor; // 배경 색상
  final String subWordFont; //자막 글꼴
  final double subSpacing; //자막 간 간격

  const SubtitlesOnlyScreen({
    super.key,
    required this.backgroundColor,
    required this.subWordFont,
    required this.subSpacing,
  });

  @override
  State<SubtitlesOnlyScreen> createState() => _SubtitlesOnlyScreenState();
}

class _SubtitlesOnlyScreenState extends State<SubtitlesOnlyScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SubtitleSettingsProvider>(); //자막 출력
    final languages = settings.selectedOutputLanguages; //선택된 출력 언어 목록 가져오기

    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: screenWidth,
            height: screenHeight,
            color: widget.backgroundColor, //배경 색상 지정
            child: Column(
              mainAxisAlignment: settings.getAlignment(),
              children: [
                for (int i = 0; i < languages.length; i++)
                  Column(
                    children: [
                      SizedBox(height: 10), //자막 간 간격 지정
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
                                settings.getBackgroundOpacity(), //자막 배경 불투명도 지정
                          ),
                          borderRadius: BorderRadius.circular(20),
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
                      SizedBox(height: 10), //자막 간 간격 지정
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close_rounded),
              iconSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}
