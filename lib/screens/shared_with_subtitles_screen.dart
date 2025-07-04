//화면 공유 + 자막
//대기 화면
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/enum_core.dart';
import '../core/styles/colors_core.dart';
import '../providers/mode_provider.dart';
import '../services/websocket_stt_service.dart';
import '../services/websocket_multiple_speech_service.dart';
import '../widgets/preview_widget/build_narrow_layout.dart';
import '../widgets/preview_widget/build_wide_layout.dart';
import '../widgets/common/connection_status_bar_widget.dart';

class SharedWithSubtitlesScreen extends StatefulWidget {
  const SharedWithSubtitlesScreen({super.key});

  @override
  State<SharedWithSubtitlesScreen> createState() => _SharedWithSubtitlesScreenState();
}

class _SharedWithSubtitlesScreenState extends State<SharedWithSubtitlesScreen> {

  // 재연결 상태 변수
  ServerConnectionState _serverConnectionState = ServerConnectionState.connected; // 서버 연결 상태
  String _statusMessage = "";               // 연결 상태 메시지 -> UI 화면에 출력
  int _reconnectAttempts = 0;               // 재연결 시도 횟수
  int _maxReconnectAttempts = 3;            // 최대 가능 재시도 횟수
  WebSocketSTTService? _singleService;      // 싱글 서비스 객체

  // 모드에 따른 서비스 할당 (강의 or 회의)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 서비스가 초기화 되지 않은 경우에 실행
    if (_singleService == null) {
      debugPrint("[🔴 DEBUG] 서비스 초기화 시작");
      // 현재 선택된 모드
      final mode = Provider.of<ModeProvider>(context, listen: false).currentMode;
      debugPrint("[🔴 DEBUG] 현재 모드 $mode");

      // 강의 모드
      if (mode == Mode.lecture) {
        _singleService = Provider.of<WebSocketSTTService>(context, listen: false);
        debugPrint("[🔴 DEBUG] 강의 모드 서비스 할당됨 - ${_singleService != null}");
      }
      // 회의 모드
      else {
        _singleService = Provider.of<WebSocketSTTService>(context, listen: false);
      }

      _reconnectionCallbacks(); // (호출) [1] 재연결 콜백 메서드
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // 반응형 레이아웃을 위한 비율 계산
    final bool isWideScreen = screenWidth > screenHeight * 1.5;

    return Scaffold(
      backgroundColor: backgroundcolorOnWord, // 회색 배경
      body: Column(
        children: [
          // [위젯] 연결 상태 표시바
          ConnectionStatusBar(
              serverConnectionState: _serverConnectionState,
              statusMessage: _statusMessage,
              reconnectAttempts: _reconnectAttempts
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.015), // 화면 크기의 1.5%를 패딩으로
              child:
                  isWideScreen //반응형 레이아웃 출력
                      ? BuildWideLayout(
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      )
                      : BuildNarrowLayout(
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 콜백 해제
    _singleService?.onStatusUpdate = null;
    _singleService?.onError = null;
    super.dispose();
  }

  // [1] 재연결 콜백 메서드
  void _reconnectionCallbacks() {
    debugPrint("[🔴 DEBUG] _reconnectionCallbacks 메서드 실행");
    // 콜백 중복 방지
    _singleService?.onStatusUpdate = null;
    _singleService?.onError = null;

    // [1-1] 서버 연결 상태
    _singleService?.onStatusUpdate = (String status) {
      debugPrint("[🔴 DEBUG] UI 상태 업데이트 $status");
      if (!mounted) return;
      // >> UI 동작 (화면 업데이트)
      setState(() {
        debugPrint("[🔴 DEBUG] setState 호출");
        // 1) 재연결 시도
        if (status.contains("재시도")) {
          _serverConnectionState = ServerConnectionState.reconnecting; // 서버 연결 상태 - 재연결 
          _statusMessage = status; // UI에 출력할 상태 메시지

          // (2) 재연결 시도 횟수 파싱
          final match = RegExp(r'재시도 (\d+)/').firstMatch(status);
          if (match != null) {
            _reconnectAttempts = int.parse(match.group(1)!);
          }
        }
        // 2) 연결 성공
        else if (status.contains("연결 성공")) {
          _serverConnectionState = ServerConnectionState.connected; // 서버 연결 상태 - 연결 성공
          _statusMessage = "서버에 연결되었습니다."; // UI에 출력할 상태 메시지
        }
        // 3) 연결 종료
        else if (status.contains("연결 종료")) {
          _serverConnectionState = ServerConnectionState.disconnected; // 서버 연결 상태 - 연결 종료
          _statusMessage = "서버 연결이 끊어졌습니다."; // UI에 출력할 상태 메시지
        }
      });
    };
    
    debugPrint("[🔴 DEBUG] 콜백 등록 완료");
    
    // [1-2] 서버 연결 실패
    _singleService?.onError = (String message, String? errorCode) {
      if (!mounted) return;
      setState(() {
        // 1) 최대 재시도 초과
        if (message.contains("최대 재시도")) {
          _serverConnectionState = ServerConnectionState.failed; // 서버 연결 상태 - 연결 실패
          _statusMessage = "최대 재시도 횟수 초과로 서버 연결에 실패했습니다."; // UI에 출력할 상태 메시지
        }
        // 2) 기타
        else if (message.contains("연결 실패")) {
          _serverConnectionState = ServerConnectionState.disconnected; // 서버 연결 상태 - 연결 끊김 
          _statusMessage = "서버 연결 실패 : $message"; // UI에 출력할 상태 메시지
        }
      });
      _showErrorSnackBar(message); // (호출) [2] 에러 메시지 표시
    };
  }

  // [2] 에러 메시지 표시
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
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