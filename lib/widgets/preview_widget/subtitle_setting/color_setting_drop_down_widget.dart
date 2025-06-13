import 'package:flutter/material.dart';
import '../../../core/global_core.dart';

class ColorSettingDropDown extends StatefulWidget {
  final String title; // 제목
  final String initialValue; // 초기값
  final List<String> options; // 항목
  final Function(String) onChanged; // 콜백
  final double screenWidth; // 너비
  final double screenHeight; // 높이
  final Color? backgroundColor; // 배경색
  final bool isColorSelector; // 불투명도 선택기인지 구분

  const ColorSettingDropDown({
    super.key,
    required this.title,
    required this.initialValue,
    required this.options,
    required this.onChanged,
    required this.screenWidth,
    required this.screenHeight,
    this.backgroundColor,
    this.isColorSelector = true, // 기본값은 색상 선택기
  });

  @override
  State<ColorSettingDropDown> createState() => _ColorSettingDropDownState();
}

class _ColorSettingDropDownState extends State<ColorSettingDropDown> {
  late String selectedValue;
  final FocusNode _buttonFocusNode = FocusNode(
    debugLabel: 'Color Setting Dropdown Button',
  );

  // 색상 이름을 Color 객체로 매핑
  final Map<String, Color> colorMap = {
    '빨강': Colors.red,
    '주황': Colors.orange,
    '노랑': Colors.yellow,
    '초록': Colors.green,
    '파랑': Colors.blue,
    '보라': Colors.purple,
    '검정': Colors.black,
    '흰색': Colors.white,
  };

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
    widget.onChanged(option);
  }

  Color _getColorFromName(String colorName) {
    return colorMap[colorName] ?? Colors.grey;
  }

  // 불투명도 값을 double로 변환 (예: "50%" -> 0.5)
  double _getOpacityFromString(String opacityString) {
    String numericPart = opacityString.replaceAll('%', '');
    return double.tryParse(numericPart)! / 100.0;
  }

  // 불투명도에 따른 색상 생성 (더 눈에 띄게)
  Color _getOpacityColor(String opacityString) {
    double opacity = _getOpacityFromString(opacityString);
    // 파란색 기준으로 불투명도 적용 (더 눈에 띄게)
    return Color.fromRGBO(33, 150, 243, opacity); // Material Blue
  }

  // 불투명도 원 위젯 (배경 포함)
  Widget _buildOpacityCircle(String opacityString) {
    double opacity = _getOpacityFromString(opacityString);

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      child: ClipOval(
        child: Stack(
          children: [
            // 흰색 배경
            Container(color: Colors.white),
            // 불투명도 레이어
            Container(
              decoration: BoxDecoration(
                color: Color.fromRGBO(33, 150, 243, opacity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: getResponsiveFontSize(widget.screenWidth) * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          MenuAnchor(
            childFocusNode: _buttonFocusNode,
            style: MenuStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blueGrey[700]),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            menuChildren:
                widget.options.map((String option) {
                  return MenuItemButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.hovered)) {
                            return Colors.blueGrey[600]!;
                          }
                          return Colors.transparent;
                        },
                      ),
                    ),
                    onPressed: () => _selectOption(option),
                    child: Container(
                      width: 120,
                      child: Row(
                        children: [
                          // 색상/불투명도 미리보기 동그라미
                          widget.isColorSelector
                              ? Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getColorFromName(option),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        option == '흰색'
                                            ? Colors.grey[400]!
                                            : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                              )
                              : _buildOpacityCircle(option),

                          SizedBox(width: 8),
                          // 옵션 이름
                          Text(
                            option,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  getResponsiveFontSize(widget.screenWidth) *
                                  0.75,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            builder: (
              BuildContext context,
              MenuController controller,
              Widget? child,
            ) {
              return InkWell(
                focusNode: _buttonFocusNode,
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 선택된 색상/불투명도 미리보기 동그라미
                      widget.isColorSelector
                          ? Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getColorFromName(selectedValue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    selectedValue == '흰색'
                                        ? Colors.grey[400]!
                                        : Colors.transparent,
                                width: 1,
                              ),
                            ),
                          )
                          : _buildOpacityCircle(selectedValue),
                      SizedBox(width: 8),
                      // 선택된 값 이름
                      Text(
                        selectedValue,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize:
                              getResponsiveFontSize(widget.screenWidth) * 0.8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black,
                        size: getResponsiveFontSize(widget.screenWidth) * 1.5,
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
