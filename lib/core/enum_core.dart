///자막 모드
library;
// enum Mode {
//   subtitleOnly,
//   sharingSubtitle,
// } //subtitleOnly : 프롬프트 모드, sharingSubtitle : 화면공유 + 자막 모드

enum Mode {
  lecture, // 강의 모드
  conference, // 회의 모드
}

//자막 언어 종류
enum Language { en, ko, jp }

// [서버 웹소켓 연결 상태]
enum ServerConnectionState {
  connected,    // 정상 연결
  disconnected, // 연결 끊김
  reconnecting, // 재연결 시도
  failed        // 연결 실패 (최대 재시도 초과)
}

enum LanguageDialogType {
  inputLanguage,   // 음성 언어
  outputLanguage,  // 자막 언어
}