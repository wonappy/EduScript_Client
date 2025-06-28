import 'package:flutter/foundation.dart';

import '../core/enum_core.dart';

class ModeProvider extends ChangeNotifier {
  Mode _currentMode = Mode.lecture; // 기본값: 강의 모드

  // [Getter] 현재 모드 조회
  Mode get currentMode => _currentMode;

  // // 현재 모드 확인
  // bool get isLectureMode => _currentMode == Mode.lecture;
  // bool get isConferenceMode => _currentMode == Mode.conference;

  // [Setter] 모드 설정
  void setMode(Mode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners(); // UI 업데이트
      debugPrint("모드 변경됨: ${mode.name}");
    }
  }

  // 모드 초기화 (기본 강의 모드)
  void resetMode() {
    setMode(Mode.lecture);
    debugPrint("모드 초기화: lecture");
  }

  // 모드 전환
  void changeMode() {
    setMode(_currentMode == Mode.lecture ? Mode.conference : Mode.lecture);
  }
}
