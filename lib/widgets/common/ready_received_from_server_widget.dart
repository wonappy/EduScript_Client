/// [위젯 - 다이얼로그]  서버로부터 "ready"를 수신했을 때 발화를 시작하도록
import 'package:client/providers/mode_provider.dart';
import 'package:client/services/websocket_multiple_speech_service.dart';
import 'package:client/services/websocket_stt_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/enum_core.dart';

class ReadyReceivedFromServer extends StatefulWidget {
  @override
  State<ReadyReceivedFromServer> createState() => _ReadyReceivedFromServerState();
}

class _ReadyReceivedFromServerState extends State<ReadyReceivedFromServer> {
  // 상태 변수
  bool _isReceived = false; // ready 수신 여부
  late dynamic _sttService;


  @override
  void initState() {
    super.initState();
    //_startConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  // [1] 모드에 따른 서비스 할당
  void _initializeService() {

    final mode = Provider.of<ModeProvider>(context, listen: false).currentMode;

    if (mode == Mode.lecture) { // 강의 모드
      _sttService = WebSocketSTTService();
    } else if (mode == Mode.conference) { // 토론 모드
      _sttService = WebSocketMultipleSTTService();
    }
  }

  // [2] 연결 시작
  void _startConnection() {
    _sttService.onStatusUpdate = (status) {
      if (status.contains("ready")) {
        setState(() {
          _isReceived = true;
        });
      }
    };

    _sttService.connectToServer();
  }
}