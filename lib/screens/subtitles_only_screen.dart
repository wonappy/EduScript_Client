//자막 (프롬프트 느낌 ver)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:html/parser.dart' as html_parser;

import '../core/enum_core.dart';
import '../providers/mode_provider.dart';
import '../services/websocket_stt_service.dart';
import '../widgets/preview_widget/subtitle_setting_provider.dart';

class SubtitlesOnlyScreen extends StatefulWidget {
  final Color backgroundColor; // 배경 색상
  final String subWordFont; //자막 글꼴
  final double subSpacing; //자막 간 간격

  const SubtitlesOnlyScreen({
    super.key,
    required this.backgroundColor,
    required this.subWordFont,
    required this.subSpacing,
  });

  @override
  State<SubtitlesOnlyScreen> createState() => _SubtitlesOnlyScreenState();
}

class _SubtitlesOnlyScreenState extends State<SubtitlesOnlyScreen> {
  final WebSocketSTTService _sttService = WebSocketSTTService();

  Map<String, String> _currentTranslations = {};

  @override
  void initState() {
    super.initState();

    // STT 서비스 -> 번역 결과 콜백 등록
    _sttService.onTranslationReceived = (translations) {
      if (mounted) {
        setState(() {
          // 번역 결과를 로컬 상태로 복사
          _currentTranslations.clear(); //현재 자막 초기화
          translations.forEach((lang, result) {
            //각 언어 자막 저장
            _currentTranslations[lang] = result.resultText;
          });
        });

        debugPrint("자막 화면 업데이트: ${_currentTranslations.length}개 언어");
      }
    };

    // 초기 상태 로드
    _currentTranslations = Map.from(_sttService.currentTranslations);
  }

  @override
  void dispose() {
    // 콜백 해제
    if (_sttService.onTranslationReceived != null) {
      _sttService.onTranslationReceived = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SubtitleSettingsProvider>(); //자막 출력
    final languages = settings.selectedOutputLanguages; //선택된 출력 언어 목록 가져오기

    // 디버그: Provider 설정 확인
    debugPrint("🔍 Provider 설정:");
    debugPrint("  - 선택된 출력 언어: $languages");
    debugPrint("  - 출력 언어 코드: ${settings.getOutputLanguageCodes()}");
    debugPrint("  - 현재 번역 결과 키: ${_currentTranslations.keys.toList()}");

    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: screenWidth,
            height: screenHeight,
            color: widget.backgroundColor, //배경 색상 지정
            child: Column(
              mainAxisAlignment: settings.getAlignment(),
              children: [
                for (int i = 0; i < languages.length; i++)
                  Column(
                    children: [
                      SizedBox(height: 10), //자막 간 간격 지정
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        width: screenWidth * 0.95,
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.5,
                        ),
                        //최대 자막 컨테이너 높이
                        decoration: BoxDecoration(
                          color: settings.getBackgroundColor().withValues(
                            //자막 배경 색상 지정
                            alpha:
                                settings.getBackgroundOpacity(), //자막 배경 불투명도 지정
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getSubtitleText(languages[i], settings), //자막 내용 지정
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: settings.getFontColor(), //자막 글자 색상 지정
                            fontSize: settings.getFontSize(
                              screenWidth,
                            ), //자막 글자 크기 지정
                            fontWeight: settings.getFontWeight(),
                            fontStyle: settings.getFontStyle(),
                            textBaseline: null,
                          ),
                        ),
                      ),
                      SizedBox(height: 10), //자막 간 간격 지정
                    ],
                  ),
              ],
            ),
          ),

          // // 📊 디버그 정보 (개발용)
          // if (kDebugMode)
          //   Positioned(top: 50, left: 16, child: _buildDebugInfo()),
          Positioned(
            bottom: 16,
            right: 16,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close_rounded),
              iconSize: 32,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 자동 언어 매핑 함수
  String? _findServerKeyForLanguage(
    String displayLanguage,
    SubtitleSettingsProvider settings,
  ) {
    debugPrint("자막 언어 매핑 중...");
    // 1) 먼저 Provider의 일반적인 매핑 확인 (Google Translation 코드)
    final outputLanguages = settings.selectedOutputLanguages;
    final outputCodes = settings.getOutputLanguageCodes();

    String? googleCode;
    for (int i = 0; i < outputLanguages.length; i++) {
      if (outputLanguages[i] == displayLanguage && i < outputCodes.length) {
        googleCode = outputCodes[i];
        break;
      }
    }

    // 2) 서버 응답 키들 중에서 매칭되는 것 찾기
    final availableKeys = _currentTranslations.keys.toList();
    String? serverKey;

    // 2-1) 언어명으로 역추적 (Provider 매핑 테이블 활용)
    for (String key in availableKeys) {
      // Azure 코드로 표시명 확인
      String azureDisplayName = settings.getDisplayNameFromAzureCode(key);
      if (azureDisplayName == displayLanguage) {
        return key;
      }

      // Google 코드로 표시명 확인
      String googleDisplayName = settings.getDisplayNameFromGoogleCode(key);
      if (googleDisplayName == displayLanguage) {
        return key;
      }
    }

    // 🎯 폴백: 기본 매핑도 시도 (여기에 추가!)
    if (googleCode != null) {
      if (availableKeys.contains(googleCode)) {
        serverKey = googleCode;
        debugPrint("🔄 폴백 매핑 성공: '$displayLanguage' → '$googleCode'");
      }
    }

    // 🎯 추가 폴백: 부분 매칭도 시도
    if (serverKey == null && googleCode != null) {
      for (String key in availableKeys) {
        // ko와 ko-KR 매칭
        if (key.startsWith(googleCode) || googleCode.startsWith(key)) {
          serverKey = key;
          debugPrint("🔄 부분 매핑 성공: '$displayLanguage' ($googleCode) → '$key'");
          break;
        }
        // ko-KR과 ko 매칭
        if (key.contains('-') && key.split('-')[0] == googleCode) {
          serverKey = key;
          debugPrint("🔄 접두사 매핑 성공: '$displayLanguage' ($googleCode) → '$key'");
          break;
        }
      }
    }

    // 🎯 최종 폴백: 어떤 경우든 부분 일치(앞, 뒤, 포함) 시도
    if (serverKey == null && googleCode != null) {
      for (String key in availableKeys) {
        if (key.contains(googleCode) || googleCode.contains(key)) {
          serverKey = key;
          debugPrint("🔄 최종 부분 매핑: '$displayLanguage' ($googleCode) ↔ '$key'");
          break;
        }
      }
    }

    return null;
  }

  // 언어별 자막 반환 (자동 매핑 사용)
  String _getSubtitleText(String language, SubtitleSettingsProvider settings) {
    // 자동 매핑으로 서버 키 찾기
    String? serverKey = _findServerKeyForLanguage(language, settings);

    // 디버그: 매핑 결과 확인
    debugPrint("🔍 자동 매핑: '$language' → '$serverKey'");

    // 번역 결과 확인
    if (serverKey != null &&
        _currentTranslations.containsKey(serverKey) &&
        _currentTranslations[serverKey]!.isNotEmpty) {
      debugPrint("✅ '$serverKey' 번역 결과 찾음");

      // HTML 디코딩 (return 하기 전에!)
      String rawText = _currentTranslations[serverKey]!;
      var document = html_parser.parse(rawText);
      String processedText = document.documentElement?.text ?? rawText;

      // 디버그: 처리 전후 비교
      if (rawText != processedText) {
        debugPrint(" HTML 디코딩:");
        debugPrint("  원본: $rawText");
        debugPrint("  처리: $processedText");
      }

      return processedText; // ← 디코딩된 텍스트 반환
    }

    // STT 서비스 상태에 따른 메시지
    if (_sttService.isRecording) {
      return "...";
    } else if (_sttService.isSessionReady) {
      return "...";
    } else if (_sttService.isConnected) {
      return "...";
    } else {
      return "...";
    }
  }

  // 디버그 정보 표시
  // Widget _buildDebugInfo() {
  //   final transcriptCount = _sttService.transcriptHistory.length;
  //   final settings = context.watch<SubtitleSettingsProvider>();
  //
  //   return Positioned(
  //     top: 50,
  //     left: 16,
  //     child: Container(
  //       padding: const EdgeInsets.all(8),
  //       decoration: BoxDecoration(
  //         color: Colors.black54,
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             "🔗 연결: ${_sttService.isConnected ? '✅' : '❌'}",
  //             style: const TextStyle(color: Colors.white, fontSize: 12),
  //           ),
  //           Text(
  //             "🎤 세션: ${_sttService.isSessionReady ? '✅' : '❌'}",
  //             style: const TextStyle(color: Colors.white, fontSize: 12),
  //           ),
  //           Text(
  //             "📡 녹음: ${_sttService.isRecording ? '✅' : '❌'}",
  //             style: const TextStyle(color: Colors.white, fontSize: 12),
  //           ),
  //           Text(
  //             "🌐 번역: ${_currentTranslations.length}개",
  //             style: const TextStyle(color: Colors.white, fontSize: 12),
  //           ),
  //           Text(
  //             "📝 원문: $transcriptCount개",
  //             style: const TextStyle(color: Colors.white, fontSize: 12),
  //           ),
  //           // 🎯 추가 디버그 정보
  //           Text(
  //             "🎯 Provider: ${settings.selectedOutputLanguages}",
  //             style: const TextStyle(color: Colors.white, fontSize: 10),
  //           ),
  //           Text(
  //             "🎯 코드: ${settings.getOutputLanguageCodes()}",
  //             style: const TextStyle(color: Colors.white, fontSize: 10),
  //           ),
  //           Text(
  //             "🎯 결과키: ${_currentTranslations.keys.toList()}",
  //             style: const TextStyle(color: Colors.white, fontSize: 10),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
