// widgets/preview_widget/play_progress/lecture_playbar_content.dart
import 'package:flutter/material.dart';
import '../../../core/global_core.dart';
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
  State<BuildLecturePlayBarContent> createState() => _BuildLecturePlayBarContentState();
}

class _BuildLecturePlayBarContentState extends State<BuildLecturePlayBarContent> {
  void _updateUI() {
    if (mounted) setState(() {});
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
      debugPrint('강의 시작');
    } else {
      TimerManager.pause();
      debugPrint('일시정지');
    }
  }

  void _handleCancel() {
    TimerManager.reset();
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
      return const SaveDialogScreen(); // 또는 SaveConfirmDialog
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