import 'package:client/screens/preview_screen.dart';
import 'package:client/services/postprocessor_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/enum_core.dart';
import '../core/styles/colors_core.dart';
import '../providers/mode_provider.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _showModeSelection = false;

  void _showModeSelectionUI() {
    setState(() {
      _showModeSelection = true;
    });
  }

  void _goBack() {
    setState(() {
      _showModeSelection = false;
    });
  }

  void _selectMode(Mode mode) {
    //mode 설정 (UI 재빌드 false)
    Provider.of<ModeProvider>(context, listen: false).setMode(mode);

    final postProcessor = PostProcessorService();
    postProcessor.setProcessingMode(mode.apiValue);

    debugPrint("선택된 모드: ${mode.name} → API 모드: ${mode.apiValue}");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PreviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final bool isWideScreen = screenWidth > screenHeight * 1.5;

    return Scaffold(
      backgroundColor: backgroundcolorOnWord,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            children: [
              // 상단 여백 (모드 선택 시 줄어듦)
              SizedBox(
                height:
                    _showModeSelection
                        ? screenHeight * 0.03
                        : screenHeight * 0.1,
              ),

              // EduScript 제목 (모드 선택 시 상단으로 이동)
              _showModeSelection
                  ? _buildTopTitle(screenWidth, isWideScreen)
                  : _buildCenterTitle(screenWidth, screenHeight, isWideScreen),

              // 버튼 영역
              _showModeSelection
                  ? _buildModeSelection(screenWidth, screenHeight, isWideScreen)
                  : _buildStartButton(screenWidth, screenHeight, isWideScreen),

              // 하단 여백
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  // 초기 화면의 가운데 제목
  Widget _buildCenterTitle(
    double screenWidth,
    double screenHeight,
    bool isWideScreen,
  ) {
    return Expanded(
      flex: 3,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'EduScript',
              style: TextStyle(
                fontSize:
                    isWideScreen ? screenWidth * 0.08 : screenWidth * 0.12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'AI 기반 실시간 스크립트 생성',
              style: TextStyle(
                fontSize:
                    isWideScreen ? screenWidth * 0.02 : screenWidth * 0.04,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 모드 선택 시 상단 제목
  Widget _buildTopTitle(double screenWidth, bool isWideScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          ),
          Expanded(
            child: Center(
              child: Text(
                'EduScript',
                style: TextStyle(
                  fontSize:
                      isWideScreen ? screenWidth * 0.05 : screenWidth * 0.08,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          // 균형을 맞추기 위한 빈 공간
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStartButton(
    double screenWidth,
    double screenHeight,
    bool isWideScreen,
  ) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: screenHeight * 0.07,
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: ElevatedButton(
              onPressed: _showModeSelectionUI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: backgroundcolorOnWord,
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '시작하기',
                style: TextStyle(
                  fontSize:
                      isWideScreen ? screenWidth * 0.025 : screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelection(
    double screenWidth,
    double screenHeight,
    bool isWideScreen,
  ) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 모드 선택 제목
          Text(
            '모드를 선택해주세요',
            style: TextStyle(
              fontSize: isWideScreen ? screenWidth * 0.03 : screenWidth * 0.05,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),

          SizedBox(height: screenHeight * 0.06),

          // 강의 모드 버튼
          Container(
            width: double.infinity,
            height: screenHeight * 0.08,
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: ElevatedButton.icon(
              onPressed: () => _selectMode(Mode.lecture),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: backgroundcolorOnWord,
                elevation: 6,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: Icon(
                Icons.school,
                size: isWideScreen ? screenWidth * 0.03 : screenWidth * 0.06,
              ),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '강의 모드',
                    style: TextStyle(
                      fontSize:
                          isWideScreen
                              ? screenWidth * 0.025
                              : screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.025),

          // 회의 모드 버튼
          Container(
            width: double.infinity,
            height: screenHeight * 0.08,
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: ElevatedButton.icon(
              onPressed: () => _selectMode(Mode.conference),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: backgroundcolorOnWord,
                elevation: 6,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: Icon(
                Icons.groups,
                size: isWideScreen ? screenWidth * 0.03 : screenWidth * 0.06,
              ),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '회의 모드',
                    style: TextStyle(
                      fontSize:
                          isWideScreen
                              ? screenWidth * 0.025
                              : screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
