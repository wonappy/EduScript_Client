import 'package:client/core/styles/color_core.dart';
import 'package:client/core/styles/size_core.dart';
import 'package:client/screens/preview_screen.dart';
import 'package:client/services/postprocessor_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/enum_core.dart';
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
      backgroundColor: AppColors.whiteColor1, // 🔴 배경색
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.smallPadding), // 🔵 패딩 크기
          child: Stack(
            children: [
              Column(
                children: [
                  // 상단 여백
                  SizedBox(height: screenHeight * 0.15),
                  // [1] 제목 + 소제목 (모드 선택 시 상단으로 이동)
                  _showModeSelection
                      ? _buildTopTitle(screenWidth, isWideScreen)
                      : _buildCenterTitle(
                        screenWidth,
                        screenHeight,
                        isWideScreen,
                      ),

                  // 중간 여백
                  SizedBox(height: 95),

                  // [2] 버튼 영역
                  _showModeSelection
                      ? _buildModeSelection(
                        screenWidth,
                        screenHeight,
                        isWideScreen,
                      )
                      : _buildStartButton(
                        screenWidth,
                        screenHeight,
                        isWideScreen,
                      ),

                  // 하단 여백
                  SizedBox(height: 59),
                ],
              ),
              _showModeSelection
                  ? IconButton(
                    onPressed: _goBack,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.greyFontColor,
                    ),
                  )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  // [1] 화면
  // [1-1] 시작 화면 (제목 + 소제목)
  Widget _buildCenterTitle(
    double screenWidth,
    double screenHeight,
    bool isWideScreen,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'EduScript',
            style: TextStyle(
              fontSize: 110, // 🔵 제목 폰트 크기
              fontWeight: FontWeight.bold,
              color: AppColors.blueColor1, // 🔴 제목 폰트 색상
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'AI 기반 실시간 스크립트 생성',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 25, // 🔵 소제목 폰트 크기
              // isWideScreen ? screenWidth * 0.02 : screenWidth * 0.04,
              color: AppColors.greyFontColor, // 🔴 소제목 폰트 색상
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // [1-2] 모드 선택 화면 (제목 + 소제목)
  Widget _buildTopTitle(double screenWidth, bool isWideScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'EduScript',
            style: TextStyle(
              fontSize: 110, // 🔵 제목 폰트 크기
              //isWideScreen ? screenWidth * 0.08 : screenWidth * 0.12,
              fontWeight: FontWeight.bold,
              color: AppColors.blueColor1, // 🔴 제목 폰트 색상
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '모드를 선택하세요',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 25, // 🔵 소제목 폰트 크기
              // isWideScreen ? screenWidth * 0.02 : screenWidth * 0.04,
              color: AppColors.greyFontColor, // 🔴 소제목 폰트 색상
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // [2] 버튼
  // [2-1] 시작하기 버튼
  Widget _buildStartButton(
    double screenWidth,
    double screenHeight,
    bool isWideScreen,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 50, // 🔵 시작하기 버튼 크기  //screenHeight * 0.07,
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: ElevatedButton(
            onPressed: _showModeSelectionUI,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueColor2, // 🔴 버튼 배경색
              foregroundColor: Colors.red, // 🔴 버튼 폰트색 ????????
              elevation: 8,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Text(
              '시작하기',
              style: TextStyle(
                color: AppColors.whiteColor1, // 🔴 버튼 폰트색
                fontSize: 30, // 🔵 폰트 크기
                //isWideScreen ? screenWidth * 0.025 : screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // [2-2] 모드 선택 버튼
  Widget _buildModeSelection(
    double screenWidth,
    double screenHeight,
    bool isWideScreen,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1) 강의 모드 버튼
        Container(
          width: 220,
          height: 50, // 🔵 강의 모드 버튼 크기 // screenHeight * 0.08,
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: ElevatedButton.icon(
            onPressed: () => _selectMode(Mode.lecture),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueColor2, // 🔴 버튼 배경색
              foregroundColor: AppColors.whiteColor1, // 🔴 버튼 폰트색
              elevation: 6,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            icon: Icon(Icons.school, size: 38),
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '강의 모드',
                  style: TextStyle(
                    fontSize: 30, // 🔵 폰트 크기
                    // isWideScreen
                    //     ? screenWidth * 0.025
                    //     : screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 10),

        // 2) 토론 모드 버튼
        Container(
          width: 220,
          height: 50, // 🔵 토론 모드 버튼 크기
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: ElevatedButton.icon(
            onPressed: () => _selectMode(Mode.conference),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueColor2, // 🔴 버튼 배경색
              foregroundColor: AppColors.whiteColor1, // 🔴 버튼 폰트색
              elevation: 6,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            icon: Icon(
              Icons.groups,
              size:
                  38, //isWideScreen ? screenWidth * 0.03 : screenWidth * 0.06,
            ),
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '토론 모드',
                  style: TextStyle(
                    fontSize: 30,
                    // isWideScreen
                    //     ? screenWidth * 0.025
                    //     : screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
