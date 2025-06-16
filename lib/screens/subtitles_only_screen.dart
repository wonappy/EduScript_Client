//자막 (프롬프트 느낌 ver)
import 'package:client/models/subtitles_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SubtitlesOnlyScreen extends StatefulWidget {
  final Color backgroundColor; // 배경 색상

  final Color subBackgroundColor; //자막 배경 색상
  final double opacitySubBackground; //자막 배경 불투명도

  final Color subWordColor; //자막 글자 색상
  final double subWordFontSize; //자막 글자 크기
  final String subWordFont; //자막 글꼴
  final double subSpacing; //자막 간 간격

  final List<SubtitlesModel> languages; //언어 리스트

  const SubtitlesOnlyScreen({
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
  State<SubtitlesOnlyScreen> createState() => _SubtitlesOnlyScreenState();
}

class _SubtitlesOnlyScreenState extends State<SubtitlesOnlyScreen> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("자막 개수 : ${widget.languages.length}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: screenWidth * 0.9,
            height: screenHeight,
            color: widget.backgroundColor, //배경 색상 지정
            child: Column(
              children: [
                for (int i = 0; i < widget.languages.length; i++)
                  Column(
                    children: [
                      SizedBox(height: widget.subSpacing), //자막 간 간격 지정
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        width: screenWidth * 0.95,
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.5,
                        ), //최대 자막 컨테이너 높이
                        decoration: BoxDecoration(
                          color: widget.subBackgroundColor.withValues(
                            //자막 배경 색상 지정
                            alpha: widget.opacitySubBackground, //자막 배경 불투명도 지정
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.languages[i].subtitle, //자막 내용 지정
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.subWordColor, //자막 글자 색상 지정
                            fontSize: widget.subWordFontSize, //자막 글자 크기 지정
                            fontWeight: FontWeight.w700,
                            textBaseline: null,
                          ),
                        ),
                      ),
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