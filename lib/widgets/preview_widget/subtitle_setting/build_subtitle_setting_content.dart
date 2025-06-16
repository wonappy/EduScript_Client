/// 자막 언어 및 테마 설정 (Provider 연동)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/global_core.dart';
import '../subtitle_setting_provider.dart';
import 'color_setting_drop_down_widget.dart';
import 'multi_language_dropdown.dart';
import 'onoff_switch_state_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    // provider
    final settings = context.watch<SubtitleSettingsProvider>();

    return Center(
      child: Container(
        padding: EdgeInsets.all(20),
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
                      _buildScreenShareSection(),
                      _buildDivider(),
                      _buildInputLanguageSection(),
                      _buildDivider(),
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

  // [섹션 별 빌더]
  Widget _buildScreenShareSection() {
    final settings = context.read<SubtitleSettingsProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle('화면 공유 ON/OFF'),
        OnOffSwitch(
          initialValue: settings.screenSharedEnabled,
          onChanged: (bool newValue) {
            settings.updateScreenSharedEnabled(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildInputLanguageSection() {
    final settings = context.read<SubtitleSettingsProvider>();

    return Column(
      children: [
        _buildSectionTitle("음성 언어 설정"),
        SizedBox(height: 10),
        _buildBigContainer(
          child: _buildSmallContainer(
            child: MultiLanguageDropdown(
              title: "언어",
              selectedLanguages: settings.selectedInputLanguages,
              availableLanguages: inputLanguagesList,
              onChanged: (List<String> newLanguages) {
                settings.updateInputLanguages(newLanguages);
              },
              screenWidth: widget.screenWidth,
              screenHeight: widget.screenHeight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputLanguageSection() {
    final settings = context.read<SubtitleSettingsProvider>();

    return Column(
      children: [
        _buildSectionTitle("출력 언어 설정"),
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
                    settings.updateOutputLanguages(newLanguages);
                  },
                  screenWidth: widget.screenWidth,
                  screenHeight: widget.screenHeight,
                ),
              ),
              SizedBox(height: 20),
              _buildSubSection(
                title: "스타일",
                content: _buildMediumContainer(
                  child: Column(
                    children: [_buildPositionDropdown(), _buildStyleDropdown()],
                  ),
                ),
              ),
              _buildSubSection(
                title: "텍스트",
                content: _buildMediumContainer(
                  child: Column(
                    children: [_buildSizeDropdown(), _buildTextColorDropdown()],
                  ),
                ),
              ),
              _buildSubSection(
                title: "배경",
                content: _buildMediumContainer(
                  child: Column(
                    children: [
                      _buildBackgroundColorDropdown(),
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
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: getResponsiveFontSize(widget.screenWidth),
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Column(
      children: [
        SizedBox(height: 10),
        Divider(color: Colors.grey, thickness: 1, height: 1),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBigContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backContentContainerColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSmallContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: dropdownWidgetColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMediumContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: dropdownWidgetColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: Offset(0, 4),
          ),
        ],
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
        _buildSectionTitle(title),
        SizedBox(height: spacing),
        content,
        SizedBox(height: 20),
      ],
    );
  }
}
