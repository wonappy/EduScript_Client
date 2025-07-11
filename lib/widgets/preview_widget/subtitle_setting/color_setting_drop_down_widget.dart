import 'package:client/core/styles/color_core.dart';
import 'package:flutter/material.dart';
import '../../../core/global_core.dart';

/// 환경 설정 드롭다운 메뉴 (2) - 색상 & 불투명도
class ColorSettingDropDown extends StatefulWidget {
  final String title; // 제목 
  final String initialValue; // 초깃값
  final List<String> options; // 옵션들
  final Function(String) onChanged; // 콜백
  final double screenWidth; // 스크린 너비
  final double screenHeight; // 스크린 높이
  final Color? backgroundColor; // 드롭다운 배경색
  final bool isColorSelector; // 색깔 선택기 or 불투명도 선택기

  const ColorSettingDropDown({
    super.key,
    required this.title,
    required this.initialValue,
    required this.options,
    required this.onChanged,
    required this.screenWidth,
    required this.screenHeight,
    this.backgroundColor,
    this.isColorSelector = true,
  });

  @override
  State<ColorSettingDropDown> createState() => _ColorSettingDropDownState();
}

class _ColorSettingDropDownState extends State<ColorSettingDropDown> {
  late String selectedValue;
  final _buttonFocusNode = FocusNode(debugLabel: 'Color Setting Dropdown Button');

  // [상수] 
  // 동그라미
  static const double _circleSize = 16.0; // 동그라미 크기
  static const double _borderWidth = 1.0; // 동그라미 테두리
  static const _opacityBaseColor = Color.fromRGBO(33, 150, 243, 1.0); // 불투명도 표시용 기본 색상
  
  // 색상 매핑
  static const _colorMap = {
    '빨강': Colors.red,
    '주황': Colors.orange,
    '노랑': Colors.yellow,
    '초록': Colors.green,
    '파랑': Colors.blue,
    '보라': Colors.purple,
    '검정': Colors.black,
    '흰색': Colors.white,
  };

  // [반응 처리]
  // 초기화 - 선택된 값 
  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  // 메모리 해제
  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  // 옵션 선택 -> 콜백 처리
  void _selectOption(String option) {
    setState(() => selectedValue = option);
    widget.onChanged(option);
  }

  // 폰트 크기
  double get _fontSize => getResponsiveFontSize(widget.screenWidth) * 0.8;

  // === Color/Opacity 도우미 메서드들 ===
  
  /// 색상 이름을 Color 객체로 변환
  Color _getColorFromName(String colorName) => _colorMap[colorName] ?? Colors.grey;
  
  /// 불투명도 문자열을 double 값으로 변환 (예: "50%" -> 0.5)
  double _getOpacityValue(String opacityString) {
    final numericPart = opacityString.replaceAll('%', '');
    return (double.tryParse(numericPart) ?? 0) / 100.0;
  }

  // [1] 동그라미 위젯
  // 색상 미리보기 동그라미 생성
  Widget _buildColorCircle(String colorName) {
    final color = _getColorFromName(colorName);
    final needsBorder = colorName == '흰색'; // 흰색은 테두리 필요
    
    return Container(
      width: _circleSize,
      height: _circleSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: needsBorder 
          ? Border.all(color: Colors.grey[400]!, width: _borderWidth)
          : null,
      ),
    );
  }

  // 불투명도 미리보기 동그라미 생성 - 흰 배경 위에 불투명도가 적용된 색상 레이어
  Widget _buildOpacityCircle(String opacityString) {
    final opacity = _getOpacityValue(opacityString);
    
    return Container(
      width: _circleSize,
      height: _circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[400]!, width: _borderWidth),
      ),
      child: ClipOval(
        child: Stack(
          children: [
            Container(color: Colors.white), // 흰색 배경
            Container(color: _opacityBaseColor.withOpacity(opacity)), // 불투명도 레이어
          ],
        ),
      ),
    );
  }

  // 색상/불투명도 구분에 따른 미리보기 동그라미 선택
  Widget _buildPreviewCircle(String value) {
    return widget.isColorSelector 
      ? _buildColorCircle(value)
      : _buildOpacityCircle(value);
  }

  // [2] 메뉴 아이템
  // 드롭다운 메뉴 아이템들 리스트 생성
  List<Widget> _buildMenuItems() {
    return widget.options.map((option) => 
      MenuItemButton(
        style: _menuItemStyle,
        onPressed: () => _selectOption(option),
        child: _buildMenuItem(option),
      )
    ).toList();
  }

  /// 개별 메뉴 아이템 위젯 생성 - 미리보기 동그라미 + 텍스트
  Widget _buildMenuItem(String option) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.05,
        child: Row(
          children: [
            _buildPreviewCircle(option), // 색상/불투명도 미리보기
            const SizedBox(width: 8),
            Text(
              option,
              style: TextStyle(
                color: Colors.white,
                fontSize: _fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [3] 스타일 정의
  // 메뉴 아이템 버튼 스타일 - 호버 시 색상 변경
  ButtonStyle get _menuItemStyle => ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      return states.contains(WidgetState.hovered) 
        ? Colors.blueGrey[600]! 
        : Colors.transparent;
    }),
  );

  // 드롭다운 메뉴 전체 스타일
  MenuStyle get _menuStyle => MenuStyle(
    backgroundColor: WidgetStateProperty.all(Colors.blueGrey[700]),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  // === 선택된 값 표시 ===
  
  /// 현재 선택된 값 표시 위젯 - 미리보기 동그라미 + 텍스트 + 화살표 아이콘
  Widget _buildSelectedValue() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPreviewCircle(selectedValue), // 선택된 값의 미리보기
        const SizedBox(width: 8),
        Text(
          selectedValue,
          style: TextStyle(
            color: Colors.black,
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 5),
        Icon(
          Icons.keyboard_arrow_down,
          color: Colors.black,
          size: getResponsiveFontSize(widget.screenWidth) * 1.5,
        ),
      ],
    );
  }

  /// 메인 위젯 빌드 - 제목 + 드롭다운 버튼으로 구성
  @override
  Widget build(BuildContext context) {
    return Container(
      //padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.whiteColor1,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 제목 텍스트
          Text(
            widget.title,
            style: TextStyle(
              fontSize: getResponsiveFontSize(widget.screenWidth) * 0.85,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          // 오른쪽: 드롭다운 메뉴
          MenuAnchor(
            childFocusNode: _buttonFocusNode,
            style: _menuStyle,
            menuChildren: _buildMenuItems(),
            builder: (context, controller, child) => InkWell(
              focusNode: _buttonFocusNode,
              onTap: controller.isOpen ? controller.close : controller.open,
              borderRadius: BorderRadius.circular(5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _buildSelectedValue(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}