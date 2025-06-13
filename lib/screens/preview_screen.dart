import 'package:flutter/material.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // 반응형 레이아웃을 위한 비율 계산
    final bool isWideScreen = screenWidth > screenHeight * 1.5;

    return Scaffold(
      backgroundColor: const Color(0xFF808080), // 회색 배경
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.015), // 화면 크기의 1.5%를 패딩으로
        child:
            isWideScreen
                ? _buildWideLayout(screenWidth, screenHeight)
                : _buildNarrowLayout(screenWidth, screenHeight),
      ),
    );
  }

  /// 와이드 스크린 (가로형) 레이아웃
  Widget _buildWideLayout(double screenWidth, double screenHeight) {
    return Row(
      children: [
        // 왼쪽 영역 (강의 화면 미리보기 + 강의 시작)
        Expanded(
          flex: 6, // 전체의 60%
          child: Column(
            children: [
              // 강의 화면 미리보기
              Expanded(
                flex: 7, // 왼쪽 영역의 70%
                child: _buildPreviewBlock(
                  title: '강의 화면 미리보기',
                  screenWidth: screenWidth * 0.6,
                  screenHeight: screenHeight * 0.7,
                ),
              ),
              SizedBox(height: screenHeight * 0.02), // 2% 간격
              // 강의 시작
              Expanded(
                flex: 3, // 왼쪽 영역의 30%
                child: _buildPreviewBlock(
                  title: '강의 시작',
                  screenWidth: screenWidth * 0.6,
                  screenHeight: screenHeight * 0.3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.02), // 2% 간격
        // 오른쪽 영역 (빈 공간)
        Expanded(
          flex: 4, // 전체의 40%
          child: _buildPreviewBlock(
            title: '',
            screenWidth: screenWidth * 0.4,
            screenHeight: screenHeight,
            showTitle: false,
          ),
        ),
      ],
    );
  }

  /// 좁은 스크린 (세로형) 레이아웃
  Widget _buildNarrowLayout(double screenWidth, double screenHeight) {
    return Column(
      children: [
        // 강의 화면 미리보기
        Expanded(
          flex: 5, // 전체의 50%
          child: _buildPreviewBlock(
            title: '강의 화면 미리보기',
            screenWidth: screenWidth,
            screenHeight: screenHeight * 0.5,
          ),
        ),
        SizedBox(height: screenHeight * 0.02), // 2% 간격
        // 강의 시작
        Expanded(
          flex: 2, // 전체의 20%
          child: _buildPreviewBlock(
            title: '강의 시작',
            screenWidth: screenWidth,
            screenHeight: screenHeight * 0.2,
          ),
        ),
        SizedBox(height: screenHeight * 0.02), // 2% 간격
        // 하단 빈 공간
        Expanded(
          flex: 3, // 전체의 30%
          child: _buildPreviewBlock(
            title: '',
            screenWidth: screenWidth,
            screenHeight: screenHeight * 0.3,
            showTitle: false,
          ),
        ),
      ],
    );
  }

  /// 개별 블록 위젯 생성
  Widget _buildPreviewBlock({
    required String title,
    required double screenWidth,
    required double screenHeight,
    bool showTitle = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 표시
        if (showTitle && title.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              left: screenWidth * 0.01,
              bottom: screenHeight * 0.01,
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(screenWidth),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        // 블록 영역
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0), // 연한 회색
              borderRadius: BorderRadius.circular(
                screenWidth * 0.008,
              ), // 반응형 모서리
              border: Border.all(color: const Color(0xFFC0C0C0), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: _getBlockContent(title, screenWidth, screenHeight),
          ),
        ),
      ],
    );
  }

  /// 블록별 컨텐츠 반환
  Widget _getBlockContent(
    String title,
    double screenWidth,
    double screenHeight,
  ) {
    switch (title) {
      case '강의 화면 미리보기':
        return _buildLecturePreviewContent(screenWidth, screenHeight);
      case '강의 시작':
        return _buildLectureStartContent(screenWidth, screenHeight);
      default:
        return _buildEmptyContent(screenWidth, screenHeight);
    }
  }

  /// 강의 화면 미리보기 컨텐츠
  Widget _buildLecturePreviewContent(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_outlined,
            size: screenWidth * 0.08,
            color: Colors.grey[600],
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            '카메라 준비 중...',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(screenWidth) * 0.8,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 강의 시작 컨텐츠
  Widget _buildLectureStartContent(double screenWidth, double screenHeight) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 설정 버튼
          _buildControlButton(
            icon: Icons.settings,
            label: '설정',
            screenWidth: screenWidth,
            onTap: () {
              // 설정 기능 구현
              print('설정 버튼 클릭');
            },
          ),
          // 강의 시작 버튼
          _buildControlButton(
            icon: Icons.play_circle_filled,
            label: '강의 시작',
            screenWidth: screenWidth,
            isPrimary: true,
            onTap: () {
              // 강의 시작 기능 구현
              print('강의 시작 버튼 클릭');
            },
          ),
          // 테스트 버튼
          _buildControlButton(
            icon: Icons.mic_rounded,
            label: '음성 테스트',
            screenWidth: screenWidth,
            onTap: () {
              // 음성 테스트 기능 구현
              print('음성 테스트 버튼 클릭');
            },
          ),
        ],
      ),
    );
  }

  /// 빈 컨텐츠 (추후 확장용)
  Widget _buildEmptyContent(double screenWidth, double screenHeight) {
    return Center(
      child: Text(
        '추가 기능 영역',
        style: TextStyle(
          fontSize: _getResponsiveFontSize(screenWidth) * 0.7,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  /// 컨트롤 버튼 위젯
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required double screenWidth,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenWidth * 0.015,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.blue[600] : Colors.grey[600],
          borderRadius: BorderRadius.circular(screenWidth * 0.01),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: screenWidth * 0.04),
            SizedBox(height: screenWidth * 0.005),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(screenWidth) * 0.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 반응형 폰트 크기 계산
  double _getResponsiveFontSize(double screenWidth) {
    // 기본 폰트 크기를 화면 너비에 비례하여 계산
    double baseFontSize = screenWidth * 0.015;

    // 최소, 최대 폰트 크기 제한
    return baseFontSize.clamp(12.0, 24.0);
  }
}
