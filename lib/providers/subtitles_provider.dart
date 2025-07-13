import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../core/enum_core.dart';
import 'mode_provider.dart';

class SubtitlesProvider extends ChangeNotifier {
  // [변수] 선택된 언어 저장
  List<String> _selectedInputLanguages = [];
  List<String> _selectedOutputLanguages = [];
  // [Getter] 선택된 언어 불러오기
  List<String> get selectedInputLanguages => _selectedInputLanguages;
  List<String> get selectedOutputLanguages => _selectedOutputLanguages;

  // 현재 모드 확인 (강의 or 토론)
  final ModeProvider _modeProvider;
  SubtitlesProvider(this._modeProvider);

  // 1) 선택된 음성 언어
  void updateInputLanguages(List<String> languages) {
    _selectedInputLanguages = languages;

    // 현재 모드가 "토론 모드"일 떄
    if (_modeProvider.currentMode == Mode.conference) {
      _selectedOutputLanguages = List.from(languages); // 출력 언어도 동기화
    }

    notifyListeners();
  }

  // 2) 선택된 출력 언어
  void updateOutputLanguages(List<String> languages) {
    _selectedOutputLanguages = languages;

    // 현재 모드가 "토론 모드"일 때
    if (_modeProvider.currentMode == Mode.conference) {
      _selectedInputLanguages = List.from(languages); // 입력 언어도 동기화
    }

    notifyListeners();
  }
}