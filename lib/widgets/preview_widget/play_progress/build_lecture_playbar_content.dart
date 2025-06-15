/// title에 맞는 content 반환
library;

import 'package:client/screens/subtitles_only_screen.dart';
import 'package:flutter/material.dart';

import '../../../models/subtitles_model.dart';
import 'build_control_button.dart';

class BuildLecturePlayBarContent extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const BuildLecturePlayBarContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 설정 버튼
          BuildControlButton(
            icon: Icons.settings,
            label: '설정',
            screenWidth: screenWidth,
            onTap: () {
              // 설정 기능 구현
              debugPrint('설정 버튼 클릭');
            },
          ),
          // 강의 시작 버튼
          BuildControlButton(
            icon: Icons.play_circle_filled,
            label: '강의 시작',
            screenWidth: screenWidth,
            isPrimary: true,
            onTap: () {
              // 강의 시작 기능 구현
              debugPrint('강의 시작 버튼 클릭');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SubtitlesOnlyScreen(
                        subBackgroundColor: Colors.black,
                        opacitySubBackground: 0.5,
                        subWordColor: Colors.white,
                        subWordFontSize: 25,
                        subWordFont: "default",
                        languages: [
                          SubtitlesModel(
                            country: "en",
                            subtitle:
                                "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest",
                          ),
                          SubtitlesModel(
                            country: "kr",
                            subtitle: "테스트테스트테스테스트테스트테스트테스트테스트테스트테스트테스트테스트테스트",
                          ),
                        ],
                        backgroundColor: Colors.black,
                        subSpacing: 20,
                      ),
                ),
              );
            },
          ),
          // 테스트 버튼
          BuildControlButton(
            icon: Icons.mic_rounded,
            label: '음성 테스트',
            screenWidth: screenWidth,
            onTap: () {
              // 음성 테스트 기능 구현
              debugPrint('음성 테스트 버튼 클릭');
            },
          ),
        ],
      ),
    );
  }
}
