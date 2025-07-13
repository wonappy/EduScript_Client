/// 자막 언어 및 테마 설정 (Provider 연동)
library;

import 'package:client/core/enum_core.dart';
import 'package:client/core/styles/color_core.dart';
import 'package:client/providers/mode_provider.dart';
import 'package:client/core/styles/size_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../subtitle_setting_provider.dart';
import 'color_setting_drop_down_widget.dart';
import 'multi_language_dropdown.dart';
import 'setting_drop_down_widget.dart';

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
  // bool screenSharedEnabled = true;
  // List<String> selectedInputLanguages = ['한국어'];
  // List<String> selectedOutputLanguages = ['한국어'];
  // String selectedPosition = '하단';
  // String selectedFontStyle = '기본';
  // String selectedFontSize = '중간';
  // String selectedFontColor = '흰색';
  // String selectedBackgroundColor = '흰색';
  // String selectedBackgroundOpacity = '50%';

  List<String> inputLanguagesList = ['한국어', '영어', '일본어', '중국어'];
  List<String> outputLanguagesList = ['한국어', '영어', '일본어', '중국어'];
  Color backContentContainerColor = Color(0xFFC1C1C1);
  Color dropdownWidgetColor = Color(0xFFF6F6F6);
  // 색상 상수 추가
  // static const Color primaryColor = Color(0xFF2196F3);
  // static const Color surfaceColor = Color(0xFFF8F9FA);
  // static const Color cardColor = Colors.white;
  // static const Color shadowColor = Color(0x1A000000);

  @override
  Widget build(BuildContext context) {
    // provider
    //final settings = context.watch<SubtitleSettingsProvider>();

    return Container(
      decoration: BoxDecoration(
        //color: Color(0xFFE8EAED),
        borderRadius: BorderRadius.circular(15),
        //   gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    //_buildScreenShareSection(),
                    //SizedBox(height: 30),
                    _buildInputLanguageSection(),
                    SizedBox(height: 25),
                    _buildOutputLanguageSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [섹션 별 빌더]
  // 1) 화면 공유 섹션
  // Widget _buildScreenShareSection() {
  //   final settings = context.read<SubtitleSettingsProvider>();
  //
  //   return Column(
  //     children: [
  //       _buildSectionTitle("화면 공유"),
  //       SizedBox(height: 10,),
  //       _buildBigContainer(
  //         child: Column(
  //           children: [
  //             _buildSmallContainer(
  //               child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   //_buildSectionTitle('화면 공유 ON/OFF'),
  //                   Text("화면 공유 ON/OFF",
  //                   style: TextStyle(
  //                     fontSize: getResponsiveFontSize(widget.screenWidth) * 0.8,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.black,
  //                   ),),
  //                   OnOffSwitch(
  //                     initialValue: settings.screenSharedEnabled,
  //                     onChanged: (bool newValue) {
  //                       settings.updateScreenSharedEnabled(newValue);
  //                     },
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // 2) 입력 언어 설정 섹션
  Widget _buildInputLanguageSection() {
    final settings = context.read<SubtitleSettingsProvider>();

    return Column(
      children: [
        _buildSectionTitle("음성 언어 설정"),
        SizedBox(height: 10),
        _buildBigContainer(
          child: Column(
            children: [
              _buildSmallContainer(
                child: Column(
                  children: [
                    MultiLanguageDropdown(
                      title: "언어",
                      selectedLanguages: settings.selectedInputLanguages,
                      availableLanguages: inputLanguagesList,
                      onChanged: (List<String> newLanguages) {
                        settings.updateInputLanguages(newLanguages); // 음성 언어 선택
                        final currentMode =
                            context.read<ModeProvider>().currentMode;
                        if (currentMode == Mode.conference) {
                          // 토론 모드일 때
                          settings.updateOutputLanguages(
                            newLanguages,
                          ); // 음성 언어 = 자막 언어
                        }
                      },
                      screenWidth: widget.screenWidth,
                      screenHeight: widget.screenHeight,
                      isInputLanguage: true, // 음성 언어 선택 여부
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3) 출력 언어 설정 섹션
  Widget _buildOutputLanguageSection() {
    final settings = context.read<SubtitleSettingsProvider>();

    return Column(
      children: [
        _buildSectionTitle("자막 설정"),
        SizedBox(height: 10),
        _buildBigContainer(
          child: Column(
            children: [
              _buildSmallContainer(
                child: MultiLanguageDropdown(
                  title: "언어",
                  selectedLanguages: settings.selectedOutputLanguages,
                  availableLanguages: outputLanguagesList,
                  onChanged: (List<String> newLanguages) {
                    settings.updateOutputLanguages(newLanguages); // 자막 언어 설정
                    final currentMode =
                        context.read<ModeProvider>().currentMode;
                    if (currentMode == Mode.conference) {
                      // 토론 모드 시
                      settings.updateInputLanguages(
                        newLanguages,
                      ); // 자막 언어 = 음성 언어
                    }
                  },
                  screenWidth: widget.screenWidth,
                  screenHeight: widget.screenHeight,
                  isInputLanguage: false, // 음성 언어 선택 여부 (false -> 자막 언어 선택 중)
                ),
              ),
              SizedBox(height: 20),
              _buildSubSection(
                title: "스타일",
                content: _buildMediumContainer(
                  child: Column(
                    children: [
                      _buildPositionDropdown(),
                      _buildDivider(),
                      _buildStyleDropdown(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildSubSection(
                title: "텍스트",
                content: _buildMediumContainer(
                  child: Column(
                    children: [
                      _buildSizeDropdown(),
                      _buildDivider(),
                      _buildTextColorDropdown(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildSubSection(
                title: "배경",
                content: _buildMediumContainer(
                  child: Column(
                    children: [
                      _buildBackgroundColorDropdown(),
                      _buildDivider(),
                      _buildOpacityDropdown(),
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

  // [개별 드롭다운] - 모두 Provider 연결
  // 1) 위치 드롭다운
  Widget _buildPositionDropdown() {
    final settings = context.read<SubtitleSettingsProvider>();

    return SettingDropdown(
      title: "위치",
      initialValue: settings.selectedPosition,
      options: ["상단", "중앙", "하단"],
      onChanged: (String newPosition) {
        settings.updatePosition(newPosition);
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
    );
  }

  // 2) 스타일 드롭다운
  Widget _buildStyleDropdown() {
    final settings = context.read<SubtitleSettingsProvider>();

    return SettingDropdown(
      title: "스타일",
      initialValue: settings.selectedFontStyle,
      options: ["기본", "굵게", "이탤릭"],
      onChanged: (String newStyle) {
        settings.updateFontStyle(newStyle);
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
    );
  }

  // 3) 폰트 사이즈 드롭다운
  Widget _buildSizeDropdown() {
    final settings = context.read<SubtitleSettingsProvider>();

    return SettingDropdown(
      title: "크기",
      initialValue: settings.selectedFontSize,
      options: ["작게", "중간", "크게", "매우 크게"],
      onChanged: (String newSize) {
        settings.updateFontSize(newSize);
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
    );
  }

  // 4) 폰트 색상 드롭다운
  Widget _buildTextColorDropdown() {
    final settings = context.read<SubtitleSettingsProvider>();

    return ColorSettingDropDown(
      title: "색상",
      initialValue: settings.selectedFontColor,
      options: ["빨강", "주황", "노랑", "초록", "파랑", "보라", "검정", "흰색"],
      onChanged: (String newColor) {
        settings.updateFontColor(newColor);
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
      isColorSelector: true,
    );
  }

  // 5) 폰트 배경색 드롭다운
  Widget _buildBackgroundColorDropdown() {
    final settings = context.read<SubtitleSettingsProvider>();

    return ColorSettingDropDown(
      title: "색상",
      initialValue: settings.selectedBackgroundColor,
      options: ["빨강", "주황", "노랑", "초록", "파랑", "보라", "검정", "흰색"],
      onChanged: (String newColor) {
        settings.updateBackgroundColor(newColor);
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
      isColorSelector: true,
    );
  }

  // 6) 배경색 불투명도 드롭다운
  Widget _buildOpacityDropdown() {
    final settings = context.read<SubtitleSettingsProvider>();

    return ColorSettingDropDown(
      title: "불투명도",
      initialValue: settings.selectedBackgroundOpacity,
      options: ["0%", "25%", "50%", "75%", "100%"],
      onChanged: (String newOpacity) {
        settings.updateBackgroundOpacity(newOpacity);
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
      isColorSelector: false,
    );
  }

  // [공통 UI 위젯들] - 기존과 동일
  // 섹션 타이틀
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Icon(_getSectionIcon(title), color: AppColors.blueColor2, size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.titleFontSize,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // 섹션 타이틀 아이콘
  IconData _getSectionIcon(String title) {
    switch (title) {
      case '화면 공유 ON/OFF':
        return Icons.screen_share;
      case '음성 언어 설정':
        return Icons.mic;
      case '출력 언어 설정':
        return Icons.subtitles;
      default:
        return Icons.settings;
    }
  }

  // 서브 섹션 타이틀
  Widget _buildSubSectionTitle(String title) {
    return Row(
      children: [
        // Icon(
        //   _getSubSectionIcon(title),
        //   color: primaryColor,
        //   size: 16,
        // ),
        //SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.baseFontSize,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // // 서브 섹션 타이틀 옆 아이콘
  // IconData _getSubSectionIcon(String title) {
  //   switch (title) {
  //     case '스타일':
  //       return Icons.style;
  //     case '텍스트':
  //       return Icons.text_fields;
  //     case '배경':
  //       return Icons.wallpaper;
  //     default:
  //       return Icons.settings;
  //   }
  // }

  // 구분선
  Widget _buildDivider() {
    return Column(
      children: [Divider(color: Colors.grey, thickness: 1, height: 1)],
    );
  }

  // // 배경 컨테이너
  // Widget _buildBackContainer({required Widget child}) {
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
  //     decoration: BoxDecoration(
  //       color: Color(0xFFF5F6F8),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
  //     ),
  //     child: child,
  //   );
  // }

  // 큰 컨테이너
  Widget _buildBigContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(7),
      ),
      child: child,
    );
  }
  
  // 작은 컨테이너
  Widget _buildSmallContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.whiteColor1,
        borderRadius: BorderRadius.circular(7),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.2),
        //     blurRadius: 3,
        //     offset: Offset(0, 4),
        //   ),
        // ],
      ),
      child: child,
    );
  }

  // 중앙 컨테이너
  Widget _buildMediumContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.whiteColor1,
        borderRadius: BorderRadius.circular(8),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.05),
        //     blurRadius: 4,
        //     offset: Offset(0, 1),
        //   ),
        // ],
      ),
      child: child,
    );
  }

  Widget _buildSubSection({
    required String title,
    required Widget content,
    double spacing = 10,
  }) {
    return Column(
      children: [
        _buildSubSectionTitle(title),
        SizedBox(height: spacing),
        content,
        // SizedBox(height: 20),
      ],
    );
  }
}
