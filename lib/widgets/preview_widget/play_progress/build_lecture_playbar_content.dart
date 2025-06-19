// widgets/preview_widget/play_progress/lecture_playbar_content.dart
// 로직 - 재생 관련 로직 돌리는 위젯 / TimeManger 연동, SaveDialog로 이동

import 'package:client/screens/subtitles_only_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/global_core.dart';
import '../../../models/subtitles_model.dart';
import '../../../screens/shared_with_subtitles_screen.dart';
import 'time_manager.dart';
import '../../preview_widget/play_progress/lecture_playbar_content.dart';
import '../../../screens/end_lecture_and_save_screen.dart';

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
  }

  @override
  void dispose() {
    TimerManager.removeListener(_updateUI);
    super.dispose();
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

  void _handlePlayPause() {
    if (!TimerManager.isPlaying) {
      TimerManager.start();
      setState(() {
        hasStarted = true; // 재생 시작했음을 표시
      });
      debugPrint('강의 시작');
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
    } else {
      TimerManager.pause();
      debugPrint('일시정지');
    }
  }

  void _handleCancel() {
    TimerManager.reset();
    setState(() {
      hasStarted = false; // 초기 상태로 돌림
    });
    debugPrint('취소');
  }

  void _handleStop() {
    TimerManager.reset();
    debugPrint('강의 종료');

    // 콜백 호출 (SaveConfirmDialog는 상위에서 처리)
    _navigateToSaveDialog();
  }

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
}
