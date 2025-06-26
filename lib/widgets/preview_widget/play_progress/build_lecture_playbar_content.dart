// [widgets/preview_widget/play_progress/lecture_playbar_content.dart]
/// [로직]
/// 1) 재생 관련 로직 돌리는 위젯
/// 2) TimeManger 연동
/// 3) SaveDialog로 이동
library;

import 'package:client/screens/subtitles_only_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/global_core.dart';
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

  final WebSocketSTTService _sttService = WebSocketSTTService(); // 서비스 등록
  bool hasStarted = false;

  void _updateUI() {
    final now = DateTime.now();
    if (mounted) setState(() {});
    // 100ms마다 UI 업데이트
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
    _initializeSTTService();
  }

  @override
  void dispose() {
    TimerManager.removeListener(_updateUI);
    _sttService.dispose(); // dispose 시, 서비스도 dispose
    super.dispose();
  }

  // [콜백] stt 서비스 초기화
  void _initializeSTTService() {
    _sttService.onTranslationReceived = (translations) {
      // 1) 번역 결과 처리
      debugPrint("번역 결과 처리");
      translations.forEach((language, result) {
        // forEach : 번역 결과 순회하면 출력
        debugPrint(">> UI [$language] ${result.resultText}"); // UI 로그
      });
    };

    // 2) 상태 변화 콜백
    _sttService.onStatusUpdate = (status) {
      debugPrint("STT Status : $status");
    };

    // 3) 에러 코드 콜백
    _sttService.onError = (message, errorCode) {
      debugPrint(
        "STT Error : $message ${errorCode != null ? '($errorCode)' : ''}",
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    // LecturePlayBarComponents를 사용해서 UI 렌더링
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
      hasStarted = true; // 재생 시작했음을 표시
    });
    debugPrint('강의 시작');

    if (_sttService.isConnected) {
      await _sttService.startRecording(); // 이미 연결되어 있으면 녹음 재시작
      debugPrint("기존 연결로 녹음 재시작");
    } else {
      // Provider에서 언어 설정 가져오기
      final subtitleSettings = context.read<SubtitleSettingsProvider>();
      final inputLanguageCode = subtitleSettings.getInputLanguageCode();
      final outputLanguageCodes = subtitleSettings.getOutputLanguageCodes();

      debugPrint("🌐 언어 설정:");
      debugPrint(
        "  입력: ${subtitleSettings.selectedInputLanguages} -> $inputLanguageCode",
      );
      debugPrint(
        "  출력: ${subtitleSettings.selectedOutputLanguages} -> $outputLanguageCodes",
      );

      await _startSTTService(
        inputLanguageCode: inputLanguageCode,
        outputLanguageCodes: outputLanguageCodes,
      ); // [STT 서비스 호출] - 녹음 시작
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubtitlesOnlyScreen(
            subWordFont: "default",
            backgroundColor: Colors.black,
            subSpacing: 20,
          ),
        ),
      );
    }
  } else {
    TimerManager.pause();
    await _sttService.stopRecording(); // [STT 서비스 호출] - 일시 정지 처리
    debugPrint('일시정지');
  }
}

  // [2] 취소 -> 타이머 리셋
  void _handleCancel() {
    TimerManager.reset();
    setState(() {
      hasStarted = false; // 초기 상태로 돌림
    });

    //번역 데이터 초기화
    _sttService.clearAllData();
    _sttService.disconnect(); // [STT 서비스 호출] - 연결 해제(종료)

    debugPrint('취소');
  }

  // [3] 종료 -> 다이얼로그 창
  void _handleStop() async {
    TimerManager.reset();
    debugPrint('강의 종료');
    setState(() {
      hasStarted = false; // 초기 상태로 돌림
    });

    await _sttService.disconnect(); // [STT 서비스 호출] - 연결 해제(종료)

    //자막 결과 및 통계 로그 출력
    final transcriptHistory = _sttService.transcriptHistory;
    final translationHistory = _sttService.translationHistory;
    final fullTranscript = _sttService.fullTranscriptText;

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

    // 콜백 호출 (SaveConfirmDialog는 상위에서 처리)
    _navigateToSaveDialog();
  }

  // [4] 다이얼로그 (저장 옵션 선택)
  Future<void> _navigateToSaveDialog() async {
    //대화상자로 표시
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SaveDialogScreen();
        // const 키워드 사용시 Flutter가 위젯을 재사용할 수 있어 이전 상태가 남아버림
        // 따라서 const 키워드를 사용하지 않음
      },
    );
  }

  // 반응형 폰트 크기 계산
  double _getResponsiveFontSize(double screenWidth) {
    // global_core.dart의 getResponsiveFontSize 사용하거나
    // 직접 계산
    return getResponsiveFontSize(screenWidth);
    // 또는 간단히: return screenWidth * 0.04;
  }

  // [STT 서비스 처리]
  Future<void> _startSTTService({
    required String inputLanguageCode,
    required List<String> outputLanguageCodes,
  }) async {
    // 1) 서버 연결
    bool connected = await _sttService.connectToServer();
    if (!connected) {
      debugPrint(">> 서버 연결 실패");
      return;
    }

    // 2) 세션 시작 (언어 설정)
    // 🔴 국가 전송
    bool sessionStarted = await _sttService.startSession(
      inputLanguage: "ko-KR", // 입력 언어 (국가)
      targetLanguages: ["en", "ja"], // 출력 언어 (국가)
    );

    if (!sessionStarted) {
      debugPrint(">> 세션 시작 실패");
      return;
    }

    debugPrint(">> STT 서비스 시작 완료");
  }
}
