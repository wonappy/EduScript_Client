import 'package:client/providers/language_setting_provider.dart';
import 'package:client/screens/subtitles_only_screen.dart';
import 'package:client/services/websocket_multiple_speech_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:io' show Platform; //OS 확인
import '../../../screens/shared_with_subtitles_screen.dart'; // 오버레이 화면

import '../../../core/enum_core.dart';
import '../../../providers/mode_provider.dart';
import '../../../providers/subtitle_style_provider.dart';
import 'time_manager.dart';
import '../../preview_widget/play_progress/lecture_playbar_content.dart';
import '../../../screens/end_lecture_and_save_screen.dart';
import '../../../services/websocket_single_speech_service.dart';

// [widgets/preview_widget/play_progress/lecture_playbar_content.dart]
/// ###  재생 관련 로직 돌리는 위젯
/// - TimeManger 연동
/// - SaveDialog로 이동
class BuildLecturePlayBarContent extends StatefulWidget {
  final double screenWidth;
  final double screenHeight; // 이거 왜 씀

  const BuildLecturePlayBarContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<BuildLecturePlayBarContent> createState() =>
      _BuildLecturePlayBarContentState();
}

class _BuildLecturePlayBarContentState extends State<BuildLecturePlayBarContent> {

  Mode? _currentMode;                                   // 현재 모드 저장
  WebSocketSingleSpeechService? _sttService;            // 싱글 STT 서비스
  WebSocketMultipleSpeechService? _multipleSTTService;  // 멀티 STT 서비스
  bool hasStarted = false;                              // STT 이미 시작되었는지 여부
  DateTime? _lastUpdate;

  // 현재 서비스 할당 (기본 lecture)
  dynamic get currentService {
    if (_currentMode == Mode.conference) {
      return _multipleSTTService ??= WebSocketMultipleSpeechService();
    } else {
      return _sttService ??= WebSocketSingleSpeechService();
    }
  }

  // 타이머 UI 업데이트
  void _updateTimerUI() {
    final now = DateTime.now();
    // 너무 자주 업데이트하지 않도록 제한
    if (_lastUpdate == null || now.difference(_lastUpdate!).inMilliseconds > 100) {
      if (mounted) {
        setState(() {});
        _lastUpdate = now;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    TimerManager.addListener(_updateTimerUI);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 페이지 진입 시 모드 설정 (한 번만)
    if (_currentMode == null) {
      _currentMode = Provider.of<ModeProvider>(context, listen: false).currentMode;
      debugPrint("페이지 진입 - 현재 모드: ${_currentMode.toString()}");
    }
  }

  @override
  void dispose() {
    TimerManager.removeListener(_updateTimerUI); // 타이머 삭제
    _sttService?.dispose();                      // 싱글 STT 서비스 해제
    _multipleSTTService?.dispose();              // 멀티 STT 서비스 해제
    super.dispose();
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
    );
  }

  // [Button 처리]
  // [1] 재생/일시정지
  void _handlePlayPause() async {
    // 1) 재생
    if (!TimerManager.isPlaying) {
      // 화면 공유 ON 시, 사용자 PC가 윈도우가 아닐 때 경고창 띄우기
      // (Mac/Linux면 Win32 API를 호출할 수 없음)
      final styles = context.read<SubtitleStyleProvider>();
      if (styles.screenSharedEnabled) {
        if (!Platform.isWindows) {
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

      // 타이머 실행
      TimerManager.start();
      setState(() {
        hasStarted = true; // 시작 상태 변경
      });

      // 현재 서비스 가져오기
      final service = currentService;

      // STT 재시작
      if (service.isConnected) {
        await service.startRecording();
        debugPrint("[DEBUG] 기존 연결로 녹음 재시작");
      }
      else {
        // 선택된 언어 설정 가져오기
        final settings = context.read<LanguageSettingProvider>();
        final inputLanguageCodes = settings.getInputLanguageCodes();
        final outputLanguageCodes = settings.getOutputLanguageCodes();

        await _startSTTService(
          inputLanguageCodes: inputLanguageCodes,
          outputLanguageCodes: outputLanguageCodes,
        );

        debugPrint('[DEBUG] 강의 시작, 현재 모드 - ${_currentMode.toString()}');
      }

      // 화면 전환 및 상태 업데이트
      if (mounted) {
        dynamic result; // 상태 변수 (Close 버튼 클릭 여부)
        // 화면 공유 모드 && 윈도우 환경일 때
        // 1) 화면 공유 모드 (오버레이) 화면 전환
        if (styles.screenSharedEnabled && Platform.isWindows) {
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SharedWithSubtitlesScreen(),
            ),
          );
        }
        // 2) 자막 ONLY 화면 전환
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
          TimerManager.pause(); // 타이머 일시 정지
          setState(() {});
        }
      }
    }

    // 2) 일시정지
    else {
      TimerManager.pause();           // 타이머 일시정지
      final service = currentService; // 현재 서비스
      await service.stopRecording();  // 녹음 중단
      debugPrint('일시정지');
    }
  }

  // [2] 취소 -> 타이머 리셋 (아예 종료)
  void _handleCancel() {
    // 서비스 데이터 초기화 및 연결 종료
    final service = currentService;
    service.clearAllData();
    service.disconnect();

    // 타이머 및 UI 상태 초기화
    TimerManager.reset(); // 타이머 리셋
    setState(() {
      hasStarted = false; // 시작 상태 false로 변경
    });

    debugPrint('[DEBUG] _handleCancel() - 서비스 취소 및 연결 해제 완료');
  }

  // [3] 종료 -> 다이얼로그 창
  void _handleStop() async {
    // 자막 결과 및 통계 로그 출력
    final service = currentService;
    final transcriptHistory = service.transcriptHistory;    // 발화 내용
    final translationHistory = service.translationHistory;  // 번역 내용
    final fullTranscript = service.fullTranscriptText;      // 전체 내용

    debugPrint("[기록 통계]");
    debugPrint("  - 총 원문 문장 수: ${transcriptHistory.length}개");
    debugPrint("  - 총 번역 문장 수: ${translationHistory.length}개");
    debugPrint("  - 전체 원문 길이: ${fullTranscript.length}자");

    // 디버깅 용도인가 .. 필요한건가 ..
    if (fullTranscript.isNotEmpty) {
      final sample =
          fullTranscript.length > 200
              ? "${fullTranscript.substring(0, 200)}..."
              : fullTranscript;
      debugPrint("  - 원문 샘플: ${sample}");
    }

    // STT 데이터 초기화 및 연결 종료
    service.clearAllData();
    service.disconnect();

    // 타이머 리셋
    TimerManager.reset();
    debugPrint('[DEBUG] _handelStop() - 서비스 종료 및 연결 해제 완료');
    setState(() {
      hasStarted = false;
    });

    // 파일 저장 다이얼로그
    _navigateToSaveDialog(
      transcriptHistory,
      translationHistory,
      fullTranscript,
    );
  }

  // [4] 파일 저장 다이얼로그
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
          mode: _currentMode!,
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
    bool sessionStarted = false; // 세션 시작

    // 세션 - 싱글 STT
    if (service is WebSocketSingleSpeechService) {
      debugPrint("[DEBUG] 싱글 모드 세션 시작");
      sessionStarted = await service.startSession(
        inputLanguage: inputLanguageCodes[0],
        targetLanguages: outputLanguageCodes,
      );
    }
    // 세션 - 멀티 STT
    else if (service is WebSocketMultipleSpeechService) {
      debugPrint("[DEBUG] 멀티 모드 세션 시작");
      sessionStarted = await service.startSession(
        inputLanguages: inputLanguageCodes,
        targetLanguages: outputLanguageCodes,
      );
    }

    // 없어도 되지 않ㅇ나?
    // 세션 결과
    // debugPrint("[DEBUG] [2] startSession 결과 - $sessionStarted");
    // if (!sessionStarted) {
    //   debugPrint("[DEBUG] 세션 시작 실패");
    // }
    //
    // debugPrint("[DEBUG] 입력 언어 - $inputLanguageCodes, 출력 언어 - $outputLanguageCodes",);
    // debugPrint("[DEBUG] STT 서비스 시작 완료 (모드 - ${_currentMode.toString()})");
  }
}
