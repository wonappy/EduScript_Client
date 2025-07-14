//자막 (프롬프트 느낌 ver)
import 'package:client/core/styles/color_core.dart';
import 'package:client/widgets/common/ready_received_dialog_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:html/parser.dart' as html_parser;

import '../core/enum_core.dart';
import '../providers/mode_provider.dart';
import '../services/websocket_multiple_speech_service.dart';
import '../services/websocket_stt_service.dart';
import '../widgets/preview_widget/subtitle_setting_provider.dart';
import '../widgets/common/connection_status_bar_widget.dart';

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

  @override
  void initState() {
    super.initState();

    // 1) 모드에 따른 서비스 할당
    // 현재 선택된 모드
    final mode = Provider.of<ModeProvider>(context, listen: false).currentMode;

    // 강의 모드
    if (mode == Mode.lecture) {
      _sttService = Provider.of<WebSocketSTTService>(context, listen: false);
      debugPrint("[🔴 DEBUG] 강의 모드 서비스 할당됨");
    }
    // 회의 모드
    else {
      _sttService = Provider.of<WebSocketMultipleSTTService>(
        context,
        listen: false,
      );
      debugPrint("[🔴 DEBUG] 회의 모드 서비스 할당됨");
    }

    // 2) 콜백 설정
    _setupCallbacks();

    // 3) 화면이 그려진 직후, 딱 한 번만 서비스 시작 요청
    debugPrint("[🔴 INIT] PostFrameCallback 등록");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("[🔴 INIT] PostFrameCallback 실행됨");
      debugPrint("[🔴 INIT] _initAndStartService 호출 시작");
      _initAndStartService();
    });
  }

  @override
  void dispose() {
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
    final settings = context.watch<SubtitleSettingsProvider>(); // 자막 출력
    final languages = settings.selectedOutputLanguages; // 선택된 출력 언어 목록 가져오기

    // [DEBUG] Provider 설정 확인
    debugPrint("🔴 Provider 설정:");
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
              mainAxisAlignment: settings.getAlignment(),
              children: [
                for (int i = 0; i < languages.length; i++)
                  Column(
                    children: [
                      SizedBox(height: 15 * scaleFactor), //자막 간 간격 지정
                      //이전 자막
                      Text(
                        Provider.of<SubtitleSettingsProvider>(
                          context,
                          listen: false,
                        ).getOutputLanguage(languages[i]),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17 * scaleFactor,
                        ),
                      ),
                      SizedBox(height: 7 * scaleFactor),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * scaleFactor,
                          vertical: 10 * scaleFactor,
                        ),
                        width: screenWidth * 0.95,
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.2,
                        ),
                        //최대 자막 컨테이너 높이
                        decoration: BoxDecoration(
                          color: settings.getBackgroundColor().withValues(
                            //자막 배경 색상 지정
                            alpha:
                                settings.getBackgroundOpacity() *
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
                            color: settings.getFontColor(), //자막 글자 색상 지정
                            fontSize:
                                settings.getFontSize(screenWidth) *
                                scaleFactor, //자막 글자 크기 지정
                            fontWeight: settings.getFontWeight(),
                            fontStyle: settings.getFontStyle(),
                            textBaseline: null,
                          ),
                        ),
                      ),
                      SizedBox(height: 5 * scaleFactor),
                      //현재 자막
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * scaleFactor,
                          vertical: 10 * scaleFactor,
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
                          borderRadius: BorderRadius.circular(5),
                          border:
                              // 발화 중인 언어 테두리 표시
                              isSpeakingLanguage(languages[i])
                                  ? Border.all(color: Colors.blue, width: 1.5)
                                  : null,
                        ),
                        child: Text(
                          _getSubtitleText(
                            languages[i],
                            settings,
                            false,
                          ), //자막 내용 지정
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: settings.getFontColor(), //자막 글자 색상 지정
                            fontSize:
                                settings.getFontSize(screenWidth) *
                                scaleFactor, //자막 글자 크기 지정
                            fontWeight: settings.getFontWeight(),
                            fontStyle: settings.getFontStyle(),
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

          // 3) Close 아이콘
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

  //multi모드 전용 : 현재 발화 중인 언어인지 확인
  bool isSpeakingLanguage(String lang) {
    bool result = false;

    // multi 모드 일 때 && 발화 중일 때에만
    if (_sttService is WebSocketMultipleSTTService &&
        _currentTranslations.isNotEmpty) {
      //lang 키 가져오기
      final settings = Provider.of<SubtitleSettingsProvider>(
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

  // 🎯 자동 언어 매핑 함수
  String? _findServerKeyForLanguage(
    String displayLanguage,
    SubtitleSettingsProvider settings,
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

    // 최종 폴백: 어떤 경우든 부분 일치(앞, 뒤, 포함) 시도
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
  String _getSubtitleText(
    String language,
    SubtitleSettingsProvider settings,
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

      // HTML 디코딩 (return 하기 전에!)
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
    // 이미 연결된 상태라면 아무것도 X
    if (_sttService.isConnected) return;

    // 1) 언어 설정 가져오기
    final settings = Provider.of<SubtitleSettingsProvider>(
      context,
      listen: false,
    ); // 사용자가 설정한 언어 정보
    final inputLanguageCodes = settings.getInputLanguageCodes(); // 입력 언어 설정
    final outputLanguageCodes = settings.getOutputLanguageCodes(); // 출력 언어 설정

    // 2) 웹소켓 연결
    bool connectd = await _sttService.connectToServer();

    // 연결 성공 시
    if (connectd) {
      debugPrint("[📌 DEBUG] 다이얼로그 호출 전");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint("[📌 DEBUG] PostFrameCallback 실행됨");
        if (mounted) {
          debugPrint("[📌 DEBUG] mounted == true, Ready 다이얼로그 표시 시도 ...");
          _showReadyDialog();
        } else {
          debugPrint("[📌 DEBUG] mounted == false, Ready 다이얼로그 표시 불가");
        }
      });
      if (_sttService is WebSocketSTTService) {
        // 싱글 모드
        await _sttService.startSession(
          inputLanguage: inputLanguageCodes[0],
          targetLanguages: outputLanguageCodes,
        );
      } else if (_sttService is WebSocketMultipleSTTService) {
        // 멀티 모드
        await _sttService.startSession(
          inputLanguages: inputLanguageCodes,
          targetLanguages: outputLanguageCodes,
        );
      }
    }
  }

  // [2] 콜백 함수 : 현재 출력 자막 변경 알림 콜백
  void _setupCallbacks() {
    // 1) 번역 결과 콜백
    if (_sttService is WebSocketMultipleSTTService) {
      //multi 모드
      _sttService.onTranslationReceived = (
        translations,
        isFinal,
        speackLanguage,
      ) {
        setState(() {
          _currentSpeakingLanguage = speackLanguage;
          if (isFinal) {
            _confirmedTranslations = Map.from(_currentTranslations);
            _currentTranslations.clear(); // 현재 문장 초기화

            debugPrint("문장 확정!");
          } else {
            // 번역 결과를 로컬 상태로 복사
            _currentTranslations.clear(); //현재 자막 초기화
            translations.forEach((lang, result) {
              // 각 언어 자막 저장
              _currentTranslations[lang] = result.resultText;
            });
          }

          debugPrint("자막 화면 업데이트: ${_currentTranslations.length}개 언어");
        });
      };
    } else {
      //single 모드
      _sttService.onTranslationReceived = (translations, isFinal) {
        setState(() {
          if (isFinal) {
            _confirmedTranslations = Map.from(_currentTranslations);
            _currentTranslations.clear(); // 현재 문장 초기화

            debugPrint("문장 확정!");
          } else {
            // 번역 결과를 로컬 상태로 복사
            _currentTranslations.clear(); //현재 자막 초기화
            translations.forEach((lang, result) {
              // 각 언어 자막 저장
              _currentTranslations[lang] = result.resultText;
            });
          }

          debugPrint("자막 화면 업데이트: ${_currentTranslations.length}개 언어");
        });
      };
    }

    // 초기 상태 로드
    //_currentTranslations = Map.from(_sttService.currentTranslations);
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
              debugPrint("[🔴 DEBUG] 서버로부터 ready 수신 - 녹음 시작 가능");
            },
          ),
    ).then((_) {
      _dialogShown = false;
    });
  }

  // [재연결 시도 관련 코드]
  // [1] 재연결 콜백 메서드
  void _reconnectionCallbacks() {
    debugPrint("[🔴 DEBUG] _reconnectionCallbacks 메서드 실행");

    // 콜백 중복 방지
    _sttService?.onStatusUpdate = null;
    _sttService?.onError = null;

    // [1-1] 서버 연결 상태
    _sttService?.onStatusUpdate = (String status) {
      debugPrint("[🔴 DEBUG] UI 상태 업데이트 $status");
      if (!mounted) return;
      // >> UI 동작 (화면 업데이트)
      setState(() {
        debugPrint("[🔴 DEBUG] setState 호출");
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

    debugPrint("[🔴 DEBUG] 콜백 등록 완료");

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
          _statusMessage = "$message"; // UI에 출력할 상태 메시지
        }
      });
      //_showErrorSnackBar(message); // (호출) [2] 에러 메시지 표시
    };
  }

  Future<void> _restartSTTConnection() async {
    debugPrint("[🔴 DEBUG] _restartSTTConnection 메서드 실행");

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
  void _showErrorSnackBar(String message) {
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

  // Future<void> _initiateAndStartSttSession() async {
  //   // 이미 녹음 중이면 아무것도 X
  //   if (_sttService.isRecording) return;
  //
  //   // 1) 서비스 연결 상태 확인
  //   if (_sttService.isConnected) {
  //     await _sttService.startRecording();
  //     debugPrint("기존 연결로 녹음 재시작");
  //   } else {
  //
  //     // Provider에서 언어 설정 가져오기
  //     final subtitleSettings = context.read<SubtitleSettingsProvider>();
  //     final inputLanguageCodes = subtitleSettings.getInputLanguageCodes();
  //     final outputLanguageCodes = subtitleSettings.getOutputLanguageCodes();
  //
  //     debugPrint("🌐 언어 설정:");
  //     debugPrint(
  //       "  입력: ${subtitleSettings.selectedInputLanguages} -> $inputLanguageCodes",
  //     );
  //     debugPrint(
  //       "  출력: ${subtitleSettings.selectedOutputLanguages} -> $outputLanguageCodes",
  //     );
  //
  //     bool connected = await _sttService.connectToServer();
  //
  //     if(!connected) {
  //       debugPrint("[subtitles_only_screen] 서버 연결 실패");
  //       return; // 연결 실패 시 중단
  //     }
  //
  //     // 세션 시작 (강의 모드는 입력 언어가 하나)
  //     bool sessionStarted = await _sttService.startSession(
  //       inputLanguage: inputLanguageCodes[0],
  //       targetLanguages: outputLanguageCodes,
  //     );
  //
  //     if (!sessionStarted) {
  //       debugPrint("[SubtitlesScreen] 세션 시작 실패");
  //       // startSession 내부에서 ready 콜백을 받으면 자동으로 startRecording이 호출되므로
  //       // 여기서 별도로 startRecording을 호출할 필요가 없습니다.
  //     }
  //
  //     // await _startSTTService(
  //     //   inputLanguageCodes: inputLanguageCodes,
  //     //   outputLanguageCodes: outputLanguageCodes,
  //     // );
  //   }
  // }

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
