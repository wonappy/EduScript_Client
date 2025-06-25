// [services/websocket_stt_service.dart]
/// 서버 STT + 번역 엔드포인트 연결
library;

import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart'; // 마이크 오디오 녹음
import 'package:permission_handler/permission_handler.dart'; // 마이크 권한 관리

import 'dart:convert'; // JSON 데이터 변환 (인코딩, 디코딩)
import 'dart:typed_data'; // 바이너리 오디오 데이터 처리
import 'dart:async'; // Stream, Timer 등 비동기 처리
import '../models/config_message_model.dart';
import '../models/status_message_model.dart';
import '../models/speech_translation_response_model.dart';

class WebSocketSTTService {
  // [WebSocket 통신]
  WebSocketChannel? _webSocketChannel; // 실시간 통신 채널
  final String _serverBaseUrl = "ws://10.101.71.246:8000"; // 서버 엔드포인트
  final String _serverEndpoint = "/api/routes/speech-translation/connect";

  // [상태 변수]
  bool _isConnected = false; // 서버 연결 상태
  bool _isSessionReady = false; // 음성 인식 세션 준비 여부

  // [오디오 녹음 관련]
  final AudioRecorder _audioRecorder = AudioRecorder(); // 오디오 캡쳐 객체
  bool _isRecording = false; // 현재 녹음 상태
  StreamSubscription<Uint8List>? _audioStreamSubscription; // 오디오 스트림 구독 관리

  // [현재 설정]
  String? _currentInputLanguage; // 현재 입력 언어 (국가)
  List<String>? _currentTargetLanguages; // 현재 타켓 언어 (국가)

  //[번역 결과 저장]
  final Map<String, String> _currentTranslations = {}; // 현재 번역 결과
  final List<String> _transcriptHistory = []; // 원문 자막 저장소 -> llm 요약 활용
  final List<Map<String, String>> _translationHistory = []; // 번역 히스토리 (약 3개 정도만 저장)

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
  Future<bool> connectToServer() async {
    try {
      _updateStatus(">> [1] 웹소켓 서버 연결 시도 중...");
      final uri = Uri.parse('$_serverBaseUrl$_serverEndpoint'); // 서버 엔드포인트
      _webSocketChannel = WebSocketChannel.connect(uri); // WebSocket 연결

      // 서버 메시지 수신 리스너
      _webSocketChannel!.stream.listen(
        _handleServerMessage,
        onError: (error) {
          _handleError("- WebSocket 연결 오류", error.toString());
          _isConnected = false;
        },
        onDone: () {
          _updateStatus("- 서버 연결 종료됨");
          _isConnected = false;
          _isSessionReady = false;
        },
      );

      _isConnected = true;
      _updateStatus("- 서버 연결 성공");
      return true;
    } catch (e) {
      _handleError("- 서버 연결 실패", e.toString());
      return false;
    }
  }

  // [2] 음성 인식 세션 시작 (언어 설정 - ConfigMessage)
  Future<bool> startSession({
    required String inputLanguage,
    required List<String> targetLanguages,
  }) async {
    if (!_isConnected || _webSocketChannel == null) {
      _handleError("세션 시작 실패", "서버가 연결되지 않았습니다");
      return false;
    }

    try {
      // 1) 마이크 권한 확인
      if (!await _checkMicrophonePermission()) {
        _handleError("- 세션 시작 실패", "마이크 권한이 필요합니다");
        return false;
      }

      // 2) 설정 메시지 생성
      final configMessage = ConfigMessage(
        inputLanguage: inputLanguage,
        targetLanguages: targetLanguages,
      );

      // JSON 매핑 -> 전송
      _webSocketChannel!.sink.add(jsonEncode(configMessage.toJson()));

      // 현재 상태 업데이트
      _currentInputLanguage = inputLanguage;
      _currentTargetLanguages = targetLanguages;

      //자막 데이터 초기화
      _clearTranslationData();

      _updateStatus("세션 설정 전송 완료, 서버 응답 대기 중...");
      return true;
    } catch (e) {
      _handleError("- 세션 시작 실패", e.toString());
      return false;
    }
  }

  // [3] 음성 녹음 시작
  Future<bool> startRecording() async {
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

  // [4] 음성 녹음 중지
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      await _audioStreamSubscription?.cancel();
      await _audioRecorder.stop();

      _audioStreamSubscription = null;
      _isRecording = false;

      _updateStatus(">> [4] 음성 녹음 중지");
    } catch (e) {
      _handleError("- 녹음 중지 실패", e.toString());
    }
  }

  // [5] 언어 설정 변경 (세션 중에)
  Future<bool> changeLanguageSettings({
    String? newInputLanguage,
    List<String>? newTargetLanguages,
  }) async {
    if (!_isConnected || _webSocketChannel == null) {
      _handleError("언어 설정 변경 실패", "서버가 연결되지 않았습니다");
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

      _updateStatus(">> [5] 언어 설정 변경 요청 전송");
      return true;
    } catch (e) {
      _handleError("언어 설정 변경 실패", e.toString());
      return false;
    }
  }

  // [6] 연결 종료
  Future<void> disconnect() async {
    try {
      // 1) 녹음 중지
      await stopRecording();

      // 2) WebSocket 연결 종료
      await _webSocketChannel?.sink.close();
      _webSocketChannel = null;

      _isConnected = false;
      _isSessionReady = false;
      _updateStatus(">> [6] 연결 종료 완료");
    } catch (e) {
      _handleError("연결 종료 중 오류", e.toString());
    }
  }

  // 번역 데이터 초기화
  void _clearTranslationData() {
    _currentTranslations.clear();
    _transcriptHistory.clear();
    _translationHistory.clear();
    debugPrint("번역 데이터 초기화");
  }

  // 번역 데이터 수동 초기화 (외부 호출 용)
  void clearAllData() {
    _clearTranslationData();
  }

  // [헬퍼 함수]
  // 서버 메시지 처리
  void _handleServerMessage(dynamic message) {
    try {
      Map<String, dynamic> data;

      // 메시지 타입 확인 (String 또는 이미 파싱된 Map)
      if (message is String) {
        data = jsonDecode(message);
      } else if (message is Map<String, dynamic>) {
        data = message;
      } else {
        debugPrint("알 수 없는 메시지 형식: ${message.runtimeType}");
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

  // 상태 메시지 처리 (StatusMessage)
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

  // 마이크 권한 확인
  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  // 번역 결과 처리 (SpeechTranslationResponse) (콜백)
  void _handleTranslationResult(SpeechTranslationResponse response) {
    if (response.translations.isNotEmpty) {
      // 1) 현재 번역 결과 업데이트
      _currentTranslations.clear(); //현재 번역 초기화
      String? originalText;

      // 나라별 번역 결과 저장
      onTranslationReceived?.call(response.translations); // 콜백

      // 로그 출력
      print("=== 번역 결과 ===");
      response.translations.forEach((lang, result) {
        _currentTranslations[lang] = result.resultText;

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

      // 5) 로그 출력
      debugPrint("=== 번역 결과 ===");
      response.translations.forEach((lang, result) {
        debugPrint("$lang: ${result.resultText}");
      });

      //원문 저장 상태 로그 출력
      if (originalText != null) {
        debugPrint("원문 저장: $originalText");
        debugPrint("총 원문 개수: ${_transcriptHistory.length}");
      }
    }
  }

  // 상태 업데이트 헬퍼 (콜백)
  void _updateStatus(String status) {
    debugPrint("Status: $status");
    print("Status: $status");
    onStatusUpdate?.call(status); // 콜백
  }

  // 에러 처리 헬퍼 (콜백)
  void _handleError(String message, String? errorCode) {
    debugPrint("Error: $message ${errorCode != null ? '($errorCode)' : ''}");
    print("Error: $message ${errorCode != null ? '($errorCode)' : ''}");
    onError?.call(message, errorCode); // 콜백
  }

  // 리소스 정리
  void dispose() {
    disconnect();
  }
}
