// 📁 providers/subtitle_settings_provider.dart
import 'package:flutter/material.dart';

import '../../core/global_core.dart';

class SubtitleSettingsProvider extends ChangeNotifier {
  // init
  bool _screenSharedEnabled = true;
  List<String> _selectedInputLanguages = ['한국어'];
  List<String> _selectedOutputLanguages = ['한국어'];
  String _selectedPosition = '하단';
  String _selectedFontStyle = '기본';
  String _selectedFontSize = '중간';
  String _selectedFontColor = '흰색';
  String _selectedBackgroundColor = '흰색';
  String _selectedBackgroundOpacity = '50%';

  // getter
  bool get screenSharedEnabled => _screenSharedEnabled;
  List<String> get selectedInputLanguages => _selectedInputLanguages;
  List<String> get selectedOutputLanguages => _selectedOutputLanguages;
  String get selectedPosition => _selectedPosition;
  String get selectedFontStyle => _selectedFontStyle;
  String get selectedFontSize => _selectedFontSize;
  String get selectedFontColor => _selectedFontColor;
  String get selectedBackgroundColor => _selectedBackgroundColor;
  String get selectedBackgroundOpacity => _selectedBackgroundOpacity;

  // update
  void updateScreenSharedEnabled(bool enabled) {
    _screenSharedEnabled = enabled;
    notifyListeners(); // 👈 UI에게 "데이터 바뀌었어!" 알림
  }

  void updateInputLanguages(List<String> languages) {
    _selectedInputLanguages = languages;
    notifyListeners();
  }

  void updateOutputLanguages(List<String> languages) {
    _selectedOutputLanguages = languages;
    notifyListeners();
  }

  void updatePosition(String position) {
    _selectedPosition = position;
    notifyListeners();
  }

  void updateFontStyle(String style) {
    _selectedFontStyle = style;
    notifyListeners();
  }

  void updateFontSize(String size) {
    _selectedFontSize = size;
    notifyListeners();
  }

  void updateFontColor(String color) {
    _selectedFontColor = color;
    notifyListeners();
  }

  void updateBackgroundColor(String color) {
    _selectedBackgroundColor = color;
    notifyListeners();
  }

  void updateBackgroundOpacity(String opacity) {
    _selectedBackgroundOpacity = opacity;
    notifyListeners();
  }

  // get 함수
  String getPreviewText(String language) {
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

  MainAxisAlignment getAlignment() {
    switch (_selectedPosition) {
      case '상단':
        return MainAxisAlignment.start;
      case '중앙':
        return MainAxisAlignment.center;
      case '하단':
      default:
        return MainAxisAlignment.end;
    }
  }

  FontWeight getFontWeight() {
    return _selectedFontStyle == '굵게' ? FontWeight.bold : FontWeight.normal;
  }

  FontStyle getFontStyle() {
    return _selectedFontStyle == '이탤릭' ? FontStyle.italic : FontStyle.normal;
  }

  double getFontSize(double screenWidth) {
    double baseSize = getResponsiveFontSize(screenWidth);
    switch (_selectedFontSize) {
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

  Color getFontColor() {
    switch (_selectedFontColor) {
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

  Color getBackgroundColor() {
    switch (_selectedBackgroundColor) {
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

  double getBackgroundOpacity() {
    switch (_selectedBackgroundOpacity) {
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
