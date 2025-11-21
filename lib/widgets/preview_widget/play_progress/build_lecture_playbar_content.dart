// [widgets/preview_widget/play_progress/lecture_playbar_content.dart]
/// [로직]
/// 1) 재생 관련 로직 돌리는 위젯
/// 2) TimeManger 연동
/// 3) SaveDialog로 이동
library;

import 'package:client/screens/subtitles_only_screen.dart';
import 'package:client/services/websocket_multiple_speech_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:io' show Platform; //OS 확인
import '../../../screens/shared_with_subtitles_screen.dart'; // 오버레이 화면

import '../../../core/enum_core.dart';
import '../../../providers/mode_provider.dart';
import '../subtitle_setting_provider.dart';
import 'time_manager.dart';
import '../../preview_widget/play_progress/lecture_playbar_content.dart';
import '../../../screens/end_lecture_and_save_screen.dart';
import '../../../services/websocket_stt_service.dart';

class BuildLecturePlayBarContent extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final VoidCallback? onLectureEnd;
  final int? counterValue;

  const BuildLecturePlayBarContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    this.onLectureEnd,
    this.counterValue,
  });

  @override
  State<BuildLecturePlayBarContent> createState() =>
      _BuildLecturePlayBarContentState();
}

class _BuildLecturePlayBarContentState
    extends State<BuildLecturePlayBarContent> {
  DateTime? _lastUpdate;

  //서비스 설정
  WebSocketSTTService? _sttService;
  WebSocketMultipleSTTService? _multipleSTTService;

  Mode? _currentMode; // 현재 모드 저장
  bool hasStarted = false;

  // 현재 모드에 따른 서비스 반환 (기본 lecture)
  dynamic get currentService {
    if (_currentMode == Mode.conference) {
      return _multipleSTTService ??= WebSocketMultipleSTTService();
    } else {
      return _sttService ??= WebSocketSTTService();
    }
  }

  void _updateUI() {
    final now = DateTime.now();
    // 너무 자주 업데이트하지 않도록 제한
    if (_lastUpdate == null ||
        now.difference(_lastUpdate!).inMilliseconds > 100) {
      if (mounted) {
        setState(() {});
        _lastUpdate = now;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    TimerManager.addListener(_updateUI);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 페이지 진입 시 모드 설정 (한 번만)
    if (_currentMode == null) {
      _currentMode =
          Provider.of<ModeProvider>(context, listen: false).currentMode;
      debugPrint("페이지 진입 - 현재 모드: ${_currentMode.toString()}");
      //_initializeSTTService();
    }
  }

  @override
  void dispose() {
    TimerManager.removeListener(_updateUI);
    // dispose 시, 서비스도 dispose
    _sttService?.dispose();
    _multipleSTTService?.dispose();
    super.dispose();
  }

  //🔴🔴 지금 호출되고 있지 않는 코드입니다!!!!! provider를 통해서 service를 확인하고 있기 때문에 사용되고 있지 않음!
  //multiple에서는 동작 하는듯...?
  // 근데 의문점... subtitle only screen에 service provider를 적용하기 전에는 이 코드가 출력됐었는데 ... 뭐지
  // [콜백] stt 서비스 초기화
  // void _initializeSTTService() {
  //   final service = currentService;
  //
  //   if (service is WebSocketSTTService) {
  //     // 일반 강의 모드
  //     service.onTranslationReceived = (translations, isFinal) {
  //       // 1) 번역 결과 처리
  //       debugPrint("번역 결과 처리");
  //       translations.forEach((language, result) {
  //         // forEach : 번역 결과 순회하면 출력
  //         debugPrint(">> UI [$language] ${result.resultText}"); // UI 로그
  //       });
  //     };
  //
  //     // 2) 상태 변화 콜백
  //     service.onStatusUpdate = (status) {
  //       debugPrint("STT Status : $status");
  //     };
  //
  //     // 3) 에러 코드 콜백
  //     service.onError = (message, errorCode) {
  //       debugPrint(
  //         "STT Error : $message ${errorCode != null ? '($errorCode)' : ''}",
  //       );
  //     };
  //   } else if (service is WebSocketMultipleSTTService) {
  //     // 다국어 회의 모드
  //     service.onTranslationReceived = (translations, isFinal) {
  //       debugPrint("번역 결과 처리 (다국어 회의)");
  //       translations.forEach((language, result) {
  //         debugPrint(">> UI [$language] ${result.resultText}");
  //       });
  //     };
  //
  //     service.onStatusUpdate = (status) {
  //       debugPrint("STT Status (회의): $status");
  //     };
  //
  //     service.onError = (message, errorCode) {
  //       debugPrint(
  //         "STT Error (회의): $message ${errorCode != null ? '($errorCode)' : ''}",
  //       );
  //     };
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return LecturePlayBarComponents.buildPlayBarContainer(
      screenWidth: widget.screenWidth,
      isPlaying: TimerManager.isPlaying,
      hasStarted: hasStarted,
      displayTime: TimerManager.formattedTime,
      onPlayPause: _handlePlayPause,
      onCancel: _handleCancel,
      onStop: _handleStop,
    );
  }

  // ============================================================================
  // 비즈니스 로직 메서드들
  // ============================================================================

  // [Button 처리]
  // [1] 재생/일시정지
  void _handlePlayPause() async {
    // 1) 재생 버튼 눌렀을 때
    if (!TimerManager.isPlaying) {
      // 자막 모드 확인 (화면 공유 or 자막 ONLY)
      final subtitleSettings = context.read<SubtitleSettingsProvider>();
      // -> "화면 공유" 모드가 켜져 있는데
      if (subtitleSettings.screenSharedEnabled) {
        // -> 사용자 PC의 OS 확인 (윈도우가 아닐 때)
        if (!Platform.isWindows) {
          // -> 경고창 띄우기 (Mac/Linux면 Win32 API를 호출할 수 없음)
          if (mounted) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('기능 안내'),
                    content: const Text(
                      '화면 공유 자막(오버레이) 기능은 Windows에서만 사용할 수 있습니다.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
            );
          }
          // Navigator.push 전에 return (강의 시작 중단)
          return;
        }
      }
      TimerManager.start(); // 타이머 실행
      setState(() {
        hasStarted = true;
      });
      debugPrint('강의 시작 - 모드: ${_currentMode.toString()}');

      final service = currentService; // 현재 서비스 가져오기

      if (service.isConnected) {
        await service.startRecording();
        debugPrint("기존 연결로 녹음 재시작");
      } else {
        // Provider에서 언어 설정 가져오기
        final subtitleSettings = context.read<SubtitleSettingsProvider>();
        final inputLanguageCodes = subtitleSettings.getInputLanguageCodes();
        final outputLanguageCodes = subtitleSettings.getOutputLanguageCodes();

        debugPrint("🌐 언어 설정:");
        debugPrint(
          "  입력: ${subtitleSettings.selectedInputLanguages} -> $inputLanguageCodes",
        );
        debugPrint(
          "  출력: ${subtitleSettings.selectedOutputLanguages} -> $outputLanguageCodes",
        );

        await _startSTTService(
          inputLanguageCodes: inputLanguageCodes,
          outputLanguageCodes: outputLanguageCodes,
        );
      }

      // 화면 전환 및 상태 업데이트
      if (mounted) {
        dynamic result; // 상태 변수 (Close 버튼 클릭 여부)

        // 화면 공유 모드 && 윈도우 환경일 때
        // 1) 화면 공유 모드 (오버레이) 화면 전환
        if (subtitleSettings.screenSharedEnabled && Platform.isWindows) {
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SharedWithSubtitlesScreen(),
            ),
          );
        }
        // 2) 자막 only 화면 전환
        else {
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SubtitlesOnlyScreen(
                    subWordFont: "default",
                    backgroundColor: Colors.black,
                    subSpacing: 20,
                  ),
            ),
          );
        }

        // [UI UPDATE] UI 화면 갱신
        // (Close 버튼 클릭으로 true를 받았을 때)
        if (result == true) {
          debugPrint("[UI UPDATE] Close 버튼 클릭 -> 녹음 일시 정지");
          TimerManager.pause(); // 타이머 일시 정지
          setState(() {});
        }
      }
    }
    // 2) 일시 정지 상태일 때
    else {
      TimerManager.pause(); // 타이머 일시정지
      final service = currentService;
      await service.stopRecording();
      debugPrint('일시정지');
    }
  }

  // [2] 취소 -> 타이머 리셋
  void _handleCancel() {
    final service = currentService; // 현재 활성화된 STT/MultipleSTT 서비스 인스턴스를 가져옵니다.

    // 1) 서버 연결 종료 및 데이터 초기화
    service.resetReconnectState(); // 재연결 상태 초기화
    service.clearAllData(); // 누적된 모든 데이터 (텍스트 기록 등) 초기화
    service.disconnect(); // WebSocket 연결 끊기

    // 2) 타이머 및 UI 상태 초기화
    TimerManager.reset(); // 타이머를 0으로 리셋
    setState(() {
      hasStarted = false; // UI의 '시작됨' 상태를 리셋합니다.
    });

    debugPrint('[DEBUG] _handleCancel() - 취소 및 서비스 연결 해제 완료');
  }

  // [3] 종료 -> 다이얼로그 창    // 일시 비활성화
  void _handleStop() async {
    // final service = currentService;
    //
    // // 1) 자막 결과 및 통계 로그 출력
    // final transcriptHistory = service.transcriptHistory;
    // final translationHistory = service.translationHistory;
    // final fullTranscript = service.fullTranscriptText;
    //
    // debugPrint("강의 요약:");
    // debugPrint("  - 총 원문 개수: ${transcriptHistory.length}");
    // debugPrint("  - 총 번역 개수: ${translationHistory.length}");
    // debugPrint("  - 전체 원문 길이: ${fullTranscript.length}자");
    //
    // if (fullTranscript.isNotEmpty) {
    //   final sample =
    //       fullTranscript.length > 200
    //           ? "${fullTranscript.substring(0, 200)}..."
    //           : fullTranscript;
    //   debugPrint("  - 원문 샘플: $sample");
    // }
    //
    // // 2) 재연결 관련 변수 초기화
    // service.resetReconnectState();
    // service.clearAllData();
    // service.disconnect();
    //
    // // 3) 타이머 삭제
    // TimerManager.reset();
    // debugPrint('[DEBUG] _handelStop() - 강의 종료');
    // setState(() {
    //   hasStarted = false;
    // });
    //
    // _navigateToSaveDialog(
    //   transcriptHistory,
    //   translationHistory,
    //   fullTranscript,
    // );
  }

  // [4] 다이얼로그 (저장 옵션 선택)
  Future<void> _navigateToSaveDialog(
    List<String> transcriptHistory,
    List<Map<String, String>> translationHistory,
    String fullTranscript,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SaveDialogScreen(
          transcriptHistory: transcriptHistory,
          translationHistory: translationHistory,
          fullTranscript: fullTranscript,
        );
      },
    );
  }

  // [STT 서비스 처리] - 모드에 따라 분기
  Future<void> _startSTTService({
    required List<String> inputLanguageCodes,
    required List<String> outputLanguageCodes,
  }) async {
    final service = currentService;

    debugPrint("[🧸 DEBUG] _startSTT 메서드 실행");
    bool connected = await service.connectToServer();
    debugPrint("[🧸 DEBUG] [1] connectToServer 결과 - $connected");

    if (!connected) {
      debugPrint("[🧸 DEBUG] 서버 연결 실패 ㅠ.ㅠ");
      return;
    }

    // 2) 세션 시작 (서비스 타입에 따라 분기)
    debugPrint("[🧸 DEBUG] [2] startSesion 호출 준비");
    bool sessionStarted = false;

    // 세션 - 싱글 모드
    if (service is WebSocketSTTService) {
      debugPrint("[🧸 DEBUG] 싱글 모드 세션 시작");
      sessionStarted = await service.startSession(
        inputLanguage: inputLanguageCodes[0],
        targetLanguages: outputLanguageCodes,
      );
    } // 세션 - 멀티 모드
    else if (service is WebSocketMultipleSTTService) {
      debugPrint("[🧸 DEBUG] 멀티 모드 세션 시작");
      sessionStarted = await service.startSession(
        inputLanguages: inputLanguageCodes,
        targetLanguages: outputLanguageCodes,
      );
    }

    // 세션 결과
    debugPrint("[🧸 DEBUG] [2] startSession 결과 - $sessionStarted");
    if (!sessionStarted) {
      debugPrint("[🧸 DEBUG] 세션 시작 실패");
    }

    debugPrint(
      "[🧸 DEBUG] 입력 언어 - $inputLanguageCodes, 출력 언어 - $outputLanguageCodes",
    );
    debugPrint("[🧸 DEBUG] STT 서비스 시작 완료 (모드 - ${_currentMode.toString()})");
  }
}
