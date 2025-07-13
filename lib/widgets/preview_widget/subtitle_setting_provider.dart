// 📁 providers/subtitle_settings_provider.dart
import 'package:client/core/styles/size_core.dart';
import 'package:flutter/material.dart';

import '../../core/global_core.dart';
import '../../core/enum_core.dart';
import '../../providers/mode_provider.dart';
import '../../models/language_mapping_model.dart';

class SubtitleSettingsProvider extends ChangeNotifier {
  // init
  bool _screenSharedEnabled = true;
  List<String> _selectedInputLanguages = ['한국어'];
  List<String> _selectedOutputLanguages = ['한국어'];
  String _selectedPosition = '중앙';
  String _selectedFontStyle = '기본';
  String _selectedFontSize = '중간';
  String _selectedFontColor = '흰색';
  String _selectedBackgroundColor = '흰색';
  String _selectedBackgroundOpacity = '50%';

  // [토론 모드일 때 언어 선택 동기화]
  // 1) 선택된 음성 언어
  // void updateInputLanguages(List<String> languages, {Mode? currentMode}) {
  //   _selectedInputLanguages = languages;
  //   // 현재 모드가 "토론 모드"일 떄
  //   if (currentMode == Mode.conference) {
  //     _selectedOutputLanguages = List.from(languages); // 출력 언어도 동기화
  //   }
  //   notifyListeners();
  // }
  //
  // // 2) 선택된 출력 언어
  // void updateOutputLanguages(List<String> languages, {Mode? currentMode}) {
  //   _selectedOutputLanguages = languages;
  //   // 현재 모드가 "토론 모드"일 때
  //   if (currentMode == Mode.conference) {
  //     _selectedInputLanguages = List.from(languages); // 입력 언어도 동기화
  //   }
  //   notifyListeners();
  // }

  // 🌐 언어 매핑 테이블
  static final Map<String, LanguageMappingModel> _languageMappings = {
    '한국어': LanguageMappingModel(
      displayName: '한국어',
      language: '한국어',
      speechCode: 'ko-KR',
      translationCode: 'ko',
      previewText: '안녕하세요! 테스트 자막입니다.',
    ),
    '영어': LanguageMappingModel(
      displayName: '영어',
      language: 'English',
      speechCode: 'en-US',
      translationCode: 'en',
      previewText: 'Hello! This is a test subtitle.',
    ),
    '일본어': LanguageMappingModel(
      displayName: '일본어',
      language: '日本語',
      speechCode: 'ja-JP',
      translationCode: 'ja',
      previewText: 'こんにちは！テスト字幕です。',
    ),
    '중국어': LanguageMappingModel(
      displayName: '중국어',
      language: '中文',
      speechCode: 'zh-CN',
      translationCode: 'zh-CN',
      previewText: '你好！这是测试字幕。',
    ),
    '독일어': LanguageMappingModel(
      displayName: '독일어',
      language: 'Deutsch',
      speechCode: 'de-DE',
      translationCode: 'de',
      previewText: 'Hallo! Dies ist ein Test-Untertitel.',
    ),
    '프랑스어': LanguageMappingModel(
      displayName: '프랑스어',
      language: 'Français',
      speechCode: 'fr-FR',
      translationCode: 'fr',
      previewText: 'Bonjour! Ceci est un sous-titre de test.',
    ),
    '스페인어': LanguageMappingModel(
      displayName: '스페인어',
      language: 'Español',
      speechCode: 'es-ES',
      translationCode: 'es',
      previewText: '¡Hola! Este es un subtítulo de prueba.',
    ),
    '이탈리아어': LanguageMappingModel(
      displayName: '이탈리아어',
      language: 'Italiano',
      speechCode: 'it-IT',
      translationCode: 'it',
      previewText: 'Ciao! Questo è un sottotitolo di prova.',
    ),
    '러시아어': LanguageMappingModel(
      displayName: '러시아어',
      language: 'Русский',
      speechCode: 'ru-RU',
      translationCode: 'ru',
      previewText: 'Привет! Это тестовые субтитры.',
    ),
    '포르투갈어': LanguageMappingModel(
      displayName: '포르투갈어',
      language: 'Português',
      speechCode: 'pt-BR',
      translationCode: 'pt',
      previewText: 'Olá! Esta é uma legenda de teste.',
    ),
    '아랍어': LanguageMappingModel(
      displayName: '아랍어',
      language: 'العربية',
      speechCode: 'ar-SA',
      translationCode: 'ar',
      previewText: 'مرحبا! هذه ترجمة تجريبية.',
    ),
    '힌디어': LanguageMappingModel(
      displayName: '힌디어',
      language: 'हिन्दी',
      speechCode: 'hi-IN',
      translationCode: 'hi',
      previewText: 'नमस्ते! यह एक परीक्षण उपशीर्षक है।',
    ),
    '태국어': LanguageMappingModel(
      displayName: '태국어',
      language: 'ภาษาไทย',
      speechCode: 'th-TH',
      translationCode: 'th',
      previewText: 'สวัสดี! นี่คือคำบรรยายทดสอบ',
    ),
    '인도네시아어': LanguageMappingModel(
      displayName: '인도네시아어',
      language: 'Bahasa Indonesia',
      speechCode: 'id-ID',
      translationCode: 'id',
      previewText: 'Halo! Ini adalah subtitle uji coba.',
    ),
    '네덜란드어': LanguageMappingModel(
      displayName: '네덜란드어',
      language: 'Nederlands',
      speechCode: 'nl-NL',
      translationCode: 'nl',
      previewText: 'Hallo! Dit is een test ondertitel.',
    ),
    '폴란드어': LanguageMappingModel(
      displayName: '폴란드어',
      language: 'Polski',
      speechCode: 'pl-PL',
      translationCode: 'pl',
      previewText: 'Cześć! To jest testowy napis.',
    ),
    '스웨덴어': LanguageMappingModel(
      displayName: '스웨덴어',
      language: 'Svenska',
      speechCode: 'sv-SE',
      translationCode: 'sv',
      previewText: 'Hej! Detta är en testundertext.',
    ),
    '핀란드어': LanguageMappingModel(
      displayName: '핀란드어',
      language: 'Suomi',
      speechCode: 'fi-FI',
      translationCode: 'fi',
      previewText: 'Hei! Tämä on testi tekstitys.',
    ),
    '덴마크어': LanguageMappingModel(
      displayName: '덴마크어',
      language: 'Dansk',
      speechCode: 'da-DK',
      translationCode: 'da',
      previewText: 'Hej! Dette er en test undertekst.',
    ),
  };

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

  //지원 언어 목록
  static List<String> get supportedLanguages => _languageMappings.keys.toList();

  // 표시명 -> 언어 코드
  // String getInputLanguageCode() {
  //   if (_selectedInputLanguages.isEmpty) return 'ko-KR'; //디폴트 한국어
  //   final mapping = _languageMappings[_selectedInputLanguages.first];
  //   return mapping?.speechCode ?? 'ko-KR';
  // }

  String getOutputLanguage(String lang) {
    return _languageMappings[lang]?.language ?? ' ';
  }

  List<String> getInputLanguageCodes() {
    return _selectedInputLanguages
        .map((lang) => _languageMappings[lang]?.speechCode ?? 'ko-KR')
        .toList();
  }

  List<String> getOutputLanguageCodes() {
    return _selectedOutputLanguages
        .map((lang) => _languageMappings[lang]?.translationCode ?? 'ko')
        .toList();
  }

  // 언어 코드 -> 표시명
  String getDisplayNameFromAzureCode(String azureCode) {
    for (final entry in _languageMappings.entries) {
      if (entry.value.speechCode == azureCode) {
        return entry.key;
      }
    }
    return azureCode;
  }

  String getDisplayNameFromGoogleCode(String googleCode) {
    for (final entry in _languageMappings.entries) {
      if (entry.value.translationCode == googleCode) {
        return entry.key;
      }
    }
    return googleCode;
  }

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
    double baseSize = AppSizes.smallFontSize;
    switch (_selectedFontSize) {
      case '작게':
        return baseSize * 1.0;
      case '크게':
        return baseSize * 1.4;
      case '매우 크게':
        return baseSize * 1.7;
      case '중간':
      default:
        return baseSize * 1.2;
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
