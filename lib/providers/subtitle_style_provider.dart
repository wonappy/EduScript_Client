import 'package:client/core/styles/size_core.dart';
import 'package:flutter/material.dart';
import '../models/language_mapping_model.dart';

/// ### 자막 스타일 설정 프로바이더
/// - 화면 공유 상태, 자막 위치, 정렬, 스타일, 크기, 색상, 배경색상, 배경불투명도
class SubtitleStyleProvider extends ChangeNotifier {
  // 초기 상태
  bool _screenSharedEnabled = false;           // 화면 공유 상태
  String _selectedPosition = '중앙';            // 자막 위치
  String _selectedHorizontalPosition = '좌측';  // 자막 정렬
  String _selectedFontStyle = '기본';           // 자막 스타일 (굵기, 이탤릭)
  String _selectedFontSize = '중간';            // 자막 크기
  String _selectedFontColor = '흰색';           // 자막 색상
  String _selectedBackgroundColor = '흰색';     // 자막 배경 색상
  String _selectedBackgroundOpacity = '0%';    // 자막 배경 불투명도

  // [Getter]
  bool get screenSharedEnabled => _screenSharedEnabled;
  String get selectedPosition => _selectedPosition;
  String get selectedHorizontalPosition => _selectedHorizontalPosition;
  String get selectedFontStyle => _selectedFontStyle;
  String get selectedFontSize => _selectedFontSize;
  String get selectedFontColor => _selectedFontColor;
  String get selectedBackgroundColor => _selectedBackgroundColor;
  String get selectedBackgroundOpacity => _selectedBackgroundOpacity;

  // [Update]
  // 1) 화면 공유(오버레이) 모드 변경
  void updateScreenSharedEnabled(bool enabled) {
    _screenSharedEnabled = enabled;
    notifyListeners();
    debugPrint("[DEBUG] 화면 공유(오버레이) 모드 : $screenSharedEnabled");
  }

  // 2) 자막 위치 설정 변경
  void updatePosition(String position) {
    _selectedPosition = position;
    notifyListeners();
  }

  // 2-1) 자막 가로 위치 설정 변경
  void updateHorizontalPosition(String position) {
    _selectedHorizontalPosition = position;
    notifyListeners();
  }

  // 3) 폰트 스타일 설정 변경
  void updateFontStyle(String style) {
    _selectedFontStyle = style;
    notifyListeners();
  }

  // 4) 폰트 크기 설정 변경
  void updateFontSize(String size) {
    _selectedFontSize = size;
    notifyListeners();
  }

  // 5) 폰트 색상 설정 변경
  void updateFontColor(String color) {
    _selectedFontColor = color;
    notifyListeners();
  }

  // 6) 자막 배경색 설정 변경
  void updateBackgroundColor(String color) {
    _selectedBackgroundColor = color;
    notifyListeners();
  }

  // 7) 자막 배경색 투명도 설정 변경
  void updateBackgroundOpacity(String opacity) {
    _selectedBackgroundOpacity = opacity;
    notifyListeners();
  }

  // [드롭다운 값]
  MainAxisAlignment getAlignment() {
    switch (_selectedPosition) {
      case '상단':
        return MainAxisAlignment.start;
      case '중앙':
        return MainAxisAlignment.center;
      case '하단':
      default:
        return MainAxisAlignment.end;
    }
  }

  CrossAxisAlignment getHorizontalAlignment() {
    switch (_selectedHorizontalPosition) {
      case '좌측':
        return CrossAxisAlignment.start; // 왼쪽 정렬
      case '중앙':
        return CrossAxisAlignment.center; // 가운데 정렬
      case '우측':
        return CrossAxisAlignment.end; // 오른쪽 정렬
      default:
        return CrossAxisAlignment.start; // 기본값
    }
  }

  FontWeight getFontWeight() {
    return _selectedFontStyle == '굵게' ? FontWeight.bold : FontWeight.normal;
  }

  FontStyle getFontStyle() {
    return _selectedFontStyle == '이탤릭' ? FontStyle.italic : FontStyle.normal;
  }

  double getFontSize(double screenWidth) {
    double baseSize = AppSizes.smallFontSize;
    switch (_selectedFontSize) {
      case '매우 작게':
        return baseSize * 1.7;
      case '중간':
        return baseSize * 2.6;
      case '크게':
        return baseSize * 2.9;
      case '매우 크게':
        return baseSize * 3.2;
      case '작게':
      default:
        return baseSize * 2.3;
    }
  }

  Color getFontColor() {
    switch (_selectedFontColor) {
      case '빨강':
        return Colors.red;
      case '주황':
        return Colors.orange;
      case '노랑':
        return Colors.yellow;
      case '초록':
        return Colors.green;
      case '파랑':
        return Colors.blue;
      case '보라':
        return Colors.purple;
      case '검정':
        return Colors.black;
      case '흰색':
      default:
        return Colors.white;
    }
  }

  Color getBackgroundColor() {
    switch (_selectedBackgroundColor) {
      case '빨강':
        return Colors.red;
      case '주황':
        return Colors.orange;
      case '노랑':
        return Colors.yellow;
      case '초록':
        return Colors.green;
      case '파랑':
        return Colors.blue;
      case '보라':
        return Colors.purple;
      case '검정':
        return Colors.black;
      case '흰색':
      default:
        return Colors.white;
    }
  }

  double getBackgroundOpacity() {
    switch (_selectedBackgroundOpacity) {
      case '0%':
        return 0.0;
      case '25%':
        return 0.25;
      case '75%':
        return 0.75;
      case '100%':
        return 1.0;
      case '50%':
      default:
        return 0.5;
    }
  }
}
