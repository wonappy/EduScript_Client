//오버레이 자막 창
import 'dart:io' show Platform;
import 'package:client/core/styles/color_core.dart';
import 'package:client/services/windows_overlay_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/enum_core.dart';
import '../providers/mode_provider.dart';
import '../services/websocket_multiple_speech_service.dart';
import '../services/websocket_stt_service.dart';
import '../widgets/preview_widget/subtitle_setting_provider.dart';
import '../widgets/common/connection_status_bar_widget.dart';

class SharedWithSubtitlesScreen extends StatefulWidget {
  const SharedWithSubtitlesScreen({super.key});

  @override
  State<SharedWithSubtitlesScreen> createState() =>
      _SharedWithSubtitlesScreenState();
}

class _SharedWithSubtitlesScreenState extends State<SharedWithSubtitlesScreen> {
  // --- 기존 연결 상태 변수 ---
  ServerConnectionState _serverConnectionState =
      ServerConnectionState.connected;
  String _statusMessage = "";
  int _reconnectAttempts = 0;

  // --- STT 서비스 및 자막 데이터 변수 (SubtitlesOnlyScreen에서 가져옴) ---
  dynamic _sttService;
  Map<String, String> _confirmedTranslations = {};
  Map<String, String> _currentTranslations = {};
  String? _currentSpeakingLanguage;

  // Win32 오버레이 매니저
  WindowsOverlayManager? _overlayManager;

  @override
  void initState() {
    super.initState();

    //새 세션 시작 시 이전 세션 데이터 삭제
    WindowsOverlayManager.clearStaticData();

    // Win32 매니저 초기화 (Windows일 때만!)
    if (Platform.isWindows) {
      _overlayManager = WindowsOverlayManager();
      _overlayManager!.initialize();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 서비스가 초기화 되지 않은 경우에만 실행
    if (_sttService == null) {
      debugPrint("[DEBUG] 서비스 초기화 시작");
      final mode =
          Provider.of<ModeProvider>(context, listen: false).currentMode;
      debugPrint("[DEBUG] 현재 모드 $mode");

      if (mode == Mode.lecture) {
        _sttService = Provider.of<WebSocketSTTService>(context, listen: false);
      } else {
        _sttService = Provider.of<WebSocketMultipleSTTService>(
          context,
          listen: false,
        );
      }

      _setupCallbacks(); // [1] 콜백 메서드
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI는 최소한의 제어판 역할만 수행
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: Stack(
        children: [
          // 1) 연결 상태 표시줄
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              child: ConnectionStatusBar(
                serverConnectionState: _serverConnectionState,
                statusMessage: _statusMessage,
                reconnectAttempts: _reconnectAttempts,
              ),
            ),
          ),

          // 2) 중앙 제어 버튼
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.screen_share_outlined,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  "화면 공유 자막이 활성화되었습니다.",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 32),
                // [자막 중지 버튼]
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text("자막 중지"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    debugPrint("[화면 공유 모드] 자막 중지 버튼 클릭");

                    // 1) 자막 중지 버튼 클릭 후, 녹음 일시 정지
                    if (_sttService != null) {
                      await _sttService.stopRecording();
                      debugPrint("[화면 공유 모드] 자막 중지 버튼 클릭 후, 녹음 일시 정지");
                    }

                    // 2) 이전 화면으로 전환 (녹음 일시 정지가 완료되면)
                    // 화면 전환 + 상태 변화 전달
                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Win32 오버레이 윈도우 제거
    _overlayManager?.dispose();

    // 콜백 해제
    _sttService?.onTranslationReceived = null;
    _sttService?.onStatusUpdate = null;
    _sttService?.onError = null;
    super.dispose();
  }

  /// [콜백 설정] STT 서비스로부터 데이터를 받아 매니저에 전달
  void _setupCallbacks() {
    debugPrint("[DEBUG] _setupCallbacks 메서드 실행");

    // 콜백 중복 방지
    _sttService?.onTranslationReceived = null;
    _sttService?.onStatusUpdate = null;
    _sttService?.onError = null;

    // 번역(자막) 결과 콜백
    if (_sttService is WebSocketMultipleSTTService) {
      // multi 모드
      _sttService.onTranslationReceived = (
        translations,
        isFinal,
        speackLanguage,
      ) {
        debugPrint("✅ [SharedScreen] Multi STT 콜백! isFinal: $isFinal");

        _currentSpeakingLanguage = speackLanguage;
        if (isFinal) {
          _confirmedTranslations = Map.from(_currentTranslations);
          _currentTranslations.clear();
        } else {
          _currentTranslations.clear();
          translations.forEach((lang, result) {
            _currentTranslations[lang] = result.resultText;
          });
        }

        // Win32 매니저에 데이터 전송
        _updateOverlay();
      };
    } else {
      // single 모드
      _sttService.onTranslationReceived = (translations, isFinal) {
        debugPrint("✅ [SharedScreen] Single STT 콜백! isFinal: $isFinal");

        // setState가 아니라, 상태 변수만 직접 업데이트
        if (isFinal) {
          _confirmedTranslations = Map.from(_currentTranslations);
          _currentTranslations.clear();
        } else {
          _currentTranslations.clear();
          translations.forEach((lang, result) {
            _currentTranslations[lang] = result.resultText;
          });
        }

        // Win32 매니저에 데이터 전송
        _updateOverlay();
      };
    }

    // 2) 재연결 콜백 (기존 코드)
    _reconnectionCallbacks();
  }

  /// Win32 매니저를 업데이트하는 함수
  void _updateOverlay() {
    if (_overlayManager == null) return; // Windows가 아니거나 초기화 전이면 중단

    // Win32 매니저에 필요한 모든 최신 데이터를 전달
    final settings = context.read<SubtitleSettingsProvider>();
    final screenSize = MediaQuery.of(context).size;

    _overlayManager!.update(
      languages: settings.selectedOutputLanguages,
      currentTranslations: _currentTranslations,
      confirmedTranslations: _confirmedTranslations,
      settings: settings,
      screenSize: screenSize,
      currentSpeakingLanguage: _currentSpeakingLanguage,
    );
  }

  // [1] 재연결 콜백 메서드
  void _reconnectionCallbacks() {
    debugPrint("[DEBUG] _reconnectionCallbacks 메서드 실행");

    // [1-1] 서버 연결 상태
    _sttService?.onStatusUpdate = (String status) {
      debugPrint("[DEBUG] UI 상태 업데이트 $status");
      if (!mounted) return;
      setState(() {
        debugPrint("[DEBUG] setState 호출");
        if (status.contains("재시도")) {
          _serverConnectionState = ServerConnectionState.reconnecting;
          _statusMessage = status;
          final match = RegExp(r'재시도 (\d+)/').firstMatch(status);
          if (match != null) {
            _reconnectAttempts = int.parse(match.group(1)!);
          }
        } else if (status.contains("연결 성공")) {
          _serverConnectionState = ServerConnectionState.connected;
          _statusMessage = "서버에 연결되었습니다.";
        } else if (status.contains("연결 종료")) {
          _serverConnectionState = ServerConnectionState.disconnected;
          _statusMessage = "서버 연결이 끊어졌습니다.";
        }
      });
    };

    debugPrint("[DEBUG] 콜백 등록 완료");

    // [1-2] 서버 연결 실패
    _sttService?.onError = (String message, String? errorCode) {
      if (!mounted) return;
      setState(() {
        if (message.contains("최대 재시도")) {
          _serverConnectionState = ServerConnectionState.failed;
          _statusMessage = "최대 재시도 횟수 초과로 서버 연결에 실패했습니다.";
        } else if (message.contains("연결 실패")) {
          _serverConnectionState = ServerConnectionState.disconnected;
          _statusMessage = "서버 연결 실패 : $message";
        }
      });
      _showErrorSnackBar(message);
    };
  }

  // [2] 에러 메시지 표시
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
