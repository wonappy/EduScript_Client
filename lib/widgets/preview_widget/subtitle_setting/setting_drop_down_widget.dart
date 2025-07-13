import 'package:client/core/styles/color_core.dart';
import 'package:client/core/styles/size_core.dart';
import 'package:flutter/material.dart';

/// 환경 설정 드롭다운 메뉴 (1) - 위치, 스타일, 크기

class SettingDropdown extends StatefulWidget {
  final String title; // 제목
  final String initialValue; // 초기값
  final List<String> options; // 옵션 List
  final Function(String) onChanged; // 상태가 바뀌었을 때
  final double screenWidth; // 너비
  final double screenHeight; // 높이
  //final Widget Function(String)? customDisplay;
  final Color? backgroundColor; // 배경색

  const SettingDropdown({
    super.key,
    required this.title,
    required this.initialValue,
    required this.options,
    required this.onChanged,
    required this.screenWidth,
    required this.screenHeight,
    //this.customDisplay,
    this.backgroundColor,
  });

  @override
  State<SettingDropdown> createState() => _SettingDropdownState();
}

class _SettingDropdownState extends State<SettingDropdown> {
  MaterialColor dropdownMaterialColor = Colors.blueGrey; // 드롭다운 항목 배경색
  late String selectedValue; // 선택된 값
  final FocusNode _buttonFocusNode = FocusNode(
    debugLabel: 'Setting Dropdown Button',
  );

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  void _selectOption(String option) {
    setState(() {
      selectedValue = option;
    });
    // 부모 위젯에 변경 알림
    widget.onChanged(option);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.whiteColor1,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // [1] 제목
          Text(
            widget.title,
            style: TextStyle(
              fontSize: AppSizes.baseFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          // [2] 드롭 다운
          MenuAnchor(
            childFocusNode: _buttonFocusNode,
            style: MenuStyle(
              // [2-1] 메뉴 스타일
              // 배경색
              backgroundColor: WidgetStateProperty.all(
                dropdownMaterialColor[700],
              ),
              // 모양 (둥근 모서리)
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            // [2-2] 메뉴 아이템 생성
            menuChildren:
                widget.options.map((String option) {
                  return MenuItemButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        // 마우스 호버 시
                        if (states.contains(WidgetState.hovered)) {
                          return dropdownMaterialColor[600]!;
                        }
                        // 기본 상태 = 부모 색상
                        return Colors.transparent;
                      }),
                    ),
                    onPressed: () => _selectOption(option), // 🔴 선택 시 실행할 함수
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width:
                            MediaQuery.of(context).size.width *
                            0.05, // 메뉴 항목 너비
                        child: Text(
                          option, // 선택 항목
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppSizes.smallFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),

            // [2-3] 드롭다운 버튼
            builder: (
              BuildContext context,
              MenuController controller,
              Widget? child,
            ) {
              return InkWell(
                focusNode: _buttonFocusNode,
                onTap: () {
                  // 🔴 드롭다운 버튼 클릭 시 이벤트
                  if (controller.isOpen) {
                    // 열려있으면 닫기
                    controller.close();
                  } else {
                    // 닫혀있으면 열기
                    controller.open();
                  }
                },
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedValue, // 현재 선택된 값으로 표시
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: AppSizes.baseFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black,
                        size: AppSizes.baseIconSize,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
