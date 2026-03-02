import 'dart:async';
import 'package:client/core/styles/color_core.dart';
import 'package:client/providers/language_setting_provider.dart';
import 'package:client/widgets/common/ready_received_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:html/parser.dart' as html_parser;
import '../core/enum_core.dart';
import '../core/styles/size_core.dart';
import '../providers/mode_provider.dart';
import '../services/websocket_multiple_speech_service.dart';
import '../services/websocket_single_speech_service.dart';
import '../providers/subtitle_style_provider.dart';
import '../widgets/common/connection_status_bar_widget.dart';

/// ### 자막 (프롬프트 느낌 ver)
class SubtitlesOnlyScreen extends StatefulWidget {
  final Color backgroundColor; // 배경 색상
  final String subWordFont; // 자막 글꼴
  final double subSpacing; // 자막 간 간격

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
  late dynamic _sttService; // 두 타입을 모두 받을 수 있게 dynamic 또는 공통 인터페이스 사용
  Map<String, String> _confirmedTranslations =
      {}; // 이전 완전 결과 저장 { "en": "Hello" }
  Map<String, String> _currentTranslations = {}; // 번역 결과 저장 { "en": "Hello" }

  static double referenceScreenWidth = 1167.0;
  bool _dialogShown = false;

  // 현재 발화 언어 (multi모드)
  String? _currentSpeakingLanguage;

  // [재연결 상태 변수]
  ServerConnectionState _serverConnectionState =
      ServerConnectionState.connected; // 서버 연결 상태
  String _statusMessage = ""; // 연결 상태 메시지 -> UI 화면에 출력
  int _reconnectAttempts = 0; // 재연결 시도 횟수

  // 음성 인식 중 상태 변수 (recognizing true : 음성 인식 중, recognizing false : 음성 인식 x )
  bool _recognizing = false;
  // ... 애니메이션
  int _dotCount = 0;
  Timer? _dotTimer;
  static const int _dotTimerMilleSecond = 200;
  // 음성 인식 중 출력 타이머
  Timer? _recognizingTimer;
  static const int _recognizingTimerMilleSecond = 400;

  @override
  void initState() {
    super.initState();
    debugPrint("[INIT] initState 메서드 실행");

    // 1) 모드에 따른 서비스 할당
    // 현재 선택된 모드
    final mode = Provider.of<ModeProvider>(context, listen: false).currentMode;

    // 강의 모드
    if (mode == Mode.lecture) {
      _sttService = Provider.of<WebSocketSingleSpeechService>(
        context,
        listen: false,
      );
      debugPrint("[INIT] 강의 모드 서비스 할당됨");
    }
    // 회의 모드
    else {
      _sttService = Provider.of<WebSocketMultipleSpeechService>(
        context,
        listen: false,
      );
      debugPrint("[INIT] 회의 모드 서비스 할당됨");
    }

    // 2) 콜백 설정
    _setupCallbacks();

    // 3) 화면이 그려진 직후, 딱 한 번만 서비스 시작 요청
    debugPrint("[INIT] PostFrameCallback 등록");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("[INIT] PostFrameCallback 실행됨");
      debugPrint("[INIT] _initAndStartService 호출 시작");
      _initAndStartService();
    });

    //음성 인식 점 갯수 애니메이션 적용
    _dotTimer = Timer.periodic(
      const Duration(milliseconds: _dotTimerMilleSecond),
      (timer) {
        if (mounted && _recognizing) {
          setState(() {
            _dotCount = (_dotCount + 1) % 3;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    // 타이머
    _dotTimer?.cancel();
    _recognizingTimer?.cancel();
    // 콜백 해제
    if (_sttService.onTranslationReceived != null) {
      _sttService.onTranslationReceived = null;
    }
    _sttService.onStatusUpdate = null;
    _sttService.onError = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<LanguageSettingProvider>(); // 언어 List 프로바이더
    final languages = settings.selectedOutputLanguages; // 선택된 출력 언어 List 가져오기
    final styles = context.watch<SubtitleStyleProvider>(); // 자막 스타일 프로바이더

    // [DEBUG] Provider 설정 확인
    debugPrint("Provider 설정:");
    debugPrint("  - 선택된 출력 언어: $languages");
    debugPrint("  - 출력 언어 코드: ${settings.getOutputLanguageCodes()}");
    debugPrint("  - 현재 번역 결과 키: ${_currentTranslations.keys.toList()}");

    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final double scaleFactor = screenWidth / referenceScreenWidth;

    return Scaffold(
      body: Stack(
        children: [
          // 1) 자막 컨테이너
          Container(
            width: screenWidth,
            height: screenHeight,
            color: AppColors.blackColor, //배경 색상 지정
            child: Column(
              mainAxisAlignment: styles.getAlignment(),
              children: [
                for (int i = 0; i < languages.length; i++)
                  Column(
                    children: [
                      SizedBox(height: 15 * scaleFactor), //자막 간 간격 지정
                      //recognized 자막
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * scaleFactor,
                          vertical: 10 * scaleFactor,
                        ),
                        width: screenWidth * 0.95,
                        decoration: BoxDecoration(
                          color: styles.getBackgroundColor().withValues(
                            //자막 배경 색상 지정
                            alpha:
                                styles.getBackgroundOpacity() *
                                0.6, //현재 자막의 60% 정도 투명도
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _getSubtitleText(
                            languages[i],
                            settings,
                            true,
                          ), //자막 내용 지정
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: styles.getFontColor(), //자막 글자 색상 지정
                            fontSize:
                                styles.getFontSize(screenWidth) *
                                scaleFactor, //자막 글자 크기 지정
                            fontWeight: styles.getFontWeight(),
                            fontStyle: styles.getFontStyle(),
                            textBaseline: null,
                          ),
                        ),
                      ),
                      SizedBox(height: 15 * scaleFactor), //자막 간 간격 지정
                    ],
                  ),
              ],
            ),
          ),
          // 2) 연결 상태 표시바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              child: ConnectionStatusBar(
                //[위젯] 로딩 스피너
                serverConnectionState: _serverConnectionState,
                statusMessage: _statusMessage,
                reconnectAttempts: _reconnectAttempts,
              ),
            ),
          ),

          // 3) 발화 인식 중 표시
          Positioned(
            bottom: 16,
            left: 16,
            child: SizedBox(
              child: Text(
                _recognizing ? _recognizingText() : " ", //음성 인식 중 표시
                style: TextStyle(
                  color: Colors.white60, //자막 글자 색상 지정
                  fontSize:
                      AppSizes.smallFontSize * 1.5 * scaleFactor, //자막 글자 크기 지정
                  fontWeight: FontWeight.normal,
                  textBaseline: null,
                ),
              ),
            ),
          ),

          // 4) Close 아이콘
          Positioned(
            bottom: 16,
            right: 16,
            child: IconButton(
              onPressed: () async {
                debugPrint("[자막 ONLY 모드] Close 버튼 클릭");

                // 1) Close 버튼 클릭 후, 녹음 일시 정지
                if (_sttService != null) {
                  await _sttService.stopRecording();
                  debugPrint("[자막 ONLY 모드] Close 버튼 클릭 후, 녹음 일시 정지");
                }

                // 2) 이전 화면으로 전환 (녹음 일시 정지가 완료되면)
                // 화면 전환 + 상태 변화 전달
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.close_rounded),
              iconSize: 32,
            ),
          ),
        ],
      ),
    );
  }

  //음성 인식 중... 글자 애니메이션
  String _recognizingText() {
    String dot = "." * (_dotCount + 1);
    String result = "음성 인식 중$dot";
    return result;
  }

  //음성 인식 중... 출력 상태 (Timer를 통해 _recognizing = false 상태가 1초 이상 지속되면 지워짐)
  void _updateRecognizingState() {
    // 기존 타이머 취소
    _recognizingTimer?.cancel();

    // 음성 인식 중... 글자 표시
    if (!_recognizing) {
      setState(() {
        _recognizing = true;
      });
    }

    // 일정 시간동안 recognizing 응답이 없다면 음성 인식 중 종료
    _recognizingTimer = Timer(
      const Duration(milliseconds: _recognizingTimerMilleSecond),
      () {
        if (mounted) {
          setState(() {
            _recognizing = false; // 음성 인식 중... 글자 지움
          });
        }
      },
    );
  }

  //multi모드 전용 : 현재 발화 중인 언어인지 확인
  bool isSpeakingLanguage(String lang) {
    bool result = false;

    // multi 모드 일 때 && 발화 중일 때에만
    if (_sttService is WebSocketMultipleSpeechService &&
        _currentTranslations.isNotEmpty) {
      //lang 키 가져오기
      final settings = Provider.of<LanguageSettingProvider>(
        context,
        listen: false,
      );
      String? serverKey = _findServerKeyForLanguage(lang, settings, false);

      if (serverKey != null) {
        if (serverKey == _currentSpeakingLanguage) {
          result = true;
        }
      }
    }

    return result;
  }

  // 자동 언어 매핑 함수
  String? _findServerKeyForLanguage(
    String displayLanguage,
    LanguageSettingProvider settings,
    bool isConfirmedLine,
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
    final targetTranslations =
        isConfirmedLine ? _confirmedTranslations : _currentTranslations;
    final availableKeys = targetTranslations.keys.toList();
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

    // 기본 매핑 시도
    if (googleCode != null) {
      if (availableKeys.contains(googleCode)) {
        serverKey = googleCode;
        debugPrint("[DEBUG] 폴백 매핑 성공: '$displayLanguage' → '$googleCode'");
      }
    }

    // 부분 매칭 시도
    if (serverKey == null && googleCode != null) {
      for (String key in availableKeys) {
        // ko와 ko-KR 매칭
        if (key.startsWith(googleCode) || googleCode.startsWith(key)) {
          serverKey = key;
          debugPrint(
            "[DEBUG] 부분 매핑 성공: '$displayLanguage' ($googleCode) → '$key'",
          );
          break;
        }
        // ko-KR과 ko 매칭
        if (key.contains('-') && key.split('-')[0] == googleCode) {
          serverKey = key;
          debugPrint(
            "[DEBUG] 접두사 매핑 성공: '$displayLanguage' ($googleCode) → '$key'",
          );
          break;
        }
      }
    }

    // 최종 폴백: 어떤 경우든 부분 일치(앞, 뒤, 포함) 시도
    if (serverKey == null && googleCode != null) {
      for (String key in availableKeys) {
        if (key.contains(googleCode) || googleCode.contains(key)) {
          serverKey = key;
          debugPrint(
            "[DEBUG] 최종 부분 매핑: '$displayLanguage' ($googleCode) ↔ '$key'",
          );
          break;
        }
      }
    }

    return null;
  }

  // 언어별 자막 반환 (자동 매핑 사용)
  String _getSubtitleText(
    String language,
    LanguageSettingProvider settings,
    bool isConfirmedLine,
  ) {
    final targetTranslations =
        isConfirmedLine ? _confirmedTranslations : _currentTranslations;

    // 자동 매핑으로 서버 키 찾기
    String? serverKey = _findServerKeyForLanguage(
      language,
      settings,
      isConfirmedLine,
    );

    // 디버그: 매핑 결과 확인
    debugPrint("자동 매핑: '$language' → '$serverKey'");

    // 번역 결과 확인
    if (serverKey != null &&
        targetTranslations.containsKey(serverKey) &&
        targetTranslations[serverKey]!.isNotEmpty) {
      debugPrint("'$serverKey' 번역 결과 찾음");

      // HTML 디코딩
      String rawText = targetTranslations[serverKey]!;
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

  // [서비스 시작 함수]
  // [1] 서비스 시작
  Future<void> _initAndStartService() async {
    debugPrint("[INIT-service] _initAndStartService 메서드 실행");

    // 이미 연결된 상태라면
    if (_sttService.isConnected) {
      debugPrint("[INIT-service] 이미 연결됨 - 다이얼로그만 표시");

      // 이미 연결된 상태에서도 다이얼로그 표시
      if (_sttService.isSessionReady) {
        // 이미 Ready 상태면 바로 완료 다이얼로그
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showReadyDialog();
          }
        });
      } else {
        // 아직 Ready 아니면 대기 다이얼로그
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showReadyDialog();
          }
        });
      }
      return; // 새 연결은 시도하지 않음
    }

    // 1) 언어 설정 가져오기
    final settings = Provider.of<LanguageSettingProvider>(
      context,
      listen: false,
    ); // 사용자가 설정한 언어 정보
    final inputLanguageCodes = settings.getInputLanguageCodes(); // 입력 언어 설정
    final outputLanguageCodes = settings.getOutputLanguageCodes(); // 출력 언어 설정

    debugPrint(
      "[INIT-service] 입력 언어 - $inputLanguageCodes / 출력 언어 $outputLanguageCodes",
    );

    // 2) 웹소켓 연결
    bool connectd = await _sttService.connectToServer();
    debugPrint("[INIT-service] 웹소켓 연결 성공 여부 - $connectd");

    // 연결 성공 시
    if (connectd) {
      if (_sttService is WebSocketSingleSpeechService) {
        // 싱글 모드
        await _sttService.startSession(
          inputLanguage: inputLanguageCodes[0],
          targetLanguages: outputLanguageCodes,
        );
      } else if (_sttService is WebSocketMultipleSpeechService) {
        // 멀티 모드
        await _sttService.startSession(
          inputLanguages: inputLanguageCodes,
          targetLanguages: outputLanguageCodes,
        );
      }
    }
  }

  // [2] 콜백 함수 : 현재 출력 자막 변경 알림 콜백 (isFinal : recognized, recognizing 문장 판별)
  void _setupCallbacks() {
    // 1) 번역 결과 콜백
    if (_sttService is WebSocketMultipleSpeechService) {
      //multi 모드
      _sttService.onTranslationReceived = (
        translations,
        isFinal,
        speackLanguage,
      ) {
        setState(() {
          _currentSpeakingLanguage = speackLanguage;
          if (isFinal) {
            translations.forEach((lang, result) {
              _confirmedTranslations[lang] = result.resultText;
            });

            debugPrint("문장 확정!");
          } else {
            //인식 중 상태 출력
            //recognizing이라면 음성 인식 중 표시 on
            _updateRecognizingState();
          }

          debugPrint("자막 화면 업데이트");
        });
      };
    } else {
      //single 모드
      _sttService.onTranslationReceived = (translations, isFinal) {
        setState(() {
          if (isFinal) {
            translations.forEach((lang, result) {
              _confirmedTranslations[lang] = result.resultText;
            });
            debugPrint("문장 확정!");
          } else {
            _updateRecognizingState();
          }

          debugPrint("자막 화면 업데이트");
        });
      };
    }

    // 초기 상태 로드
    _confirmedTranslations = {};
    _currentTranslations = {};

    // 2) 재연결 콜백 리스너
    _reconnectionCallbacks(); // (호출) [1] 재연결 콜백 메서드
  }

  // [ready 수신 다이얼로그]
  void _showReadyDialog() {
    if (_dialogShown) return;
    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ReadyReceivedDialog(
            onReadyConfirmed: () {
              debugPrint("[DEBUG] 서버로부터 ready 수신 - 녹음 시작 가능");
            },
          ),
    ).then((_) {
      _dialogShown = false;
    });
  }

  // [재연결 시도 관련 코드]
  // [1] 재연결 콜백 메서드
  void _reconnectionCallbacks() {
    debugPrint("[Re-콜백] _reconnectionCallbacks 메서드 실행");

    // 콜백 중복 방지
    _sttService?.onStatusUpdate = null;
    _sttService?.onError = null;

    // [1-1] 서버 연결 상태
    _sttService?.onStatusUpdate = (String status) {
      debugPrint("[Re-콜백] UI 상태 업데이트 $status");
      if (!mounted) return;
      // >> UI 동작 (화면 업데이트)
      setState(() {
        debugPrint("[Re-콜백] setState 호출");
        // 1) 재연결 시도
        if (status.contains("재시도")) {
          _serverConnectionState =
              ServerConnectionState.reconnecting; // 서버 연결 상태 - 재연결
          _statusMessage = status; // UI에 출력할 상태 메시지

          // (2) 재연결 시도 횟수 파싱
          final match = RegExp(r'재시도 (\d+)/').firstMatch(status);
          if (match != null) {
            _reconnectAttempts = int.parse(match.group(1)!);
          }
        }
        // 2) 연결 성공
        else if (status.contains("연결 성공") ||
            status.contains("세션 준비 시작") ||
            status.contains("음성 녹음 시작")) {
          _serverConnectionState =
              ServerConnectionState.connected; // 서버 연결 상태 - 연결 성공
          _statusMessage = "서버에 연결되었습니다."; // UI에 출력할 상태 메시지
        }
        // 3) 연결 종료
        else if (status.contains("연결 종료")) {
          _serverConnectionState =
              ServerConnectionState.disconnected; // 서버 연결 상태 - 연결 종료
          _statusMessage = "서버 연결이 끊어졌습니다."; // UI에 출력할 상태 메시지
        }
      });
    };

    debugPrint("[Re-콜백] 콜백 등록 완료");

    // [1-2] 서버 연결 실패
    _sttService?.onError = (String message, String? errorCode) {
      if (!mounted) return;
      setState(() {
        // 1) 최대 재시도 초과
        if (message.contains("최대 재시도")) {
          _serverConnectionState =
              ServerConnectionState.failed; // 서버 연결 상태 - 연결 실패
          _statusMessage = "최대 재시도 횟수 초과로 서버 연결에 실패했습니다."; // UI에 출력할 상태 메시지
        }
        // 2) 기타
        else if (message.contains("연결 실패")) {
          _serverConnectionState =
              ServerConnectionState.disconnected; // 서버 연결 상태 - 연결 끊김
          _statusMessage = message; // UI에 출력할 상태 메시지
        }
      });
      //_showErrorSnackBar(message); // (호출) [2] 에러 메시지 표시
    };
  }

  Future<void> restartSTTConnection() async {
    debugPrint("[DEBUG] _restartSTTConnection 메서드 실행");

    // 1) 기존 연결 완전히 종료
    await _sttService.disconnect();

    // 2) 잠깐 대기 (연결이 완전히 정리될 때까지)
    await Future.delayed(Duration(seconds: 1));

    // 3) 콜백 재등록
    _setupCallbacks();

    // 4) 새로 연결 시도
    await _initAndStartService();
  }

  // [2] 에러 메시지 표시
  void showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
