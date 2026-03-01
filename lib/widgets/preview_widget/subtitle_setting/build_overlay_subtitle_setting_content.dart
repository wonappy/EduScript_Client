import 'package:client/core/styles/color_core.dart';
import 'package:client/core/styles/style_option_core.dart';
import 'package:client/providers/language_setting_provider.dart';
import 'package:client/core/styles/size_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/global_core.dart';
import '../../../providers/mode_provider.dart';
import '../../../providers/subtitle_style_provider.dart';
import 'multi_language_dropdown.dart';
import 'onoff_switch_state_widget.dart';
import 'setting_drop_down_widget.dart';

/// ### 화면 공유(오버레이) 모드일 때, 자막 설정 창 구성 (Provider 연동)
class BuildOverlaySubtitleSettingContent extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;

  const BuildOverlaySubtitleSettingContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<BuildOverlaySubtitleSettingContent> createState() =>
      _BuildSubtitleSettingContentState();
}

class _BuildSubtitleSettingContentState
    extends State<BuildOverlaySubtitleSettingContent> {
  List<String> inputLanguagesList = GlobalCore.languageOptions;
  List<String> outputLanguagesList = GlobalCore.languageOptions;
  Color backContentContainerColor = Color(0xFFC1C1C1);
  Color dropdownWidgetColor = Color(0xFFF6F6F6);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),

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
                    SizedBox(height: 30),
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
  //1) 화면 공유 섹션
  Widget _buildScreenShareSection() {
    final settings = context.read<SubtitleStyleProvider>();

    return Column(
      children: [
        _buildSectionTitle("화면 공유"),
        SizedBox(height: 10),
        _buildBigContainer(
          child: Column(
            children: [
              _buildSmallContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "화면 공유 OFF/ON",
                      style: TextStyle(
                        fontSize: AppSizes.baseFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    OnOffSwitch(
                      initialValue: settings.screenSharedEnabled,
                      onChanged: (bool newValue) {
                        settings.updateScreenSharedEnabled(newValue);
                      },
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

  // 2) 입력 언어 설정 섹션
  Widget _buildInputLanguageSection() {
    final mode = context.watch<ModeProvider>();
    final settings = context.watch<LanguageSettingProvider>();

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
                        settings.updateInputLanguages(newLanguages, mode.currentMode); // 인식 언어 업데이트
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
    final mode = context.watch<ModeProvider>();
    final settings = context.watch<LanguageSettingProvider>();

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
                    settings.updateOutputLanguages(newLanguages, mode.currentMode); // 출력 언어 업데이트
                  },
                  screenWidth: widget.screenWidth,
                  screenHeight: widget.screenHeight,
                  isInputLanguage: false, // 인식 언어 선택 여부 (false -> 자막 언어 선택 중)
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
                      _buildAlignmentDropdown(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildSubSection(
                title: "텍스트",
                content: _buildMediumContainer(
                  child: Column(children: [_buildSizeDropdown()]),
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
    final settings = context.read<SubtitleStyleProvider>();

    return SettingDropdown(
      title: "세로 정렬",
      initialValue: settings.selectedPosition,
      options: StyleOptionCore.positionOptions,
      onChanged: (String newPosition) {
        settings.updatePosition(newPosition);
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
    );
  }

  // 1) 위치 드롭다운
  Widget _buildAlignmentDropdown() {
    final settings = context.read<SubtitleStyleProvider>();

    return SettingDropdown(
      title: "가로 정렬",
      initialValue: settings.selectedHorizontalPosition,
      options: StyleOptionCore.horizontalPositionOptions,
      onChanged: (String newPosition) {
        settings.updateHorizontalPosition(newPosition);
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
    );
  }

  // 2) 폰트 크기 드롭다운
  Widget _buildSizeDropdown() {
    final settings = context.read<SubtitleStyleProvider>();

    return SettingDropdown(
      title: "크기",
      initialValue: settings.selectedFontSize,
      options: StyleOptionCore.fontSizeOptions,
      onChanged: (String newSize) {
        settings.updateFontSize(newSize);
      },
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
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
      case '화면 공유 OFF/ON':
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

  // 구분선
  Widget _buildDivider() {
    return Column(
      children: [Divider(color: Colors.grey, thickness: 1, height: 1)],
    );
  }

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
      ],
    );
  }
}
