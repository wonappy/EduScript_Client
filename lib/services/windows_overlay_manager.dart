import 'dart:ffi' hide Size; // 네이티브 함수 호출
import 'package:ffi/ffi.dart'; // C 타입 메모리 관리
import 'package:win32/win32.dart'; // Win32 API
import 'package:flutter/material.dart';

import 'package:html/parser.dart' as html_parser; //html 디코딩

import '../widgets/preview_widget/subtitle_setting_provider.dart';

class WindowsOverlayManager {
  /// 윈도우 핸들 (HWND) : 윈도우 식별 ID
  int _hwnd = 0;

  /// 윈도우 클래스 이름
  static const String _wndClassName = 'FLUTTER_OVERLAY_WINDOW';

  // 투명 배경 용 마젠타 브러쉬
  static final int _hBrushMagenta = CreateSolidBrush(RGB(255, 0, 255));

  // FFI 콜백 포인터를 GC로부터 보호하기 위한 static 변수
  static Pointer<NativeFunction<WNDPROC>>? _wndProcPtr;

  // static 변수 선언(자막 데이터와 설정값)
  static SubtitleSettingsProvider? _lastSettings;
  static Size? _lastScreenSize;
  static Map<String, String> _lastCurrentTranslations = {};
  static Map<String, String> _lastConfirmedTranslations = {};
  static List<String> _lastLanguages = [];
  // (currentSpeakingLanguage 등 필요한 것 모두 추가)

  // 번역 내용 초기화
  static void clearStaticData() {
    _lastCurrentTranslations.clear();
    _lastConfirmedTranslations.clear();
  }

  /// 1. [초기화] Win32 오버레이 윈도우 생성
  void initialize() {
    if (_hwnd != 0) return; // 이미 생성됨

    final hInstance = GetModuleHandle(nullptr); // 현재 프로세스 핸들 가져오기

    // 1) 윈도우 클래스 등록
    _wndProcPtr ??= Pointer.fromFunction<WNDPROC>(
      _windowProc,
      0, // exceptionalReturn
    );

    final wc =
        calloc<WNDCLASS>()
          ..ref.style = CS_HREDRAW | CS_VREDRAW
          ..ref.lpfnWndProc = _wndProcPtr!
          ..ref.hInstance = hInstance
          ..ref.lpszClassName = _wndClassName.toNativeUtf16()
          ..ref.hCursor = LoadCursor(NULL, IDC_ARROW)
          ..ref.hbrBackground = _hBrushMagenta;
    RegisterClass(wc);

    // 2) 윈도우 생성 (CreateWindowEx)
    _hwnd = CreateWindowEx(
      WS_EX_TOPMOST | // 항상 최상위 레이어
          WS_EX_LAYERED | // 투명도 사용
          WS_EX_TRANSPARENT | // 마우스 이벤트 통과(무시)
          WS_EX_COMPOSITED, // 더블 버퍼링 (화면 재생성 과정에서 깜빡힘 제거)
      _wndClassName.toNativeUtf16(),
      'Flutter Subtitle Overlay'.toNativeUtf16(),
      WS_POPUP,
      0,
      0, // (x, y)
      GetSystemMetrics(SM_CXSCREEN), // 모니터 너비
      GetSystemMetrics(SM_CYSCREEN), // 모니터 높이
      NULL,
      NULL,
      hInstance,
      nullptr,
    );

    if (_hwnd == 0) {
      debugPrint('- Win32: CreateWindowEx 실패');
      return;
    }

    // 3) 윈도우 투명도 설정 (LWA_COLORKEY)
    SetLayeredWindowAttributes(
      _hwnd,
      RGB(255, 0, 255), // 투명하게 만들 색상 (마젠타)
      0,
      LWA_COLORKEY,
    );

    // 4) 윈도우 표시 및 업데이트
    ShowWindow(_hwnd, SW_SHOW);
    UpdateWindow(_hwnd);

    debugPrint('- Win32: 오버레이 윈도우 생성 성공 (HWND: $_hwnd)');
  }

  /// 2. [업데이트] OS에 자막 업데이트 요청
  void update({
    required List<String> languages,
    required Map<String, String> currentTranslations,
    required Map<String, String> confirmedTranslations,
    required SubtitleSettingsProvider settings,
    required Size screenSize,
    String? currentSpeakingLanguage,
  }) {
    if (_hwnd == 0) return;

    // 기본 정보 저장
    _lastSettings = settings;
    _lastScreenSize = screenSize;
    _lastLanguages = languages;
    _lastCurrentTranslations = Map.from(currentTranslations);
    _lastConfirmedTranslations = Map.from(confirmedTranslations);

    // 윈도우 업데이트 알림
    InvalidateRect(_hwnd, nullptr, TRUE);

    // 강제 UI 업데이트!
    UpdateWindow(_hwnd);
  }

  // 3. 윈도우 제거
  void dispose() {
    if (_hwnd != 0) {
      DestroyWindow(_hwnd);
      _hwnd = 0;
      debugPrint('- Win32: 오버레이 윈도우 제거됨');
    }
    //DeleteObject(_hBrushMagenta); -> 얘가 없어지면 투명창 생성이 안되니까... 프로그램이 종료될 때 사라지도록 하기
  }

  /// 4. [이벤트 처리] Win32 윈도우 이벤트 콜백
  static int _windowProc(int hwnd, int uMsg, int wParam, int lParam) {
    switch (uMsg) {
      case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
      case WM_PAINT:
        _onPaint(hwnd);
        return 0;
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
  }

  /// 5. [그리기] WM_PAINT의 실제 그리기 로직 (상/중/하 정렬 구현)
  static void _onPaint(int hwnd) {
    final ps = calloc<PAINTSTRUCT>();
    final hdc = BeginPaint(hwnd, ps);

    final rcClient = calloc<RECT>();
    GetClientRect(hwnd, rcClient);

    // 1) 윈도우 전체를 마젠타(투명색)로 칠해서 깨끗이 지움
    FillRect(hdc, rcClient, _hBrushMagenta);

    final settings = _lastSettings;
    final screenSize = _lastScreenSize;

    // 2) 데이터가 있을 때만 그리기
    if (settings != null && screenSize != null) {
      // --- GDI 리소스 준비 ---
      final hFont = _createGdiFont(settings, screenSize);
      final hOldFont = SelectObject(hdc, hFont);
      SetBkMode(hdc, TRANSPARENT);
      SetTextColor(hdc, _flutterColorToWin32Color(Colors.white)); // 글씨 색상 (흰색)

      final hBrushBackground = CreateSolidBrush(
        RGB(0, 0, 0), // 현재 인식 중 자막 배경 색상
      );
      final hBrushOldBackground = CreateSolidBrush(
        RGB(50, 50, 50),
      ); // 인식 완료 자막 배경 색상

      // 레이아웃 값 정의
      final double scaleFactor = screenSize.width / 1167.0;
      final int spacingSmall = (7 * scaleFactor).round();
      final int spacingMedium = (15 * scaleFactor).round();
      final int padding = (10 * scaleFactor).round(); // 상하좌우 패딩
      final int drawFormat = DT_CENTER | DT_WORDBREAK | DT_NOCLIP; // 자동 줄 바꿈

      // 자막의 최대 가로 폭 (화면의 90%)
      final int maxWidth = (rcClient.ref.right * 0.9).round();

      final MainAxisAlignment alignment = settings.getAlignment();

      // Alignment.topCenter
      if (alignment == MainAxisAlignment.start) {
        int currentY = rcClient.ref.top + spacingMedium; // Y 시작점
        for (final lang in _lastLanguages) {
          final textConfirmed = _findSubtitleText(lang, true, settings);
          final textCurrent = _findSubtitleText(lang, false, settings);

          if (textConfirmed.isNotEmpty) {
            currentY = _drawTextWithBackground(
              hdc,
              textConfirmed,
              currentY,
              drawFormat,
              padding,
              rcClient.ref,
              hBrushOldBackground,
              false,
              maxWidth,
            );
            currentY += spacingSmall;
          }
          if (textCurrent.isNotEmpty) {
            currentY = _drawTextWithBackground(
              hdc,
              textCurrent,
              currentY,
              drawFormat,
              padding,
              rcClient.ref,
              hBrushBackground,
              false,
              maxWidth,
            );
            currentY += spacingMedium;
          }
        }
      } else if (alignment == MainAxisAlignment.center) {
        // 1. 모든 자막의 총 높이 계산
        int totalHeight = 0;
        final rcCalc = calloc<RECT>();

        for (final lang in _lastLanguages) {
          final textConfirmed = _findSubtitleText(lang, true, settings);
          final textCurrent = _findSubtitleText(lang, false, settings);

          if (textConfirmed.isNotEmpty) {
            SetRect(rcCalc, 0, 0, maxWidth, 0);
            DrawText(
              hdc,
              textConfirmed.toNativeUtf16(),
              -1,
              rcCalc,
              DT_CALCRECT | drawFormat,
            );
            totalHeight += rcCalc.ref.bottom + (padding * 2) + spacingSmall;
          }
          if (textCurrent.isNotEmpty) {
            SetRect(rcCalc, 0, 0, maxWidth, 0);
            DrawText(
              hdc,
              textCurrent.toNativeUtf16(),
              -1,
              rcCalc,
              DT_CALCRECT | drawFormat,
            );
            totalHeight += rcCalc.ref.bottom + (padding * 2) + spacingMedium;
          }
        }
        calloc.free(rcCalc);

        // 2. 그리기 시작 Y 좌표 계산 (화면 중앙)
        int currentY = (rcClient.ref.bottom - totalHeight) ~/ 2 + spacingMedium;

        // 3. 위에서 아래로 그리기
        for (final lang in _lastLanguages) {
          final textConfirmed = _findSubtitleText(lang, true, settings);
          final textCurrent = _findSubtitleText(lang, false, settings);
          if (textConfirmed.isNotEmpty) {
            currentY = _drawTextWithBackground(
              hdc,
              textConfirmed,
              currentY,
              drawFormat,
              padding,
              rcClient.ref,
              hBrushOldBackground,
              false,
              maxWidth,
            );
            currentY += spacingSmall;
          }
          if (textCurrent.isNotEmpty) {
            currentY = _drawTextWithBackground(
              hdc,
              textCurrent,
              currentY,
              drawFormat,
              padding,
              rcClient.ref,
              hBrushBackground,
              false,
              maxWidth,
            );
            currentY += spacingMedium;
          }
        }
      } else {
        int currentY = rcClient.ref.bottom - spacingMedium; // Y 시작점
        for (final lang in _lastLanguages.reversed) {
          final textConfirmed = _findSubtitleText(lang, true, settings);
          final textCurrent = _findSubtitleText(lang, false, settings);

          if (textCurrent.isNotEmpty) {
            currentY = _drawTextWithBackground(
              hdc,
              textCurrent,
              currentY,
              drawFormat,
              padding,
              rcClient.ref,
              hBrushBackground,
              true,
              maxWidth,
            );
            currentY -= spacingSmall;
          }
          if (textConfirmed.isNotEmpty) {
            currentY = _drawTextWithBackground(
              hdc,
              textConfirmed,
              currentY,
              drawFormat,
              padding,
              rcClient.ref,
              hBrushOldBackground,
              true,
              maxWidth,
            );
            currentY -= spacingMedium;
          }
        }
      }

      // GDI 리소스 정리
      DeleteObject(hBrushBackground);
      DeleteObject(hBrushOldBackground);
      SelectObject(hdc, hOldFont);
      DeleteObject(hFont);
    }

    // 5. 리소스 최종 정리
    calloc.free(rcClient);
    EndPaint(hwnd, ps);
    calloc.free(ps);
  }

  /// 6. Flutter 설정을 Win32 GDI 폰트로 변환
  static int _createGdiFont(
    SubtitleSettingsProvider settings,
    Size screenSize,
  ) {
    final lf = calloc<LOGFONT>();
    final logicalScreenHeight = GetDeviceCaps(GetDC(NULL), LOGPIXELSY);

    // 1. 폰트 크기 (요청대로 크기만 설정)
    final fontSize = settings.getFontSize(screenSize.width);
    lf.ref.lfHeight = -(fontSize * logicalScreenHeight / 72).round();

    // 2. 폰트 굵기 (기본값)
    lf.ref.lfWeight = 400;

    // 3. 이탤릭체 (기본값)
    lf.ref.lfItalic = 0;

    // 4. 폰트 지정 (맑은 고딕)
    lf.ref.lfCharSet =
        129; // 한글 강제 지정 -> 아랍어, 태국어 등은 깨짐...!!!언어 확장 시 코드 수정 필요 ㅠ.ㅠ

    // 5. 설정이 완료된 폰트 정보(lf)로 GDI 폰트 생성
    final hFont = CreateFontIndirect(lf);

    calloc.free(lf);

    return hFont;
  }

  /// 7. Flutter Color -> Win32 COLORREF (RGB)
  static int _flutterColorToWin32Color(Color color) {
    return RGB(color.red, color.green, color.blue);
  }

  /// 8. 자막 텍스트 매핑
  static String _findSubtitleText(
    String displayLanguage,
    bool isConfirmedLine,
    SubtitleSettingsProvider settings,
  ) {
    final targetTranslations =
        isConfirmedLine ? _lastConfirmedTranslations : _lastCurrentTranslations;

    String rawText = "..."; // 기본값
    bool found = false;

    final outputLanguages = settings.selectedOutputLanguages;
    final outputCodes = settings.getOutputLanguageCodes();
    String? googleCode;
    for (int i = 0; i < outputLanguages.length; i++) {
      if (outputLanguages[i] == displayLanguage && i < outputCodes.length) {
        googleCode = outputCodes[i];
        break;
      }
    }
    final availableKeys = targetTranslations.keys.toList();
    for (String key in availableKeys) {
      if (settings.getDisplayNameFromAzureCode(key) == displayLanguage) {
        rawText = targetTranslations[key] ?? "...";
        found = true;
        break;
      }
      if (settings.getDisplayNameFromGoogleCode(key) == displayLanguage) {
        rawText = targetTranslations[key] ?? "...";
        found = true;
        break;
      }
    }
    if (!found && googleCode != null && availableKeys.contains(googleCode)) {
      rawText = targetTranslations[googleCode] ?? "...";
      found = true;
    }
    if (!found && targetTranslations.containsKey(displayLanguage)) {
      rawText = targetTranslations[displayLanguage]!;
      found = true;
    }
    if (!found &&
        googleCode != null &&
        targetTranslations.containsKey(googleCode)) {
      rawText = targetTranslations[googleCode]!;
      found = true;
    }

    // HTML 디코딩 로직
    var document = html_parser.parse(rawText);
    String processedText = document.documentElement?.text ?? rawText;

    return processedText;
  }

  /// 9. GDI 배경과 텍스트 생성 함수
  static int _drawTextWithBackground(
    int hdc,
    String text,
    int startY,
    int drawFormat,
    int padding,
    RECT rcClient,
    int hBrush, // HBRUSH
    bool drawUpwards,
    int maxWidth,
  ) {
    // 1. 텍스트 크기 계산
    final rcCalc = calloc<RECT>();
    rcCalc.ref.right = maxWidth;

    DrawText(hdc, text.toNativeUtf16(), -1, rcCalc, DT_CALCRECT | drawFormat);
    final int textWidth = rcCalc.ref.right;
    final int textHeight = rcCalc.ref.bottom;
    calloc.free(rcCalc);

    // 2. 배경 RECT 계산
    final int bgWidth =
        (textWidth > maxWidth ? maxWidth : textWidth) + (padding * 2);
    final int bgHeight = textHeight + (padding * 2);
    final int bgLeft = (rcClient.right - bgWidth) ~/ 2; // 화면 중앙

    final rcBg = calloc<RECT>();
    int nextY;

    if (drawUpwards) {
      // (하단 정렬) Y 좌표를 위로 이동
      final int bgTop = startY - bgHeight;
      SetRect(rcBg, bgLeft, bgTop, bgLeft + bgWidth, startY);
      nextY = bgTop;
    } else {
      // (상단/중앙 정렬) Y 좌표를 아래로 이동
      final int bgBottom = startY + bgHeight;
      SetRect(rcBg, bgLeft, startY, bgLeft + bgWidth, bgBottom);
      nextY = bgBottom; // 다음 Y 좌표는 방금 그린 사각형의 하단
    }

    FillRect(hdc, rcBg, hBrush);
    DrawText(hdc, text.toNativeUtf16(), -1, rcBg, drawFormat | DT_VCENTER);

    calloc.free(rcBg);
    return nextY;
  }
}
