import 'package:client/core/enum_core.dart';
import 'package:client/core/styles/color_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// ### 서버 연결 상태 바
/// - 로딩 스피너 & 상태 메시지 출력
class ConnectionStatusBar extends StatelessWidget {
  final ServerConnectionState serverConnectionState; // 서버 연결 상태
  final String statusMessage; // 서버 연결 상태 메시지
  final int reconnectAttempts; // 재시도 시도 횟수

  const ConnectionStatusBar({
    super.key,
    required this.serverConnectionState,
    required this.statusMessage,
    required this.reconnectAttempts,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("[DEBUG] ConnectionStatusBar 실행 - $serverConnectionState");

    if (serverConnectionState == ServerConnectionState.connected) {
      return const SizedBox.shrink(); // 감추기
    }

    Color backgroundColor; // 배경색
    bool loadingSpinner = false; // 로딩 스피너 출력 여부

    // 서버 연결 상태에 따른 스타일 지정
    switch (serverConnectionState) {
      case ServerConnectionState.reconnecting: // 재연결
        backgroundColor = Colors.amber.shade600;
        loadingSpinner = true;
        break;
      case ServerConnectionState.failed: // 연결 실패
        backgroundColor = Colors.red.shade600;
        break;
      case ServerConnectionState.disconnected: // 연결 끊김
        backgroundColor = Colors.red.shade600;
        break;
      default:
        backgroundColor = Colors.grey; // 디폴트
    }

    debugPrint("[DEBUG]  loadingSpinner - $loadingSpinner");
    debugPrint("[DEBUG] 서버 연결 상태 메시지 - $statusMessage");

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 양쪽 여백
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12), // 둥근 모서리
        boxShadow: [
          // 그림자
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // reconnecting이 아닐 때만 아이콘 표시
          if (serverConnectionState != ServerConnectionState.reconnecting) ...[
            Icon(
              _getStatusIcon(serverConnectionState),
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
          ],
          // 1) 재연결 상태 시 (로딩 스피너 true)
          // 스피너 출력
          if (loadingSpinner) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2, // 스피너 굵기
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ), // 스피너 색상 (애니메이션 없이)
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 2) 상태 메시지 출력
          Expanded(
            child: Text(
              statusMessage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontSize: 14, // 화면 비율에 맞도록 수정
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [아이콘 출력 함수]
  IconData _getStatusIcon(ServerConnectionState state) {
    switch (state) {
      case ServerConnectionState.reconnecting:
        return Icons.sync;
      case ServerConnectionState.failed:
        return Icons.error_outline;
      case ServerConnectionState.disconnected:
        return Icons.wifi_off;
      default:
        return Icons.info_outline;
    }
  }
}
