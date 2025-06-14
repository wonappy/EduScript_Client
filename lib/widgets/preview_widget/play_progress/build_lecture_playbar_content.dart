/// 재생 부분 컨트롤 버튼 위젯
library;

import 'package:flutter/material.dart';
import '../../../core/global_core.dart';
import '../play_progress/time_manager.dart'; // TimerManager import

class BuildLecturePlayBarContent extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final int? counterValue;
  

  const BuildLecturePlayBarContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    this.counterValue
  });

  @override
  State<BuildLecturePlayBarContent> createState() => _BuildLecturePlayBarContentState();
}

class _BuildLecturePlayBarContentState extends State<BuildLecturePlayBarContent> {
  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void initState(){
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
    String displayTime = TimerManager.formattedTime;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.screenWidth * 0.04,
        vertical: widget.screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(widget.screenWidth * 0.02),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 닫기 버튼 (재생 중일 때만 표시)
          if (TimerManager.isPlaying) ...[
            _buildControlIcon(
              icon: Icons.close,
              onTap: () {
                TimerManager.reset();
                debugPrint('강의 종료');
              },
            ),
            SizedBox(width: widget.screenWidth * 0.03),
          ],
          
          // 메인 재생/일시정지 버튼
          GestureDetector(
            onTap: () {
              if (!TimerManager.isPlaying) {
                TimerManager.start();
                debugPrint('강의 시작');
              } else {
                TimerManager.pause();
                debugPrint('일시정지');
              }
            },
            child: Container(
              width: widget.screenWidth * 0.12,
              height: widget.screenWidth * 0.12,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: Icon(
                TimerManager.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: widget.screenWidth * 0.06,
              ),
            ),
          ),
          
          // 정지 버튼 (재생 중일 때만 표시)
          if (TimerManager.isPlaying) ...[
            SizedBox(width: widget.screenWidth * 0.03),
            _buildControlIcon(
              icon: Icons.stop,
              onTap: () {
                TimerManager.reset();
                debugPrint('정지');
              },
            ),
          ],
          
          SizedBox(width: widget.screenWidth * 0.04),
          
          // 시간 표시
          Text(
            displayTime,
            style: TextStyle(
              fontSize: getResponsiveFontSize(widget.screenWidth) * 0.8,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(widget.screenWidth * 0.02),
        child: Icon(
          icon,
          color: Colors.black87,
          size: widget.screenWidth * 0.05,
        ),
      ),
    );
  }
}
