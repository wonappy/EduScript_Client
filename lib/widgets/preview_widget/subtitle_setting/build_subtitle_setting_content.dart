/// 자막 언어 및 테마 설정
library;

import 'package:flutter/material.dart';
import '../../../core/global_core.dart';
import 'setting_drop_down_widget.dart';
import 'color_setting_drop_down_widget.dart';
import 'onoff_switch_state_widget.dart';

class BuildSubtitleSettingContent extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;

  const BuildSubtitleSettingContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<BuildSubtitleSettingContent> createState() =>
      _BuildSubtitleSettingContentState();
}

class _BuildSubtitleSettingContentState
    extends State<BuildSubtitleSettingContent> {
  // [초기값 설정]
  bool screenSharedEnaboled = true; // 스위치
  String selectedLanguage = '한국어'; // 언어
  String selectedPosition = '하단'; // 자막 위치
  String selectedStyle = '기본'; // 자막 스타일
  String selectedTextColor = "검정"; // 글/배경 색상
  String selectedOpacity = "50%"; // 배경 불투명도

  Color bigContainerColor = Color(0xFFC1C1C1);
  Color dropdownWidgetColor = Color(0xFFF6F6F6);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // [0] 스타일 미리 보기 화면
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5), // 그림자 색상 및 투명도
                    spreadRadius: 5, // 그림자 확산 정도
                    blurRadius: 7, // 그림자 흐림 정도
                    offset: Offset(0, 3), // 그림자 위치 (x, y)
                  ),
                ],
              ),
              width: widget.screenWidth * 0.8,
              height: widget.screenHeight * 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("안녕하세용", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "저는 부자가 될거에요",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  // 스크롤바 안보이도록
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        // [1] 화면 공유 ON/OFF
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "화면 공유 ON/OFF",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      getResponsiveFontSize(
                                        widget.screenWidth,
                                      ) *
                                      0.8,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            OnOffSwitch(),
                          ],
                        ),
                        SizedBox(height: 15),
                        SizedBox(
                          // Divider
                          width: double.infinity, // 부모 너비에 맞춤
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 25),

                        // [2] 입력 언어 설정
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "입력 언어 설정",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  getResponsiveFontSize(widget.screenWidth) *
                                  0.8,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // 큰 컨테이너
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bigContainerColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  0.2,
                                ), // 그림자 색상 및 투명도
                                blurRadius: 3, // 그림자 흐림 정도 (자연스러운 효과)
                                offset: Offset(0, 4), // y값을 높이면 아래쪽에만 그림자
                              ),
                            ],
                          ),
                          // 중간 컨테이너
                          child: Container(
                            decoration: BoxDecoration(
                              color: dropdownWidgetColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    0.2,
                                  ), // 그림자 색상 및 투명도
                                  blurRadius: 3, // 그림자 흐림 정도 (자연스러운 효과)
                                  offset: Offset(0, 4), // y값을 높이면 아래쪽에만 그림자
                                ),
                              ],
                            ),
                            child: SettingDropdown(
                              title: "언어",
                              initialValue: "한국어",
                              options: ["한국어", "영어", "일본어", "중국어"],
                              onChanged: (String newLanguage) {
                                setState(() {
                                  selectedLanguage = newLanguage;
                                });
                              },
                              screenWidth: widget.screenWidth,
                              screenHeight: widget.screenHeight,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          // Divider
                          width: double.infinity, // 부모 너비에 맞춤
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 25),

                        // [3] 출력 언어 설정
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "출력 언어 설정",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  getResponsiveFontSize(widget.screenWidth) *
                                  0.8,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        // [3-1] 출력 언어 설정
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: bigContainerColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  0.2,
                                ), // 그림자 색상 및 투명도
                                blurRadius: 3, // 그림자 흐림 정도 (자연스러운 효과)
                                offset: Offset(0, 4), // y값을 높이면 아래쪽에만 그림자
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: dropdownWidgetColor,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        0.2,
                                      ), // 그림자 색상 및 투명도
                                      blurRadius: 3, // 그림자 흐림 정도 (자연스러운 효과)
                                      offset: Offset(0, 4), // y값을 높이면 아래쪽에만 그림자
                                    ),
                                  ],
                                ),
                                child: SettingDropdown(
                                  title: "언어",
                                  initialValue: "한국어",
                                  options: ["한국어", "영어", "일본어", "중국어"],
                                  onChanged: (String newLanguage) {
                                    setState(() {
                                      selectedLanguage = newLanguage;
                                    });
                                  },
                                  screenWidth: widget.screenWidth,
                                  screenHeight: widget.screenHeight,
                                ),
                              ),
                              SizedBox(height: 20),
                              // [3-2] 스타일
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "스타일",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        getResponsiveFontSize(
                                          widget.screenWidth,
                                        ) *
                                        0.8,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: dropdownWidgetColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        0.2,
                                      ), // 그림자 색상 및 투명도
                                      blurRadius: 3, // 그림자 흐림 정도 (자연스러운 효과)
                                      offset: Offset(0, 4), // y값을 높이면 아래쪽에만 그림자
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SettingDropdown(
                                      title: "위치",
                                      initialValue: "하단",
                                      options: ["상단", "중앙", "하단"],
                                      onChanged: (String newPosition) {
                                        setState(() {
                                          selectedPosition = newPosition;
                                        });
                                      },
                                      screenWidth: widget.screenWidth,
                                      screenHeight: widget.screenHeight,
                                    ),
                                    SettingDropdown(
                                      title: "스타일",
                                      initialValue: "기본",
                                      options: ["기본", "굵게", "이탤릭"],
                                      onChanged: (String newStyle) {
                                        setState(() {
                                          selectedStyle = newStyle;
                                        });
                                      },
                                      screenWidth: widget.screenWidth,
                                      screenHeight: widget.screenHeight,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),

                              // [3-3] 텍스트
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "텍스트",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        getResponsiveFontSize(
                                          widget.screenWidth,
                                        ) *
                                        0.8,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: dropdownWidgetColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        0.2,
                                      ), // 그림자 색상 및 투명도
                                      blurRadius: 3, // 그림자 흐림 정도 (자연스러운 효과)
                                      offset: Offset(0, 4), // y값을 높이면 아래쪽에만 그림자
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SettingDropdown(
                                      title: "크기",
                                      initialValue: "크게",
                                      options: ["작게", "중간", "크게", "매우 크게"],
                                      onChanged: (String newPosition) {
                                        setState(() {
                                          selectedPosition = newPosition;
                                        });
                                      },
                                      screenWidth: widget.screenWidth,
                                      screenHeight: widget.screenHeight,
                                    ),
                                    ColorSettingDropDown(
                                      title: "색상",
                                      initialValue: "검정",
                                      options: [
                                        "빨강",
                                        "주황",
                                        "노랑",
                                        "초록",
                                        "파랑",
                                        "보라",
                                        "검정",
                                        "흰색",
                                      ],
                                      onChanged: (String newColor) {
                                        setState(() {
                                          selectedTextColor =
                                              newColor; // 적절한 변수명으로 변경
                                        });
                                      },
                                      screenWidth: widget.screenWidth,
                                      screenHeight: widget.screenHeight,
                                      isColorSelector: true,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),

                              // [3-4] 배경
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "배경",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        getResponsiveFontSize(
                                          widget.screenWidth,
                                        ) *
                                        0.8,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: dropdownWidgetColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        0.2,
                                      ), // 그림자 색상 및 투명도
                                      blurRadius: 3, // 그림자 흐림 정도 (자연스러운 효과)
                                      offset: Offset(0, 4), // y값을 높이면 아래쪽에만 그림자
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    ColorSettingDropDown(
                                      title: "색상",
                                      initialValue: "검정",
                                      options: [
                                        "빨강",
                                        "주황",
                                        "노랑",
                                        "초록",
                                        "파랑",
                                        "보라",
                                        "검정",
                                        "흰색",
                                      ],
                                      onChanged: (String newColor) {
                                        setState(() {
                                          selectedTextColor =
                                              newColor; // 적절한 변수명으로 변경
                                        });
                                      },
                                      screenWidth: widget.screenWidth,
                                      screenHeight: widget.screenHeight,
                                      isColorSelector: true,
                                    ),
                                    ColorSettingDropDown(
                                      title: "불투명도",
                                      initialValue: "50%",
                                      options: [
                                        "0%",
                                        "25%",
                                        "50%",
                                        "75%",
                                        "100%",
                                      ],
                                      onChanged: (String newOpacity) {
                                        setState(() {
                                          selectedOpacity = newOpacity;
                                        });
                                      },
                                      screenWidth: widget.screenWidth,
                                      screenHeight: widget.screenHeight,
                                      isColorSelector: false, // 불투명도 선택기로 설정
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
