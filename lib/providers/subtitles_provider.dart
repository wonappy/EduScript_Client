import 'package:flutter/foundation.dart';
import '../core/enum_core.dart';
import 'mode_provider.dart';

/// # 입출력 언어 설정 및 언어 매핑 관련 프로바이더
class SubtitlesProvider extends ChangeNotifier {
  List<String> _selectedInputLanguages = [];
  List<String> _selectedOutputLanguages = [];
  
  // [Getter] 선택된 언어 List 불러오기
  List<String> get selectedInputLanguages => _selectedInputLanguages;
  List<String> get selectedOutputLanguages => _selectedOutputLanguages;

  // 현재 모드 확인 (강의 or 토론)
  final ModeProvider _modeProvider;
  SubtitlesProvider(this._modeProvider);

  // 입력 언어 업데이트
  void updateInputLanguages(List<String> languages) {
    _selectedInputLanguages = languages;

    // 현재 모드 == "토론 모드"
    if (_modeProvider.currentMode == Mode.conference) {
      _selectedOutputLanguages = List.from(languages); // 출력 언어도 동기화
    }

    notifyListeners();
  }

  // 출력 언어 업데이트
  void updateOutputLanguages(List<String> languages) {
    _selectedOutputLanguages = languages;

    // 현재 모드 == "토론 모드"
    if (_modeProvider.currentMode == Mode.conference) {
      _selectedInputLanguages = List.from(languages); // 입력 언어도 동기화
    }

    notifyListeners();
  }
}