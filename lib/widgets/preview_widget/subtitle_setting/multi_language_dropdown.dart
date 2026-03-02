import 'package:client/core/enum_core.dart';
import 'package:client/core/styles/color_core.dart';
import 'package:client/core/styles/size_core.dart';
import 'package:client/providers/mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'multi_language_select_dialog.dart';

/// ### 언어 다중 선택 드롭다운
// 드롭다운 위젯
class MultiLanguageDropdown extends StatelessWidget {
  final String title;
  final List<String> selectedLanguages;
  final List<String> availableLanguages;
  final Function(List<String>) onChanged;
  final double screenWidth;
  final double screenHeight;
  final Color? backgroundColor;
  final bool isInputLanguage;

  const MultiLanguageDropdown({
    super.key,
    required this.title,
    required this.selectedLanguages,
    required this.availableLanguages,
    required this.onChanged,
    required this.screenWidth,
    required this.screenHeight,
    this.backgroundColor,
    this.isInputLanguage = false,
  });

  String _getDisplayText() {
    if (selectedLanguages.isEmpty) {
      return '언어를 선택하세요';
    } else if (selectedLanguages.length == 1) {
      return selectedLanguages.first;
    } else {
      return '${selectedLanguages.first} 외 ${selectedLanguages.length - 1}개';
    }
  }

  void _showLanguageDialog(BuildContext context) async {
    final mode = Provider.of<ModeProvider>(context, listen: false).currentMode;
    final bool isLectureMode = mode == Mode.lecture; // 강의 모드 true, 토론 모드 false

    final result = await showDialog<List<String>>(
      context: context,
      builder:
          (context) => MultiLanguageSelectDialog(
            availableLanguages: availableLanguages,
            selectedLanguages: selectedLanguages,
            isLectureMode: isLectureMode,     // bool
            isInputLanguage: isInputLanguage, // bool
          ),
    );

    debugPrint("[DEBUG] 현재 선택된 언어 - ${result}");

    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor1,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppSizes.baseFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          InkWell(
            onTap: () => _showLanguageDialog(context),
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getDisplayText(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: AppSizes.baseFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: AppSizes.baseIconSize,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}