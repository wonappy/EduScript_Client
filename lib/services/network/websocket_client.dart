//websocket_client.dart
//클라이언트 웹소켓 연결 상태 관리 ( 연결 시도, 종료 등 )

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/global_core.dart';

class WebsocketClient {
  // [통신 변수]
  WebSocketChannel? _channel; // 실시간 통신 채널
  final String _serverEndpoint =
      "/api/routes/speech-translation/connect/single-mode";

  // [연결 상태 변수]
  bool _isConnected = false; // 서버 연결 상태

  // [재연결 변수]
  bool _shouldAutoReconnect = true; // 재연결 기능 on/off
  bool _isReconnecting = false; // 재연결 시도 상태 확인
  Timer? _reconnectTimer; // 재시도 타이머
  int _reconnectAttempts = 0; // 재시도 횟수
  final int _maxReconnectAttempts = 3; // 최대 재시도 가능 횟수
  final List<int> _reconnectDelays = [2, 6, 10]; // 대기 시간 증가

  // [이벤트 콜백]
  Function(dynamic)? onMessage; // 메시지 도착
  Function(dynamic)? onError; // 에러 발생
  Function()? onDisconnected; // 연결 끊어짐
  Function()? onReconnected; // 재연결 성공 -> 세션 복구 요청

  // [Getter]
  bool get isConnected => _isConnected; // 서버 연결 상태

  // [싱글톤 패턴]
  static final WebsocketClient _instance = WebsocketClient._internal();
  factory WebsocketClient() => _instance;
  WebsocketClient._internal();

  // 서버 연결 시도
  Future<bool> connect({bool isRetry = false}) async {
    // 기존 연결 정리
    if (_channel != null) {
      try {
        // 1) 기존 연결 채널에 "연결 종료" 신호
        _channel!.sink.close().timeout(const Duration(seconds: 2));
      } catch (e) {
        // 2) 이미 닫힌 채널 또 닫지 않도록
        debugPrint(" 이전 웹소켓 연결 정리 중 오류 발생 (무시 가능) - $e");
      }
      _channel = null; // 연결 변수 삭제
    }

    try {
      // 변수 초기화
      if (!isRetry) {
        _shouldAutoReconnect = true; // 자동 재연결 활성화
        _reconnectAttempts = 0; // 연결 시도 횟수 초기화
        _isReconnecting = false;
      } else {
        // 재연결 시 초기화 x
        debugPrint(
          "[DEBUG] 서버 연결 재시도 $_reconnectAttempts/$_maxReconnectAttempts",
        );
      }

      // 서버 연결 시도
      final uri = Uri.parse(
        '${GlobalCore.serverBaseUrl.trim()}$_serverEndpoint',
      ); // 서버 엔드포인트
      debugPrint("[DEBUG] WebsocketClient 연결 시도 : $uri");
      _channel = WebSocketChannel.connect(uri); // 웹소켓 연결
      // ready 수신 까지 10초 개시
      await _channel!.ready.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("WebSocket 연결 타임아웃", Duration(seconds: 10));
        },
      );

      _isConnected = true; // 연결 상태 갱신
      _listenToStream(); // 리스너 부착

      return true;
    } catch (e) {
      _isConnected = false; // 연결 상태 갱신
      if (!isRetry) {
        // "재시도"가 아닐 때만 에러를 보고하도록
        debugPrint("[ERROR] 서버 연결 실패 : $e");
        onError?.call(e);
      }
      return false;
    }
  }

  // 데이터 전송 (언어 설정, 음성 데이터 등)
  void send(dynamic data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(data);
    }
  }

  // 연결 종료
  Future<void> disconnect() async {
    // 재연결 중지
    _shouldAutoReconnect = false; // 수동 종료 시 자동 재연결 비활성화
    _stopReconnectTimer(); // 재연결 타이머 중지

    // 웹소켓 연결 종료
    if (_channel != null) {
      await _channel?.sink.close();
      _channel = null;
    }

    _isConnected = false; // 세션 연결 종료
  }

  // 서버 메시지 수신 리스너
  void _listenToStream() {
    _channel!.stream.listen(
      (message) => onMessage?.call(message),
      onError: (error) {
        //에러 처리
        _handleConnectionLoss();
        onError?.call(error); // 에러 콜백
      },
      onDone: () {
        //연결 종료 처리
        _handleConnectionLoss();
      },
    );
  }

  // 연결 중지 처리 + 재연결 시도
  void _handleConnectionLoss() {
    if (!_isConnected) return; // 이미 처리됨
    _isConnected = false;
    onDisconnected?.call(); // 서비스에게 "끊겼다!" 알림

    // 재연결 기능 on일 시,
    if (_shouldAutoReconnect) {
      _scheduleReconnect();
    }
  }

  // 재연결 예약
  void _scheduleReconnect() {
    if (_isReconnecting || !_shouldAutoReconnect) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint("[DEBUG] 재연결 실패: 최대 횟수 초과");
      _shouldAutoReconnect = false;
      return;
    }

    _isReconnecting = true;

    final delay =
        _reconnectDelays[_reconnectAttempts.clamp(
          0,
          _reconnectDelays.length - 1,
        )]; // clamp(최소,최댓값)
    debugPrint("[DEBUG] $delay초 후 재연결 시도"); // 2, 6, 10초

    // 2초 뒤에 재연결 시도 시작
    _reconnectTimer = Timer(Duration(seconds: delay), _attemptReconnect);
  }

  // 재연결 시도
  Future<void> _attemptReconnect() async {
    _reconnectAttempts++; // 재연결 시도 횟수 증가
    debugPrint("[DEBUG]서버 연결 재시도 ($_reconnectAttempts/$_maxReconnectAttempts)");

    // 재연결 시도
    final success = await connect(isRetry: true);
    _isReconnecting = false;

    if (success) {
      //성공할 시
      _stopReconnectTimer(); // 타이머 중지
      _reconnectAttempts = 0; // 재시도 카운트 리셋 = 0
      onReconnected?.call(); // 재연결 콜백 호출
    } else {
      _scheduleReconnect(); // 재연결 예약
    }
  }

  // 재연결 타이머 중지
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel(); // 타이머 객체 취소
    _reconnectTimer = null; // 타이머 객체 삭제
    _isReconnecting = false;
  }
}
