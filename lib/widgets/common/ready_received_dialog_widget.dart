/// [위젯 - 다이얼로그]  서버로부터 "ready"를 수신했을 때 발화를 시작하도록
library;

import 'dart:io';
import 'package:provider/provider.dart';
import 'package:client/core/styles/color_core.dart';
import 'package:client/providers/mode_provider.dart';
import 'package:client/services/websocket_multiple_speech_service.dart';
import 'package:client/services/websocket_stt_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/enum_core.dart';

class ReadyReceivedDialog extends StatefulWidget {
  // [콜백 등록] ready 수신 -> 외부에 알림
  final VoidCallback onReadyConfirmed;
  const ReadyReceivedDialog({super.key, required this.onReadyConfirmed});

  @override
  State<ReadyReceivedDialog> createState() =>
      _ReadyReceivedDialogState();
}

class _ReadyReceivedDialogState extends State<ReadyReceivedDialog> {
  // [상태 변수]
  bool _isReadyReceived = false; // ready 수신 여부
  late dynamic _sttService; // STT 서비스 인스턴스

  @override
  void initState() {
    super.initState();

    // (호출) [1] 서비스 초기화 + 콜백
    // 위젯 트리에 삽입될 때 (위젯이 생성될 때) 딱 한번 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0, // 다이얼로그 그림자 제거

      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24), // 내부 여백
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(
            maxWidth: 300, // 다이얼로그 최대 너비
            minHeight: 100, // 최소 높이
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1) 상태 아이콘
              _isReadyReceived
                  ? // ready 수신 O
              const Icon(
                Icons.task_alt, // 🔴 체크 표시 아이콘
                color: AppColors.greenColor,
                size: 48,
              )
                  : // ready 수신 X
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3, // 🔴 스피너 굵기
              ),
              const SizedBox(height: 16),

              // 2) 상태 멘트
              Text(
                _isReadyReceived
                    ? "준비 완료. 발화를 시작하세요!" // ready 수신 O
                    : "준비 중입니다. 잠시만 기다려주세요...", // ready 수신 X
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 다이얼로그 닫힐 때 콜백 해제
    if (_sttService != null) {
      _sttService.onStatusUpdate = null;
    }
    super.dispose();
  }

  // [1] 서비스 초기화 + 콜백
  void _initializeServices() {
    // 1) 모드에 따른 서비스 할당
    final mode = Provider.of<ModeProvider>(context, listen: false).currentMode;
    if (mode == Mode.lecture) {
      // 강의 모드
      _sttService = Provider.of<WebSocketSTTService>(context, listen: false);
    } else if (mode == Mode.conference) {
      // 토론 모드
      _sttService = Provider.of<WebSocketMultipleSTTService>(
        context,
        listen: false,
      );
    }
    debugPrint("[🍒 DEBUG 1] 서비스 할당 완료.");

    // 2) onStatusUpdate 콜백 등록
    // 서비스가 변경될 때마다 다시 등록됨
    _sttService.onStatusUpdate = (status) {
      debugPrint("[🍒 DEBUG 1] status 수신 - $status");

      // "ready" 수신 확인
      if (status.contains("ready") || status.contains("준비 완료")) {
        if (!_isReadyReceived) {
          setState(() {
            // ready 수신 상태 O
            _isReadyReceived = true;
          });

          // (호출) [2] ready 수신 후 처리
          // UI 변경 및 다이얼로그 닫기
          _onReadyReceived();
        }
      }
    };

    //  3)서비스의 isSessionReady가 이미 true일 때
    if (_sttService.isSessionReady) {
      debugPrint("[🍒 DEBUG 1] 서비스가 이미 ready 상태입니당.");
      if (!_isReadyReceived) {
        setState(() {
          _isReadyReceived = true;
        });
        _onReadyReceived();
      }
    }
  }

  // [2] ready 수신 후 처리
  void _onReadyReceived() {
    debugPrint("[🍒 DEBUG 2] ready 수신 완료");
    // ready 상태 확인 후, 콜백 호출
    widget.onReadyConfirmed();

    // 다이얼로그 닫기 (🔴 UI 수정)
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
