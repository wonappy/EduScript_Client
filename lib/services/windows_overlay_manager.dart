import 'dart:ffi' hide Size; // 네이티브 함수 호출
import 'package:client/providers/language_setting_provider.dart';
import 'package:ffi/ffi.dart'; // C 타입 메모리 관리
import 'package:win32/win32.dart'; // Win32 API
import 'package:flutter/material.dart';

import 'package:html/parser.dart' as html_parser; //html 디코딩

import '../providers/subtitle_style_provider.dart';

class WindowsOverlayManager {
  /// 윈도우 핸들 (HWND) : 윈도우 식별 ID
  int _hwnd = 0;

  /// 윈도우 클래스 이름
  String _currentWndClassName = '';

  // 투명 배경 용 마젠타 브러쉬
  int _hBrushMagenta = 0;

  // FFI 콜백 포인터를 GC로부터 보호하기 위한 static 변수
  static Pointer<NativeFunction<WNDPROC>>? _wndProcPtr;

  // static 변수 선언(자막 데이터와 설정값)
  static SubtitleStyleProvider? _lastStyles;
  static LanguageSettingProvider? _lastSettings;
  static Size? _lastScreenSize;
  static Map<String, String> _lastCurrentTranslations = {};
  static Map<String, String> _lastConfirmedTranslations = {};
  static List<String> _lastLanguages = [];

  // 번역 내용 초기화
  static void clearStaticData() {
    _lastCurrentTranslations.clear();
    _lastConfirmedTranslations.clear();
  }

  /// 1. [초기화] Win32 오버레이 윈도우 생성
  void initialize() {
    if (_hwnd != 0) return; // 이미 생성됨

    final hInstance = GetModuleHandle(nullptr); // 현재 프로세스 핸들 가져오기

    //윈도우 클래스 이름 생성 (현재 시간으로 랜덤한 이름 생성)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentWndClassName = 'FLUTTER_OVERLAY_$timestamp';

    // 1) 윈도우 클래스 등록
    _wndProcPtr = Pointer.fromFunction<WNDPROC>(_windowProc, 0);

    _hBrushMagenta = CreateSolidBrush(RGB(255, 0, 255));

    final classNamePtr = _currentWndClassName.toNativeUtf16();
    final windowNamePtr = 'Flutter Subtitle Overlay'.toNativeUtf16();

    final wc =
        calloc<WNDCLASS>()
          ..ref.style = CS_HREDRAW | CS_VREDRAW
          ..ref.lpfnWndProc = _wndProcPtr!
          ..ref.hInstance = hInstance
          ..ref.lpszClassName = _currentWndClassName.toNativeUtf16()
          ..ref.hCursor = LoadCursor(NULL, IDC_ARROW)
          ..ref.hbrBackground = _hBrushMagenta;

    final atom = RegisterClass(wc);
    if (atom == 0) {
      final error = GetLastError();
      debugPrint("[Win32 Error] RegisterClass 실패! Code: $error");
    }

    // 2) 윈도우 생성
    _hwnd = CreateWindowEx(
      WS_EX_TOPMOST | // 항상 최상위 레이어
          WS_EX_LAYERED | // 투명도 사용
          WS_EX_TRANSPARENT | // 마우스 이벤트 통과(무시)
          WS_EX_COMPOSITED | // 더블 버퍼링 (화면 재생성 과정에서 깜빡힘 제거)
          WS_EX_TOOLWINDOW, //작업 표시줄 숨기기
      classNamePtr,
      windowNamePtr,
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
      final error = GetLastError();
      debugPrint('[Win32 Error] CreateWindowEx 실패! Code: $error');

      // 실패 시 정리
      DeleteObject(_hBrushMagenta);
      calloc.free(classNamePtr);
      calloc.free(windowNamePtr);
      calloc.free(wc);
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

    debugPrint('[Win32] 오버레이 윈도우 생성 성공 (HWND: $_hwnd)');

    // 메모리 해제
    calloc.free(classNamePtr);
    calloc.free(windowNamePtr);
    calloc.free(wc);
  }

  /// 2. [업데이트] OS에 자막 업데이트 요청
  void update({
    required List<String> languages,
    required Map<String, String> currentTranslations,
    required Map<String, String> confirmedTranslations,
    required LanguageSettingProvider settings,
    required SubtitleStyleProvider styles,
    required Size screenSize,
    String? currentSpeakingLanguage,
  }) {
    if (_hwnd == 0) return;

    // 기본 정보 저장
    _lastSettings = settings;
    _lastStyles = styles;
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
      debugPrint('[Win32] 오버레이 윈도우 제거됨');
    }

    // 클래스 해제
    if (_currentWndClassName.isNotEmpty) {
      final hInstance = GetModuleHandle(nullptr);
      final classNamePtr = _currentWndClassName.toNativeUtf16();
      UnregisterClass(classNamePtr, hInstance);
      calloc.free(classNamePtr);
      _currentWndClassName = '';
    }

    // 브러시 제거
    if (_hBrushMagenta != 0) {
      DeleteObject(_hBrushMagenta);
      _hBrushMagenta = 0;
    }

    // 콜백 포인터 초기화
    _wndProcPtr = null;

    clearStaticData();
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

  /// 5. 실제 그리기 로직 (상/중/하 정렬 구현)
  static void _onPaint(int hwnd) {
    final ps = calloc<PAINTSTRUCT>();
    final hdc = BeginPaint(hwnd, ps);
    final rcClient = calloc<RECT>();
    GetClientRect(hwnd, rcClient);

    // [수정] 여기서 브러시 잠깐 생성해서 칠하고 삭제
    final hTempBrush = CreateSolidBrush(RGB(255, 0, 255));
    FillRect(hdc, rcClient, hTempBrush);
    DeleteObject(hTempBrush);

    final styles = _lastStyles;
    final settings = _lastSettings;
    final screenSize = _lastScreenSize;

    if (styles != null && screenSize != null) {
      final hFont = _createGdiFont(styles, screenSize);
      final hBrushBackground = CreateSolidBrush(RGB(0, 0, 0));

      final hOldFont = SelectObject(hdc, hFont);
      try {
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, _flutterColorToWin32Color(Colors.white));

        final alignment = styles.getAlignment();
        final horizontalAlignment = styles.getHorizontalAlignment();

        int textAlignFlag;
        switch (horizontalAlignment) {
          case CrossAxisAlignment.center:
            textAlignFlag = DT_CENTER;
            break;
          case CrossAxisAlignment.end:
            textAlignFlag = DT_RIGHT;
            break;
          case CrossAxisAlignment.start:
          default:
            textAlignFlag = DT_LEFT;
            break;
        }

        final double scaleFactor = screenSize.width / 1167.0;
        final int spacingMedium = (15 * scaleFactor).round();
        final int padding = (10 * scaleFactor).round();
        final int drawFormat = textAlignFlag | DT_WORDBREAK | DT_NOCLIP;
        final int maxWidth = (rcClient.ref.right * 0.9).round();

        void drawSubtitles(int startY, bool isUpwards) {
          int currentY = startY;
          final langs =
              isUpwards ? _lastLanguages.reversed.toList() : _lastLanguages;

          for (final lang in langs) {
            final textConfirmed = _findSubtitleText(lang, true, settings!);
            final String processedText =
                textConfirmed;

            if (processedText.isNotEmpty && processedText != "...") {
              currentY = _drawTextWithBackground(
                hdc,
                processedText,
                currentY,
                drawFormat,
                padding,
                rcClient.ref,
                hBrushBackground,
                isUpwards,
                maxWidth,
                horizontalAlignment,
              );
              if (isUpwards)
                currentY -= spacingMedium;
              else
                currentY += spacingMedium;
            }
          }
        }

        if (alignment == MainAxisAlignment.start) {
          drawSubtitles(rcClient.ref.top + spacingMedium, false);
        } else if (alignment == MainAxisAlignment.center) {
          int totalHeight = 0;
          final rcCalc = calloc<RECT>();
          for (final lang in _lastLanguages) {
            final textConfirmed = _findSubtitleText(lang, true, settings!);
            final String processedText =
                textConfirmed; //_truncateText(textConfirmed);
            if (processedText.isNotEmpty && processedText != "...") {
              SetRect(rcCalc, 0, 0, maxWidth, 0);
              final textPtr = processedText.toNativeUtf16();
              DrawText(hdc, textPtr, -1, rcCalc, DT_CALCRECT | drawFormat);
              calloc.free(textPtr);
              totalHeight += rcCalc.ref.bottom + (padding * 2) + spacingMedium;
            }
          }
          calloc.free(rcCalc);
          int startY = (rcClient.ref.bottom - totalHeight) ~/ 2 + spacingMedium;
          drawSubtitles(startY, false);
        } else {
          drawSubtitles(rcClient.ref.bottom - spacingMedium, true);
        }
      } finally {
        // GDI 리소스 정리 => 무조건 실행!! (GDI 리소수 누수 현상 방지)
        SelectObject(hdc, hOldFont); //예전 폰트로 선택 변경

        DeleteObject(hBrushBackground);
        DeleteObject(hFont);
      }
    }

    // 5. 리소스 최종 정리
    calloc.free(rcClient);
    EndPaint(hwnd, ps);
    calloc.free(ps);
  }

  /// 6. Flutter 설정을 Win32 GDI 폰트로 변환
  static int _createGdiFont(
    SubtitleStyleProvider styles,
    Size screenSize,
  ) {
    final lf = calloc<LOGFONT>();

    final hdc = GetDC(NULL);
    final logicalScreenHeight = GetDeviceCaps(hdc, LOGPIXELSY);
    ReleaseDC(NULL, hdc);

    // 1. 폰트 크기 (요청대로 크기만 설정)
    final fontSize = styles.getFontSize(screenSize.width);
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
    LanguageSettingProvider settings
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
    CrossAxisAlignment hAlign,
  ) {
    final textPtr = text.toNativeUtf16();

    // 1. 텍스트 크기 계산
    final rcCalc = calloc<RECT>();
    rcCalc.ref.right = maxWidth;

    DrawText(hdc, textPtr, -1, rcCalc, DT_CALCRECT | drawFormat);
    final int textWidth = rcCalc.ref.right;
    final int textHeight = rcCalc.ref.bottom;
    calloc.free(rcCalc);

    // 2. 배경 RECT 계산
    final int bgWidth =
        (textWidth > maxWidth ? maxWidth : textWidth) + (padding * 2);
    final int bgHeight = textHeight + (padding * 2);
    final int bgLeft;
    if (hAlign == CrossAxisAlignment.start) {
      bgLeft = (rcClient.right * 0.05).round();
    } else if (hAlign == CrossAxisAlignment.center) {
      bgLeft = (rcClient.right - bgWidth) ~/ 2;
    } else {
      bgLeft = (rcClient.right * 0.95).round() - bgWidth;
    }

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
    DrawText(hdc, textPtr, -1, rcBg, drawFormat | DT_TOP);

    calloc.free(rcBg);
    calloc.free(textPtr);
    return nextY;
  }

  /// 10. 구두점 기준 자막 길이 제한 (최대 2문장) -> 마지막 2문장씩 자름
  static String _truncateText(String text) {
    if (text == "...") {
      return text;
    }

    // 구두점 나열 (한국어, 영어, 일본어, 중국어 마침표/물음표/느낌표)
    final RegExp punctuation = RegExp(r'([.?!。？！])');
    final List<RegExpMatch> matches = punctuation.allMatches(text).toList();
    final int count = matches.length;

    // 원본 텍스트
    String textToProcess = text;

    // 구두점 1개 + 이어지는 문장일 때 문장 분할
    if (count == 1 && text.length > matches.last.end) {
      final int splitIndex = matches.first.end;
      textToProcess = text.substring(splitIndex);
    } else if (count >= 2) {
      // 구두점 2개 이상일 때 문장 분할
      final int splitIndex = matches.elementAt(count - 2).end;
      textToProcess = text.substring(splitIndex);
    }

    //'.' 기준 줄 바꿈
    String result = textToProcess.replaceAllMapped(punctuation, (match) {
      return '${match.group(1)}\n';
    });

    // 중복 줄 바꿈, 공백 정리
    result = result.replaceAll(RegExp(r'(\n\s*)+'), '\n');
    result = result.trim();

    return result;
  }
}
