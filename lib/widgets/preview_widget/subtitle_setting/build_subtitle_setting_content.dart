/// 자막 언어 및 테마 설정
library;

import 'package:flutter/material.dart';
import '../../../core/global_core.dart';
import 'setting_drop_down_widget.dart';
import 'color_setting_drop_down_widget.dart';
import 'onoff_switch_state_widget.dart';
import 'multi_language_dropdown.dart';

class BuildSubtitleSettingContent extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;

  const BuildSubtitleSettingContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<BuildSubtitleSettingContent> createState() =>
      _BuildSubtitleSettingContentState();
}

class _BuildSubtitleSettingContentState
    extends State<BuildSubtitleSettingContent> {
  // [초기값 설정]
  bool screenSharedEnabled = true; // 스위치
  List<String> selectedInputLanguages = ['한국어']; // 입력 언어
  List<String> selectedOutputLanguages = ['한국어']; // 출력 언어
  String selectedPosition = '하단'; // 자막 위치
  String selectedFontStyle = '기본'; // 자막 스타일 (이탤릭, 굵기 등)
  String selectedFontSize = '중간'; // 폰트 크기
  String selectedFontColor = '흰색'; // 폰트 색상
  String selectedBackgroundColor = '흰색'; // 폰트 배경색
  String selectedBackgroundOpacity = '50%'; // 배경색 불투명도

  List<String> inputLanguagesList = ['한국어', '영어', '일본어', '중국어'];
  List<String> outputLanguagesList = ['한국어', '영어', '일본어', '중국어'];
  Color backContentContainerColor = Color(0xFFC1C1C1);
  Color dropdownWidgetColor = Color(0xFFF6F6F6);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // [0] 미리보기 화면
            _buildPreviewContainer(),
            SizedBox(height: 30),

            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  // 스크롤바 안보이도록
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // [1] 화면 공유 ON/OFF
                      _buildScreenShareSection(),
                      _buildDivider(), // 구분선
                      // [2] 입력 언어 설정 섹션
                      _buildInputLanguageSection(),
                      _buildDivider(), // 구분선
                      // [3] 출력 언어 설정 섹션
                      _buildOutputLanguageSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [공통 UI 위젯]
  // 1) 미리보기 화면
  Widget _buildPreviewContainer() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // 그림자 색상 및 투명도
            spreadRadius: 5, // 그림자 확산 정도
            blurRadius: 7, // 그림자 흐림 정도
            offset: Offset(0, 3), // 그림자 위치 (x, y)
          ),
        ],
      ),
      width: widget.screenWidth * 0.8,
      height: widget.screenHeight * 0.3,
      child: Column(
        mainAxisAlignment: _getAlignment(),
        children: _buildPreviewText(),
      ),
    );
  }

  List<Widget> _buildPreviewText() {
    if (selectedOutputLanguages.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _getBackgroundColor().withOpacity(_getBackgroundOpacity()),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            '안녕하세요! 텍스트 자막입니다.',
            style: TextStyle(
              color: _getFontColor(),
              fontSize: _getFontSize(),
              fontWeight: _getFontWeight(),
              fontStyle: _getFontStyle(),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    return selectedOutputLanguages.map((language) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 2), // 각 자막 사이 간격
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _getBackgroundColor().withOpacity(_getBackgroundOpacity()),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          _getPreviewText(language), // 언어별 텍스트 반환
          style: TextStyle(
            color: _getFontColor(),
            fontSize: _getFontSize(),
            fontWeight: _getFontWeight(),
            fontStyle: _getFontStyle(),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }).toList();
  }

  // 2) 섹션 제목
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: getResponsiveFontSize(widget.screenWidth) * 0.8,
          color: Colors.black,
        ),
      ),
    );
  }

  // 3) 구분선
  Widget _buildDivider() {
    return Column(
      children: [
        SizedBox(height: 20),
        Divider(color: Colors.grey, thickness: 1, height: 1),
        SizedBox(height: 25),
      ],
    );
  }

  // 4) 큰 컨테이너
  Widget _buildBigContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backContentContainerColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // 그림자 색상 및 투명도
            blurRadius: 3, // 그림자 흐림 정도
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // 5) 작은 컨테이너
  Widget _buildSmallContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: dropdownWidgetColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // 그림자 색상 및 투명도
            blurRadius: 3, // 그림자 흐림 정도
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // 6) 중간 컨테이너 (둥근 모서리)
  Widget _buildMediumContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: dropdownWidgetColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // 7) 서브 섹션 (제목 & 내용)
  Widget _buildSubSection({
    required String title,
    required Widget content,
    double spacing = 10,
  }) {
    return Column(
      children: [
        _buildSectionTitle(title),
        SizedBox(height: spacing),
        content,
        SizedBox(height: 20),
      ],
    );
  }

  // [섹션 별 빌더]
  // 1) 화면 공유 ON/OFF
  Widget _buildScreenShareSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle('화면 공유 ON/OFF'), // 섹션 제목
        SizedBox(height: 10),
        // ON/OFF 위젯
        OnOffSwitch(
          initialValue: screenSharedEnabled,
          onChanged: (bool newValue) {
            setState(() {
              screenSharedEnabled = newValue;
            });
          },
        ),
      ],
    );
  }

  // 2) 입력 언어 섹션
  Widget _buildInputLanguageSection() {
    return Column(
      children: [
        _buildSectionTitle("입력 언어 설정"),
        SizedBox(height: 10),
        _buildBigContainer(
          child: _buildSmallContainer(
            child: MultiLanguageDropdown(
              title: "언어",
              selectedLanguages: selectedInputLanguages, // 리스트 전달
              availableLanguages: inputLanguagesList,
              onChanged: (List<String> newLanguages) {
                // List<String> 받음
                setState(() {
                  selectedInputLanguages = newLanguages;
                });
              },
              screenWidth: widget.screenWidth,
              screenHeight: widget.screenHeight,
            ),
          ),
        ),
      ],
    );
  }

  // 3) 출력 언어 섹션
  Widget _buildOutputLanguageSection() {
    return Column(
      children: [
        _buildSectionTitle("출력 언어 설정"),
        SizedBox(height: 10),
        _buildBigContainer(
          child: Column(
            children: [
              // 3-1) 출력 언어 선택
              _buildSmallContainer(
                child: MultiLanguageDropdown(
                  title: "언어",
                  selectedLanguages: selectedOutputLanguages, // 리스트 전달
                  availableLanguages: outputLanguagesList,
                  onChanged: (List<String> newLanguages) {
                    // List<String> 받음
                    setState(() {
                      selectedOutputLanguages = newLanguages;
                    });
                  },
                  screenWidth: widget.screenWidth,
                  screenHeight: widget.screenHeight,
                ),
              ),
              SizedBox(height: 20),

              // 3-2) 스타일 설정
              _buildSubSection(
                title: "스타일",
                content: _buildMediumContainer(
                  child: Column(
                    children: [
                      _buildPositionDropdown(), // 텍스트 위치
                      _buildStyleDropdown(), // 텍스트 스타일
                    ],
                  ),
                ),
              ),

              // 3-3) 텍스트 설정
              _buildSubSection(
                title: "텍스트",
                content: _buildMediumContainer(
                  child: Column(
                    children: [
                      _buildSizeDropdown(), // 텍스트 크기
                      _buildTextColorDropdown(), // 텍스트 색상
                    ],
                  ),
                ),
              ),

              // 배경 설정
              _buildSubSection(
                title: "배경",
                content: _buildMediumContainer(
                  child: Column(
                    children: [
                      _buildBackgroundColorDropdown(), // 배경색
                      _buildOpacityDropdown(), // 배경색 불투명도
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // [개별 드롭다운]
  // 1) 텍스트 위치
  Widget _buildPositionDropdown() {
    return SettingDropdown(
      title: "위치",
      initialValue: "하단",
      options: ["상단", "중앙", "하단"],
      onChanged: (String newPosition) {
        setState(() {
          selectedPosition = newPosition;
        });
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
    );
  }

  // 2) 텍스트 스타일
  Widget _buildStyleDropdown() {
    return SettingDropdown(
      title: "스타일",
      initialValue: "기본",
      options: ["기본", "굵게", "이탤릭"],
      onChanged: (String newStyle) {
        setState(() {
          selectedFontStyle = newStyle;
        });
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
    );
  }

  // 3) 텍스트 크기
  Widget _buildSizeDropdown() {
    return SettingDropdown(
      title: "크기",
      initialValue: "중간",
      options: ["작게", "중간", "크게", "매우 크게"],
      onChanged: (String newSize) {
        setState(() {
          selectedFontSize = newSize;
        });
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
    );
  }

  // 4) 텍스트 색상
  Widget _buildTextColorDropdown() {
    return ColorSettingDropDown(
      title: "색상",
      initialValue: "흰색",
      options: ["빨강", "주황", "노랑", "초록", "파랑", "보라", "검정", "흰색"],
      onChanged: (String newColor) {
        setState(() {
          selectedFontColor = newColor;
        });
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
      isColorSelector: true,
    );
  }

  // 5) 텍스트 배경 색상
  Widget _buildBackgroundColorDropdown() {
    return ColorSettingDropDown(
      title: "색상",
      initialValue: "흰색",
      options: ["빨강", "주황", "노랑", "초록", "파랑", "보라", "검정", "흰색"],
      onChanged: (String newColor) {
        setState(() {
          selectedBackgroundColor = newColor;
        });
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
      isColorSelector: true,
    );
  }

  // 6) 배경색 불투명도
  Widget _buildOpacityDropdown() {
    return ColorSettingDropDown(
      title: "불투명도",
      initialValue: "50%",
      options: ["0%", "25%", "50%", "75%", "100%"],
      onChanged: (String newOpacity) {
        setState(() {
          selectedBackgroundOpacity = newOpacity;
        });
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
      isColorSelector: false,
    );
  }

  // [상태 변환 함수들]
  // 1) 출력 언어
  String _getPreviewText(String language) {
    switch (language) {
      case '영어':
        return 'Hello! This is a test subtitle.';
      case '일본어':
        return 'こんにちは！テスト字幕です。';
      case '중국어':
        return '你好！这是测试字幕。';
      default:
        return '안녕하세요! 텍스트 자막입니다.';
    }
  }

  // 2) 자막 위치
  MainAxisAlignment _getAlignment() {
    switch (selectedPosition) {
      case '상단':
        return MainAxisAlignment.start;
      case '중앙':
        return MainAxisAlignment.center;
      case '하단':
      default:
        return MainAxisAlignment.end;
    }
  }

  // 3) 자막 스타일
  // 폰트 굵기 (FontWeight)
  FontWeight _getFontWeight() {
    return selectedFontStyle == '굵게' ? FontWeight.bold : FontWeight.normal;
  }

  // 폰트 스타일 (FontStyle)
  FontStyle _getFontStyle() {
    return selectedFontStyle == '이탤릭' ? FontStyle.italic : FontStyle.normal;
  }

  // 4) 텍스트 크기
  double _getFontSize() {
    double baseSize = getResponsiveFontSize(widget.screenWidth);
    switch (selectedFontSize) {
      case '작게':
        return baseSize * 0.6;
      case '크게':
        return baseSize * 1.2;
      case '매우 크게':
        return baseSize * 1.5;
      case '중간':
      default:
        return baseSize * 0.8;
    }
  }

  // 5) 텍스트 색상
  Color _getFontColor() {
    switch (selectedFontColor) {
      case '빨강':
        return Colors.red;
      case '주황':
        return Colors.orange;
      case '노랑':
        return Colors.yellow;
      case '초록':
        return Colors.green;
      case '파랑':
        return Colors.blue;
      case '보라':
        return Colors.purple;
      case '검정':
        return Colors.black;
      case '흰색':
      default:
        return Colors.white;
    }
  }

  // 6) 배경 색상
  Color _getBackgroundColor() {
    switch (selectedBackgroundColor) {
      case '빨강':
        return Colors.red;
      case '주황':
        return Colors.orange;
      case '노랑':
        return Colors.yellow;
      case '초록':
        return Colors.green;
      case '파랑':
        return Colors.blue;
      case '보라':
        return Colors.purple;
      case '검정':
        return Colors.black;
      case '흰색':
      default:
        return Colors.white;
    }
  }

  // 7) 배경 불투명도
  double _getBackgroundOpacity() {
    switch (selectedBackgroundOpacity) {
      case '0%':
        return 0.0;
      case '25%':
        return 0.25;
      case '75%':
        return 0.75;
      case '100%':
        return 1.0;
      case '50%':
      default:
        return 0.5;
    }
  }
}