// [services/websocket_multiple_speech_service.dart]
/// 서버 STT + 번역 (Multiple Mode) 엔드포인트 연결
library;

import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart'; // 마이크 오디오 녹음
import 'package:permission_handler/permission_handler.dart'; // 마이크 권한 관리

import 'dart:convert'; // JSON 데이터 변환 (인코딩, 디코딩)
import 'dart:typed_data'; // 바이너리 오디오 데이터 처리
import 'dart:async'; // Stream, Timer 등 비동기 처리
import '../core/global_core.dart';
import '../models/multiple_config_message_model.dart'; //언어 설정 request dto
import '../models/status_message_model.dart';
import '../models/speech_translation_response_model.dart';

class WebSocketSTTService {
  // [WebSocket 통신]
  WebSocketChannel? _webSocketChannel; // 실시간 통신 채널
  final String _serverEndpoint =
      "/api/routes/speech-translation/connect/multiple-mode";

  // [상태 변수]
  bool _isConnected = false; // 서버 연결 상태
  bool _isSessionReady = false; // 음성 인식 세션 준비 여부

  // [오디오 녹음 관련]
  final AudioRecorder _audioRecorder = AudioRecorder(); // 오디오 캡쳐 객체
  bool _isRecording = false; // 현재 녹음 상태
  StreamSubscription<Uint8List>? _audioStreamSubscription; // 오디오 스트림 구독 관리

  // [현재 설정]
  List<String>? _currentInputLanguages; // 현재 입력 언어 (국가)
  List<String>? _currentTargetLanguages; // 현재 타켓 언어 (국가)

  //[번역 결과 저장]
  final Map<String, String> _currentTranslations = {}; // 현재 번역 결과
  final List<String> _transcriptHistory = []; // 원문 자막 저장소 - 다국어 인식 결과 저장
  final Map<String, List<String>> _languageTextHistory = {}; //각 나라 별 자막 저장소
  final List<Map<String, String>> _translationHistory =
      []; // 번역 히스토리 (약 3개 정도만 저장)

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
  List<String>? get currentInputLanguages => _currentInputLanguages;
  List<String>? get currentTargetLanguages => _currentTargetLanguages;

  // [Getter] 번역 결과 접근
  Map<String, String> get currentTranslations =>
      Map.unmodifiable(_currentTranslations);
  Map<String, List<String>> get languageTextHistory =>
      Map.unmodifiable(_languageTextHistory);
  List<String> get transcriptHistory => List.unmodifiable(_transcriptHistory);
  List<Map<String, String>> get translationHistory =>
      List.unmodifiable(_translationHistory);

  // 전체 원문 텍스트 (하나의 문단으로) -> LLM 활용 -> [언어] 내용 형태로 확장 고려
  String get fullTranscriptText => _transcriptHistory.join("\n");

  // // 각 나라 원문 텍스트 (하나의 문자열로) -> LLM 활용
  // String get LanguageTranscriptText => _languageTextHistory.join(" ");

  // [1] WebSocket 서버 연결 (상태 응답 - StatusMessage)
  Future<bool> connectToServer() async {
    try {
      _updateStatus(">> [1] 웹소켓 서버 연결 시도 중...");
      final uri = Uri.parse('$serverBaseUrl$_serverEndpoint'); // 서버 엔드포인트
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
    required List<String> inputLanguages,
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
      final configMessage = MultipleConfigMessage(
        inputLanguages: inputLanguages,
        targetLanguages: targetLanguages,
      );

      // JSON 매핑 -> 전송
      _webSocketChannel!.sink.add(jsonEncode(configMessage.toJson()));

      // 현재 상태 업데이트
      _currentInputLanguages = inputLanguages;
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

  Future<void> resumeRecording() async {
    if (_isRecording || !_isConnected) return;

    debugPrint("🔍 재시작: 기존 데이터 연결됨");
    await startRecording(); // 기존 메서드 그대로 호출
  }

  // [5] 언어 설정 변경 (세션 중에)
  Future<bool> changeLanguageSettings({
    List<String>? newInputLanguages,
    List<String>? newTargetLanguages,
  }) async {
    if (!_isConnected || _webSocketChannel == null) {
      _handleError("언어 설정 변경 실패", "서버가 연결되지 않았습니다");
      return false;
    }

    try {
      final configMessage = MultipleConfigMessage(
        inputLanguages: newInputLanguages ?? _currentInputLanguages!,
        targetLanguages: newTargetLanguages ?? _currentTargetLanguages!,
      );

      _webSocketChannel!.sink.add(jsonEncode(configMessage.toJson()));

      if (newInputLanguages != null) _currentInputLanguages = newInputLanguages;

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
    _languageTextHistory.clear();
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
          _handleTranslationResult(
            SeperatedSpeechTranslationResponse.fromJson(data),
          );
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

  // 번역 결과 처리 (SeperatedSpeechTranslationResponse) (콜백)
  void _handleTranslationResult(SeperatedSpeechTranslationResponse response) {
    if (response.translations.isNotEmpty && response.original.isNotEmpty) {
      // 1) 현재 번역 결과 업데이트
      _currentTranslations.clear(); //현재 번역 초기화
      String? originalText;

      debugPrint("=== 번역 결과 ===");
      response.translations.forEach((lang, result) {
        _currentTranslations[lang] = result.resultText;

        //번역 결과 로그 출력 포함
        debugPrint("$lang: ${result.resultText}");

        //각 나라 언어 저장소에 추가
        //저장소에 없는 나라면 list 추가 먼저
        if (_languageTextHistory[lang] == null) {
          _languageTextHistory[lang] = [];
        }
        //추가
        _languageTextHistory[lang]!.add(result.resultText);
      });

      // 2) 원문 자막 저장소에 추가
      response.original.forEach((lang, result) {
        originalText = result.resultText;
        _transcriptHistory.add(result.resultText);
      });

      // 3) 번역 저장소에 추가
      if (_currentTranslations.isNotEmpty) {
        _translationHistory.add(Map.from(_currentTranslations));
      }

      // 4) 콜백 호출
      onTranslationReceived?.call(response.translations);

      // 5) 원문 저장 상태 로그 출력
      if (originalText != null) {
        debugPrint("원문 저장: $originalText");
        debugPrint("총 원문 개수: ${_transcriptHistory.length}");
      }
    }
  }

  // 상태 업데이트 헬퍼 (콜백)
  void _updateStatus(String status) {
    debugPrint("Status: $status");
    onStatusUpdate?.call(status); // 콜백
  }

  // 에러 처리 헬퍼 (콜백)
  void _handleError(String message, String? errorCode) {
    debugPrint("Error: $message ${errorCode != null ? '($errorCode)' : ''}");
    onError?.call(message, errorCode); // 콜백
  }

  // 리소스 정리
  void dispose() {
    disconnect();
  }
}
