import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../core/enum_core.dart';
import 'mode_provider.dart';
import '../models/language_mapping_model.dart';

/// ### 입출력 언어 설정 및 언어 매핑 관련 프로바이더
class LanguageSettingProvider extends ChangeNotifier {
  // 현재 모드 확인
  //final ModeProvider _mode;
  //LanguageSettingProvider(this._mode);

  // 입출력 언어 초기 상태
  List<String> _selectedInputLanguages = ['한국어'];
  List<String> _selectedOutputLanguages = ['한국어'];

  // [Getter]
  List<String> get selectedInputLanguages => _selectedInputLanguages;
  List<String> get selectedOutputLanguages => _selectedOutputLanguages;

  // 언어 매핑 테이블
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
      previewText: 'Здравствуйте! Это тестовые субтитры.',
    ),
    '포르투갈어': LanguageMappingModel(
      displayName: '포르투갈어',
      language: 'Português',
      speechCode: 'pt-BR',
      translationCode: 'pt',
      previewText: 'Olá! Escta é uma legenda de teste.',
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
    '몽골어': LanguageMappingModel(
      displayName: '몽골어',
      language: 'Монгол',
      speechCode: 'mn-MN',
      translationCode: 'mn',
      previewText: 'Сайн уу! Энэ бол текстийн хадмал гарчиг юм.',
    ),
    '네팔어': LanguageMappingModel(
      displayName: '네팔어',
      language: 'नेपाली',
      speechCode: 'ne-NP',
      translationCode: 'ne',
      previewText: 'नमस्ते! यो एउटा परीक्षण उपशीर्षक हो।',
    ),
    '크메르어(캄보디아)': LanguageMappingModel(
      displayName: '크메르어(캄보디아)',
      language: 'ខ្មែរ (កម្ពុជា)',
      speechCode: 'km-KH',
      translationCode: 'km',
      previewText: 'សួស្តី! នេះជាចំណងជើងរងសាកល្បង។',
    ),
    '우즈베크어(우즈베키스탄)': LanguageMappingModel(
      displayName: '우즈베크어(우즈베키스탄)',
      language: 'O‘zbek (O‘zbekiston)',
      speechCode: 'uz-UZ',
      translationCode: 'uz',
      previewText: 'Salom! Bu matn taglavhasi.',
    ),
    '베트남어': LanguageMappingModel(
      displayName: '베트남어',
      language: 'Tiếng Việt',
      speechCode: 'vi-VN',
      translationCode: 'vi',
      previewText: 'Xin chào! Đây là phụ đề thử nghiệm.',
    ),
  };

  // 지원 언어 목록
  static List<String> get supportedLanguages => _languageMappings.keys.toList();

  String getOutputLanguage(String lang) {
    return _languageMappings[lang]?.language ?? ' ';
  }

  // 입력 언어 코드
  List<String> getInputLanguageCodes() {
    return _selectedInputLanguages
        .map((lang) => _languageMappings[lang]?.speechCode ?? 'ko-KR')
        .toList();
  }

  // 출력 언어 코드
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

  // [Update]
  // 입력 언어 설정 변경
  void updateInputLanguages(List<String> languages, Mode mode) {
    _selectedInputLanguages = List.from(languages);

    if (mode == Mode.conference) {
      _selectedOutputLanguages = List.from(languages);
    }

    notifyListeners();
  }

  // 출력 언어 설정 변경
  void updateOutputLanguages(List<String> languages, Mode mode) {
    _selectedOutputLanguages = List.from(languages);

    if (mode == Mode.conference) {
      _selectedInputLanguages = List.from(languages);
    }

    notifyListeners();
  }

  // 미리보기 화면에 출력할 텍스트
  String getPreviewText(String language) {
    switch (language) {
      case '영어':
        return 'Hello! This is a test subtitle.';
      case '일본어':
        return 'こんにちは！テスト字幕です。';
      case '중국어':
        return '你好！这是测试字幕。';
      case '몽골어':
        return 'Сайн уу! Энэ бол текстийн хадмал гарчиг юм.';
      case '네팔어':
        return 'नमस्ते! यो एउटा परीक्षण उपशीर्षक हो।';
      case '크메르어(캄보디아)':
        return 'សួស្តី! នេះជាចំណងជើងរងសាកល្បង។';
      case '우즈베크어(우즈베키스탄)':
        return 'Salom! Bu matn taglavhasi.';
      case '러시아어':
        return 'Здравствуйте! Это тестовые субтитры.';
      case '베트남어':
        return 'Xin chào! Đây là phụ đề thử nghiệm.';
      default:
        return '안녕하세요! 텍스트 자막입니다.';
    }
  }
}
