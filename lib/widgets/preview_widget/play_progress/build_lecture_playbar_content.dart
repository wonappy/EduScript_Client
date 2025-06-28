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
import '../../../core/enum_core.dart';
import '../../../core/global_core.dart';
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
      _initializeSTTService();
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

  // [콜백] stt 서비스 초기화
  void _initializeSTTService() {
    final service = currentService;

    if (service is WebSocketSTTService) {
      // 일반 강의 모드
      service.onTranslationReceived = (translations) {
        // 1) 번역 결과 처리
        debugPrint("번역 결과 처리");
        translations.forEach((language, result) {
          // forEach : 번역 결과 순회하면 출력
          debugPrint(">> UI [$language] ${result.resultText}"); // UI 로그
        });
      };

      // 2) 상태 변화 콜백
      service.onStatusUpdate = (status) {
        debugPrint("STT Status : $status");
      };

      // 3) 에러 코드 콜백
      service.onError = (message, errorCode) {
        debugPrint(
          "STT Error : $message ${errorCode != null ? '($errorCode)' : ''}",
        );
      };
    } else if (service is WebSocketMultipleSTTService) {
      // 다국어 회의 모드
      service.onTranslationReceived = (translations) {
        debugPrint("번역 결과 처리 (다국어 회의)");
        translations.forEach((language, result) {
          debugPrint(">> UI [$language] ${result.resultText}");
        });
      };

      service.onStatusUpdate = (status) {
        debugPrint("STT Status (회의): $status");
      };

      service.onError = (message, errorCode) {
        debugPrint(
          "STT Error (회의): $message ${errorCode != null ? '($errorCode)' : ''}",
        );
      };
    }
  }

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
      getResponsiveFontSize: _getResponsiveFontSize,
    );
  }

  // ============================================================================
  // 비즈니스 로직 메서드들
  // ============================================================================

  // [Button 처리]
  // [1] 재생/일시정지
  void _handlePlayPause() async {
    if (!TimerManager.isPlaying) {
      TimerManager.start();
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

      if (mounted) {
        Navigator.push(
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
    } else {
      TimerManager.pause();
      final service = currentService;
      await service.stopRecording();
      debugPrint('일시정지');
    }
  }

  // [2] 취소 -> 타이머 리셋
  void _handleCancel() {
    TimerManager.reset();
    setState(() {
      hasStarted = false;
    });

    final service = currentService;
    service.clearAllData();
    service.disconnect();

    debugPrint('취소');
  }

  // [3] 종료 -> 다이얼로그 창
  void _handleStop() async {
    TimerManager.reset();
    debugPrint('강의 종료');
    setState(() {
      hasStarted = false;
    });

    final service = currentService;
    await service.disconnect();

    // 자막 결과 및 통계 로그 출력
    final transcriptHistory = service.transcriptHistory;
    final translationHistory = service.translationHistory;
    final fullTranscript = service.fullTranscriptText;

    debugPrint("강의 요약:");
    debugPrint("  - 총 원문 개수: ${transcriptHistory.length}");
    debugPrint("  - 총 번역 개수: ${translationHistory.length}");
    debugPrint("  - 전체 원문 길이: ${fullTranscript.length}자");

    if (fullTranscript.isNotEmpty) {
      final sample =
          fullTranscript.length > 200
              ? "${fullTranscript.substring(0, 200)}..."
              : fullTranscript;
      debugPrint("  - 원문 샘플: $sample");
    }

    _navigateToSaveDialog();
  }

  // [4] 다이얼로그 (저장 옵션 선택)
  Future<void> _navigateToSaveDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SaveDialogScreen();
      },
    );
  }

  // 반응형 폰트 크기 계산
  double _getResponsiveFontSize(double screenWidth) {
    return getResponsiveFontSize(screenWidth);
  }

  // [STT 서비스 처리] - 모드에 따라 분기
  Future<void> _startSTTService({
    required List<String> inputLanguageCodes,
    required List<String> outputLanguageCodes,
  }) async {
    final service = currentService;

    // 1) 서버 연결
    bool connected = await service.connectToServer();
    if (!connected) {
      debugPrint(">> 서버 연결 실패");
      return;
    }

    // 2) 세션 시작 (서비스 타입에 따라 분기)
    bool sessionStarted = false;

    if (service is WebSocketSTTService) {
      // Single 모드: 입력 언어 하나만 사용
      sessionStarted = await service.startSession(
        inputLanguage: inputLanguageCodes[0], //가장 첫번째로 설정된 언어만 전송
        targetLanguages: outputLanguageCodes,
      );
    } else if (service is WebSocketMultipleSTTService) {
      // Multiple 모드: 입력 언어를 리스트로 전달
      sessionStarted = await service.startSession(
        inputLanguages: inputLanguageCodes,
        targetLanguages: outputLanguageCodes,
      );
    }

    debugPrint("입력 언어들: $inputLanguageCodes, 출력 언어들: $outputLanguageCodes");

    if (!sessionStarted) {
      debugPrint(">> 세션 시작 실패");
      return;
    }

    debugPrint(">> STT 서비스 시작 완료 (모드: ${_currentMode.toString()})");
  }
}
