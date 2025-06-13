//자막 (프롬프트 느낌 ver)
import 'package:flutter/material.dart';

import '../core/styles/colors_core.dart';
import '../widgets/preview_widget/build_narrow_layout.dart';
import '../widgets/preview_widget/build_wide_layout.dart';

class SubtitlesOnlyScreen extends StatefulWidget {
  //글자 크기, 배경 색상, 자막 배경 색상, 자막 배경 불투명도, 자막 글자 색상, 자막 글꼴, 자막 간 간격, 언어 리스트

  const SubtitlesOnlyScreen({super.key});

  @override
  State<SubtitlesOnlyScreen> createState() => _SubtitlesOnlyScreenState();
}

class _SubtitlesOnlyScreenState extends State<SubtitlesOnlyScreen> {
  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // 반응형 레이아웃을 위한 비율 계산
    final bool isWideScreen = screenWidth > screenHeight * 1.5;

    return Scaffold();
  }
}
