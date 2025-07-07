// [services/websocket_stt_service.dart]
/// 서버 STT + 번역 (Single Mode) 엔드포인트 연결
library;

import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart'; // 마이크 오디오 녹음
import 'package:permission_handler/permission_handler.dart'; // 마이크 권한 관리

import 'dart:convert'; // JSON 데이터 변환 (인코딩, 디코딩)
import 'dart:typed_data'; // 바이너리 오디오 데이터 처리
import 'dart:async'; // Stream, Timer 등 비동기 처리
import '../core/global_core.dart';
import '../models/config_message_model.dart';
import '../models/status_message_model.dart';
import '../models/speech_translation_response_model.dart';

class WebSocketSTTService {
  // [WebSocket 통신]
  WebSocketChannel? _webSocketChannel; // 실시간 통신 채널
  final String _serverEndpoint = "/api/routes/speech-translation/connect/single-mode";

  // [상태 변수]
  bool _isConnected = false; // 서버 연결 상태
  bool _isSessionReady = false; // 음성 인식 세션 준비 여부

  // [오디오 녹음 관련]
  final AudioRecorder _audioRecorder = AudioRecorder();     // 오디오 캡쳐 객체
  bool _isRecording = false;                                // 현재 녹음 상태
  StreamSubscription<Uint8List>? _audioStreamSubscription;  // 오디오 스트림 구독 관리

  // [현재 설정]
  String? _currentInputLanguage;                            // 현재 입력 언어 (국가)
  List<String>? _currentTargetLanguages;                    // 현재 출력 언어 (국가)

  // [번역 결과 저장]
  final Map<String, String> _currentTranslations = {};      // 현재 번역 결과
  final List<String> _transcriptHistory = [];               // 원문 자막 저장소 -> llm 요약 활용
  final List<Map<String, String>> _translationHistory = []; // 번역 히스토리 (약 3개 정도만 저장)

  // [서버 연결 재시도 처리 관련]
  Timer? _reconnectTimer;                               // 재시도 타이머
  int _reconnectAttempts = 0;                           // 재시도 횟수
  final int _maxReconnectAttempts = 3;                  // 최대 재시도 가능 횟수 (무한 재시도 방지)
  final List<int> _reconnectDelays = [2, 6, 10];         // 대기 시간 증가
  bool _shouldAutoReconnect = true;                     // 재연결 기능 on/off
  bool _wasRecordingBeforeDisconnect = false;           // 연결 끊어지기 전 상태

  // [콜백 함수]
  Function(Map<String, TranslationResult>)? onTranslationReceived; // 번역 결과 콜백
  Function(String)? onStatusUpdate; // 상태 변경 콜백
  Function(String, String?)? onError; // 에러 콜백

  // [싱글톤 패턴]
  static final WebSocketSTTService _instance = WebSocketSTTService._internal();
  factory WebSocketSTTService() => _instance;
  WebSocketSTTService._internal();

  // [Getter] 현재 상태 확인
  bool get isConnected => _isConnected;
  bool get isSessionReady => _isSessionReady;
  bool get isRecording => _isRecording;
  String? get currentInputLanguage => _currentInputLanguage;
  List<String>? get currentTargetLanguages => _currentTargetLanguages;

  // [Getter] 번역 결과 접근
  Map<String, String> get currentTranslations =>
      Map.unmodifiable(_currentTranslations);
  List<String> get transcriptHistory => List.unmodifiable(_transcriptHistory);
  List<Map<String, String>> get translationHistory =>
      List.unmodifiable(_translationHistory);

  // 전체 원문 텍스트 (하나의 문자열로) -> LLM 활용
  String get fullTranscriptText => _transcriptHistory.join(' ');

  // [1] WebSocket 서버 연결 (상태 응답 - StatusMessage)
  Future<bool> connectToServer({bool isRetry = false}) async {
    debugPrint("[DEBUG 1] connectToServer 메서드 실행 (웹소켓 연결)");
    try {
      // 1) 최초 연결 시
      if (!isRetry) {
        _updateStatus("[DEBUG 1] 웹소켓 서버 연결 시도");
        _reconnectAttempts = 0; // 연결 시도 횟수 - 최초 연결 시에만 리셋
      } else { // 재시도 시
        _updateStatus("[DEBUG 1] 서버 연결 재시도 ${_reconnectAttempts}/${_maxReconnectAttempts}");
      }

      // 2) 서버에 WebSocket 연결 시도
      final uri = Uri.parse('$serverBaseUrl$_serverEndpoint'); // 서버 엔드포인트
      _webSocketChannel = WebSocketChannel.connect(uri); // WebSocket 연결

      // 3) 서버 연결 완료 확인 - Completer
      final Completer<bool> connectionCompleter = Completer<bool>();

      // 4) 서버 메시지 수신 리스너
      _webSocketChannel!.stream.listen(
        (message) {
          // 4-1) 첫 번째 메시지 수신 시
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(true); // 연결 성공
          }
          // 4-2) 그 외 메시지 처리
          _handleServerMessage(message);
        },
        onError: (error) {
          // 4-3) 웹소켓 연결 오류 시
          _handleError("[ERROR 1] WebSocket 연결 오류", error.toString());
          _isConnected = false;
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(false);
          }
        },
        onDone: () {
          // 4-4) 연결이 종료되었을 때 처리
          _handleConnectionClosed();
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(false); // 연결 실패로 완료
          }
        },
      );

      // 5) 타임아웃 예외 처리
      try {
        // 10초 내 실제 연결 성공 여부 확인
        final result = await connectionCompleter.future.timeout(
          Duration(seconds: 10),
          onTimeout: () {
            // 3초 내에 응답 없을 시, 타임아웃
            _handleError("[ERROR 1] 서버 연결 타임아웃", "Connection Timeout");
            return false;
          },
        );

        // 5-1) 10초 내 서버 연결 성공 시
        if (result) {
          _isConnected = true;
          _updateStatus("[DEBUG 1] 서버 연결 성공 ~!@");
          return true;
        } else {
          _isConnected = false;
          return false;
        }
      } catch (e) {
        _isConnected = false;
        return false;
      }
    } catch (e) {
      _handleError("[ERROR 1] 서버 연결 실패", e.toString());
      _isConnected = false;
      return false;
    }
  }

  // [2] 음성 인식 세션 시작 (언어 설정 - ConfigMessage)
  Future<bool> startSession({
    required String inputLanguage,          // (매개변수1) 입력 언어 국가 설정
    required List<String> targetLanguages,  // (매개변수2) 출력 언어 국가 설정
  }) async {
    debugPrint("[DEBUG 2] startSession 메서드 실행 (세션 시작)");
    // 0) 서버 연결 상태 확인
    if (!_isConnected || _webSocketChannel == null) { // 연결 상태 false || 웹소캣 객체 == null
      _handleError("[ERROR 2] 세션 시작 실패", "서버가 연결되지 않았습니다");
      return false;
    }

    try {
      // 1) 마이크 권한 확인
      if (!await _checkMicrophonePermission()) {
        _handleError("[ERROR 2] 세션 시작 실패", "마이크 권한이 필요합니다");
        return false;
      }

      // 2) 설정 메시지 생성
      final configMessage = ConfigMessage(
        inputLanguage: inputLanguage, // 입력 언어 국가
        targetLanguages: targetLanguages, // 출력 언어 국가
      );

      // JSON 매핑 -> 전송
      _webSocketChannel!.sink.add(jsonEncode(configMessage.toJson()));

      // 현재 상태 업데이트
      _currentInputLanguage = inputLanguage;
      _currentTargetLanguages = targetLanguages;

      // 자막 데이터 초기화
      _clearTranslationData(); // (호출) +) 번역 데이터 초기화

      _updateStatus("[DEBUG 2] 세션 설정 전송 완료, 서버 응답 대기 중...");
      _shouldAutoReconnect = true;// 세션 시작 시 자동 재연결 활성화
      return true;
    } catch (e) {
      _handleError("[ERROR 2] 세션 시작 실패", e.toString());
      return false;
    }
  }

  // [3] 음성 녹음 시작
  Future<bool> startRecording() async {
    debugPrint("[DEBUG 3] startRecording() 메서드 실행"); // 디버깅
    // 세션 상태 체크
    if (!_isSessionReady) {
      _handleError("녹음 시작 실패", "세션이 준비되지 않았습니다");
      return false;
    }

    // 중복 녹음 방지 (마이크 리소스 하나만 사용)
    if (_isRecording) {
      _updateStatus("이미 녹음 중입니다");
      return true;
    }

    try {
      // 1) 오디오 스트림 설정
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits, // PCM 16bit 포맷
          sampleRate: 16000, // 16kHz 샘플레이트
          numChannels: 1, // 모노 채널
        ),
      );

      // 2) 오디오 데이터를 서버로 실시간 전송
      _audioStreamSubscription = stream.listen(
        // 오디오가 들어올 때 콜백
        (audioData) {
          // 바이너리 음성 데이터
          if (_isConnected && _webSocketChannel != null) {
            _webSocketChannel!.sink.add(audioData); // 음성 데이터를 실시간으로 전송
          }
        },
        onError: (error) {
          _handleError("오디오 스트림 오류", error.toString());
        },
      );

      // 3) 상태 업데이트
      _isRecording = true;
      _updateStatus("🎤 음성 녹음 시작");
      return true;
    } catch (e) {
      _handleError("녹음 시작 실패", e.toString());
      return false;
    }
  }

  // [4-1] 음성 녹음 중지
  Future<void> stopRecording() async {
    debugPrint("[DEBUG 4-1] stopRecording() 메서드 (녹음 중지)"); // 디버깅
    if (!_isRecording) return;

    debugPrint("🔍 녹음 중지 전 데이터: ${_transcriptHistory.length}개");
    debugPrint("🔍 전체 텍스트: $fullTranscriptText");

    try {
      await _audioStreamSubscription?.cancel();
      await _audioRecorder.stop();

      _audioStreamSubscription = null;
      _isRecording = false;

      debugPrint("🔍 녹음 중지 후 데이터: ${_transcriptHistory.length}개");
      _updateStatus(">> [4] 음성 녹음 중지");
    } catch (e) {
      _handleError("- 녹음 중지 실패", e.toString());
    }
  }

  // [4-2] 녹음 중지 후 재개
  Future<void> resumeRecording() async {
    debugPrint("[DEBUG 4-2] resumeRecording() 메서드 실행 (녹음 중지 후 재개)"); // 디버깅
    if (_isRecording || !_isConnected) return;

    debugPrint("- 재시작 : 기존 데이터 연결됨");
    await startRecording(); // (호출) [3] 음성 녹음 시작
  }

  // [5] 언어 설정 변경 (세션 중에)
  Future<bool> changeLanguageSettings({
    String? newInputLanguage, // 새 입력 언어 국가
    List<String>? newTargetLanguages, // 새 출력 언어 국가 List
  }) async {
    debugPrint("[DEBUG 5] changeLanguageSettings 메서드 실행 (세션 중 언어 설정 변경)");
    if (!_isConnected || _webSocketChannel == null) {
      _handleError("[ERROR 5] 언어 설정 변경 실패", "서버가 연결되지 않았습니다");
      return false;
    }

    try {
      final configMessage = ConfigMessage(
        inputLanguage: newInputLanguage ?? _currentInputLanguage!,
        targetLanguages: newTargetLanguages ?? _currentTargetLanguages!,
      );

      _webSocketChannel!.sink.add(jsonEncode(configMessage.toJson()));

      if (newInputLanguage != null) _currentInputLanguage = newInputLanguage;

      if (newTargetLanguages != null) {
        _currentTargetLanguages = newTargetLanguages;
      }

      _updateStatus("[DEBUG 5] 언어 설정 변경 요청 전송");
      return true;
    } catch (e) {
      _handleError("[ERROR 5] 언어 설정 변경 실패", e.toString());
      return false;
    }
  }

  // [6] 서버 연결 재시도 처리 관련
  // [6-1] 연결 끊어졌을 때 처리
  // -> 상태 업데이트, 녹음 상태 저장, 재연결 스케줄링
  void _handleConnectionClosed() {
    debugPrint("[DEBUG 6] _handleConnectionClosed 메서드 실행 (재연결)");

    _isConnected = false;                         // 세션 연결 종료
    _isSessionReady = false;                      // 세션 준비 상태 종료
    _wasRecordingBeforeDisconnect = _isRecording; // 끊어지기 전 상태 저장 (녹음 중이었는지)

    if (_shouldAutoReconnect && _reconnectAttempts < _maxReconnectAttempts) { // 자동 재연결, 재시도 횟수 < 3
      //_shouldAutoReconnect = false; // 중복 재연결 방지
      _scheduleReconnect(); // (호출) 2) 재연결 예약
    } else { // 횟수 초과로 재연결 중단
      _shouldAutoReconnect = false; // 중복 재연결 방지
      _updateStatus("[DEBUG 6] 서버 연결 종료됨");
    }
  }

  // [6-2] 재연결 예약
  void _scheduleReconnect() {
    final delay = _reconnectDelays[_reconnectAttempts.clamp(0, _reconnectDelays.length-1)]; // clamp(최소,최댓값)
    _updateStatus("[DEBUG 6] ${delay}초 후 재연결 시도"); // 1, 3, 5초

    _reconnectTimer = Timer(Duration(seconds: delay), _attemptReconnect); // (호출) 3) 재연결 시도
  }

  // [6-3] 재연결 시도
  Future<void> _attemptReconnect() async {
    debugPrint("[🐟 DEBUG] _attemptReconnect 실행 - 현재 : $_reconnectAttempts");
    _reconnectAttempts++; // 재연결 시도 횟수 증가
    debugPrint("[🐟 DEBUG] _attemptReconnect 실행 - 증가 후 : $_reconnectAttempts");
    _updateStatus("[DEBUG 1] 서버 연결 재시도 ${_reconnectAttempts}/${_maxReconnectAttempts}");
    final success = await connectToServer(isRetry: true); // (호출) [1] WebSocket 서버 연결 - 재연결 시도 !!!

    // 1) 재연결 성공
    if (success && _currentInputLanguage != null) { // 재연결 성공 && 입력 언어 국가 not null
      //_shouldAutoReconnect = true;
      _stopReconnectTimer(); // 타이머 중지
      _reconnectAttempts = 0; // 재시도 카운트 리셋

      await startSession( // (호출) [2] 음성 인식 세션
        inputLanguage: _currentInputLanguage!, // 입력 언어 국가
        targetLanguages: _currentTargetLanguages!, // 출력 언어 국가
      );

      if (_wasRecordingBeforeDisconnect) { // 이전에 녹음 중이었다면 재개
        await resumeRecording();
      }
    } else {
      // 2) 재연결 실패
      if (_reconnectAttempts >= _maxReconnectAttempts) { // 최대 재시도 초과 시
        _stopReconnectTimer();   // 타이머 중지
        _shouldAutoReconnect = false; // 자동 재연결 끄기
        _handleError("[ERROR 6] 실패", "최대 재시도 횟수 초과");
      } else { // 재시도 횟수 남으면 다시 시도
        _scheduleReconnect(); // (호출) 2) 재연결 시도
      }
    }
  }

  // [6-4] 재연결 타이머 중지
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();  // 타이머 객체 취소
    _reconnectTimer = null;     // 타이머 객체 삭제
  }

  // [7] 연결 종료
  Future<void> disconnect() async {
    debugPrint("[DEBUG 7] disconnect 메서드 실행 (연결 종료)");
    try {
      // 1) 재연결 중지
      _shouldAutoReconnect = false; // 수동 종료 시 자동 재연결 비활성화
      _stopReconnectTimer();        // 재연결 타이머 중지
      // 2) 녹음 중지
      await stopRecording();
      // 3) WebSocket 연결 종료
      await _webSocketChannel?.sink.close();
      _webSocketChannel = null;

      _isConnected = false;     // 세션 연결 종료
      _isSessionReady = false;  // 세션 준비 상태 종료

      _updateStatus("[DEBUG 7] 연결 종료 완료");
    } catch (e) {
      _handleError("[ERROR 7] 연결 종료 중 오류", e.toString());
    }
  }

  // [헬퍼 함수]
  // +) 번역 데이터 초기화
  void _clearTranslationData() {
    _currentTranslations.clear();
    _transcriptHistory.clear();
    _translationHistory.clear();
    debugPrint("[DEBUG] 번역 데이터 초기화");
  }

  // +) 번역 데이터 수동 초기화 (외부 호출 용)
  void clearAllData() {
    _clearTranslationData(); // (호출) +) 번역 데이터 초기화
  }

  // 1) 서버 메시지 처리
  void _handleServerMessage(dynamic message) {
    try {
      Map<String, dynamic> data;

      // 메시지 타입 확인 (String 또는 이미 파싱된 Map)
      if (message is String) {
        data = jsonDecode(message);
      } else if (message is Map<String, dynamic>) {
        data = message;
      } else {
        debugPrint("[DEBUG] 알 수 없는 메시지 형식: ${message.runtimeType}");
        return;
      }

      final messageType = data['type'] ?? '';

      switch (messageType) {
        case 'status':
          _handleStatusMessage(StatusMessage.fromJson(data));
          break;
        case 'result':
          _handleTranslationResult(SpeechTranslationResponse.fromJson(data));
          break;
        default:
          debugPrint("알 수 없는 메시지 타입: $messageType");
      }
    } catch (e) {
      _handleError("메시지 처리 오류", e.toString());
    }
  }

  // 2) 상태 메시지 처리 (StatusMessage)
  void _handleStatusMessage(StatusMessage statusMsg) {
    switch (statusMsg.status) {
      case 'ready':
        _isSessionReady = true;
        _updateStatus("✅ ${statusMsg.message ?? '세션 준비 완료'}");

        startRecording(); // 녹음 시작
        break;
      case 'error':
        _isSessionReady = false;
        _handleError(statusMsg.message ?? '서버 오류', statusMsg.errorCode);
        break;
      case 'warning':
        _updateStatus("⚠️ ${statusMsg.message ?? '경고'}");
        break;
      case 'disconnected':
        _isConnected = false;
        _isSessionReady = false;
        _updateStatus("🔌 ${statusMsg.message ?? '연결 종료'}");
        break;
      default:
        _updateStatus("📢 ${statusMsg.message ?? statusMsg.status}");
    }
  }

  // 3) 마이크 권한 확인
  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  // 4) 번역 결과 처리 (SpeechTranslationResponse) (콜백)
  void _handleTranslationResult(SpeechTranslationResponse response) {
    if (response.translations.isNotEmpty) {
      // 1) 현재 번역 결과 업데이트
      _currentTranslations.clear(); //현재 번역 초기화
      String? originalText;

      debugPrint("=== 번역 결과 ===");
      response.translations.forEach((lang, result) {
        _currentTranslations[lang] = result.resultText;

        //번역 결과 로그 출력 포함
        debugPrint("$lang: ${result.resultText}");

        // 입력 언어의 텍스트를 원문으로 저장
        if (lang == _currentInputLanguage) {
          originalText = result.resultText;
        }
      });

      // 2) 원문 자막 저장소에 추가
      if (originalText != null && originalText!.isNotEmpty) {
        _transcriptHistory.add(originalText!);
      }

      // 3) 번역 저장소에 추가
      if (_currentTranslations.isNotEmpty) {
        _translationHistory.add(Map.from(_currentTranslations));
      }

      // 4) 콜백 호출
      onTranslationReceived?.call(response.translations);

      // 5) 원문 저장 상태 로그 출력
      if (originalText != null) {
        debugPrint("[DEBUG] 원문 저장: $originalText");
        debugPrint("[DEBUG] 총 원문 개수: ${_transcriptHistory.length}");
      }
    }
  }

  // 5) 상태 업데이트 헬퍼 (콜백)
  void _updateStatus(String status) {
    debugPrint("Status: $status");
    onStatusUpdate?.call(status); // 콜백
  }

  // 6) 에러 처리 헬퍼 (콜백)
  void _handleError(String message, String? errorCode) {
    debugPrint("Error: $message ${errorCode != null ? '($errorCode)' : ''}");
    onError?.call(message, errorCode); // 콜백
  }

  // [리소스 정리]
  void dispose() {
    disconnect();
  }
}
