// [services/websocket_stt_service.dart]
/// 서버 STT + 번역 (Single Mode) 엔드포인트 연결
library;

import 'package:client/services/network/websocket_client.dart';
import 'package:flutter/cupertino.dart';

import 'dart:convert'; // JSON 데이터 변환 (인코딩, 디코딩)
import 'dart:typed_data'; // 바이너리 오디오 데이터 처리
import 'dart:async'; // Stream, Timer 등 비동기 처리
import '../models/config_message_model.dart';
import '../models/status_message_model.dart';
import '../models/speech_translation_response_model.dart';
import 'audio/audio_record_service.dart';

class WebSocketSTTService {
  // [서비스 객체 변수]
  final WebsocketClient _client = WebsocketClient(); // 웹소켓 클라이언트 객체 변수 저장
  final AudioRecordService _audioService =
      AudioRecordService(); // 오디오 서비스 객체 변수 저장

  // [오디오 스트림 연결] (오디오 -> 웹소켓)
  StreamSubscription<Uint8List>? _audioStreamSubscription; // 오디오 스트림 구독 관리

  // [상태 변수]
  bool _isSessionReady = false; // 음성 인식 세션 준비 여부
  String? _transcriptBackup; // 자막 백업용

  // [현재 언어 설정] 재연결 시 복구 용도
  String? _currentInputLanguage; // 현재 입력 언어 (국가)
  List<String>? _currentTargetLanguages; // 현재 출력 언어 (국가)

  // [번역 결과 저장소]
  final Map<String, String> _currentTranslations = {}; // 현재 번역 결과
  final List<String> _transcriptHistory = []; // 원문 자막 저장소 -> llm 요약 활용
  final List<Map<String, String>> _translationHistory =
      []; // 번역 히스토리 (약 3개 정도만 저장)

  // [콜백 함수]
  Function(Map<String, TranslationResult>, bool)?
  onTranslationReceived; // 번역 결과 콜백
  Function(String)? onStatusUpdate; // 상태 변경 콜백
  Function(String, String?)? onError; // 에러 콜백

  // [싱글톤 패턴]
  static final WebSocketSTTService _instance = WebSocketSTTService._internal();
  factory WebSocketSTTService() => _instance;
  WebSocketSTTService._internal() {
    _initializeClientListeners();
  }

  // [Getter] 현재 상태 확인
  bool get isConnected => _client.isConnected;
  bool get isSessionReady => _isSessionReady;
  bool get isRecording => _audioService.isRecording;
  String? get currentInputLanguage => _currentInputLanguage;
  List<String>? get currentTargetLanguages => _currentTargetLanguages;

  // [Getter] 번역 결과 접근
  Map<String, String> get currentTranslations =>
      Map.unmodifiable(_currentTranslations);
  List<String> get transcriptHistory => List.unmodifiable(_transcriptHistory);
  List<Map<String, String>> get translationHistory =>
      List.unmodifiable(_translationHistory);

  // 전체 원문 텍스트 (하나의 문자열로) -> LLM 활용
  String get fullTranscriptText {
    if (_transcriptHistory.isNotEmpty) {
      return _transcriptHistory.join(' ');
    } else if (_transcriptBackup != null) {
      debugPrint("[DEBUG] 백업된 원문 사용");
      return _transcriptBackup!;
    } else {
      return '';
    }
  }

  // [1] 서버에 WebSocket 연결 (상태 응답 - StatusMessage)
  Future<bool> connectToServer({bool isRetry = false}) async {
    debugPrint("[DEBUG] connectToServer 메서드 실행 (웹소켓 연결)");

    if (!isRetry) _updateStatus("서버 연결 시도 . . .");
    return await _client.connect(isRetry: isRetry);
  }

  // [2] 음성 인식 세션 시작 (언어 설정 - ConfigMessage)
  // 어플리케이션 세션 시작
  // 언어 설정 전송 -> "ready" 응답 대기
  Future<bool> startSession({
    required String inputLanguage, // (매개변수1) 입력 언어 국가 설정
    required List<String> targetLanguages, // (매개변수2) 출력 언어 국가 설정
  }) async {
    debugPrint("[DEBUG] startSession 메서드 실행 (세션 시작)");

    if (!isConnected) {
      _handleError("세션 시작 실패", "서버가 연결되지 않았습니다");
      return false;
    }

    try {
      // 설정 메시지 생성
      final configMessage = ConfigMessage(
        inputLanguage: inputLanguage, // 입력 언어 국가
        targetLanguages: targetLanguages, // 출력 언어 국가
      );

      // JSON 매핑 -> 전송
      _client.send(jsonEncode(configMessage.toJson()));

      // 현재 상태 업데이트
      _currentInputLanguage = inputLanguage;
      _currentTargetLanguages = targetLanguages;
      _clearTranslationData(); // 데이터 초기화

      _updateStatus("세션 설정 전송 완료, 서버 응답 대기 중...");
      return true;
    } catch (e) {
      _handleError("세션 시작 실패", e.toString());
      return false;
    }
  }

  // [3] 음성 녹음 시작
  Future<bool> startRecording() async {
    debugPrint("[DEBUG] startRecording() 메서드 실행");

    if (!_isSessionReady) {
      _handleError("녹음 시작 실패", "세션이 준비되지 않았습니다");
      return false;
    }

    // 오디오 스트림 정리
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    // 오디오 스트림 요청
    final stream = await _audioService.startRecording();

    if (stream != null) {
      // 오디오 데이터를 서버로 실시간 전송
      _audioStreamSubscription = stream.listen(
        // 오디오가 들어올 때 콜백
        (audioData) => _client.send(audioData), // 바이너리 음성 데이터를 실시간으로 전송,
        onError: (error) {
          _handleError("오디오 스트림 오류", error.toString());
        },
      );

      // 상태 업데이트
      _updateStatus("음성 녹음 시작");
      return true;
    }
    return false;
  }

  // [4] 음성 녹음 중지
  Future<void> stopRecording() async {
    debugPrint("[DEBUG] stopRecording() 메서드 (녹음 중지)"); // 디버깅

    // 음성 스트림 종료
    await _audioStreamSubscription?.cancel(); // 음성 스트림 취소
    _audioStreamSubscription = null; // 음성 스트림 변수 초기화

    // 마이크 종료
    _audioService.stopRecording();

    _updateStatus("음성 녹음 중지");
  }

  // [5] 녹음 중지 후 재개
  Future<void> resumeRecording() async {
    debugPrint("[DEBUG] resumeRecording() 메서드 실행 (녹음 중지 후 재개)");
    if (isRecording || !isConnected) return;

    _updateStatus("재시작 : 기존 데이터 연결됨");
    await startRecording(); // (호출) [3] 음성 녹음 시작
  }

  // [6] 언어 설정 변경 (세션 중에)
  Future<bool> changeLanguageSettings({
    String? newInputLanguage, // 새 입력 언어 국가
    List<String>? newTargetLanguages, // 새 출력 언어 국가 List
  }) async {
    debugPrint("[DEBUG] changeLanguageSettings 메서드 실행 (세션 중 언어 설정 변경)");

    if (!isConnected) {
      _handleError("언어 설정 변경 실패", "서버가 연결되지 않았습니다");
      return false;
    }

    try {
      final configMessage = ConfigMessage(
        inputLanguage: newInputLanguage ?? _currentInputLanguage!,
        targetLanguages: newTargetLanguages ?? _currentTargetLanguages!,
      );

      _client.send(jsonEncode(configMessage.toJson()));

      if (newInputLanguage != null) _currentInputLanguage = newInputLanguage;
      if (newTargetLanguages != null) {
        _currentTargetLanguages = newTargetLanguages;
      }

      _updateStatus("언어 설정 변경 요청 전송 완료");
      return true;
    } catch (e) {
      _handleError("언어 설정 변경 실패", e.toString());
      return false;
    }
  }

  // [7] 연결 종료
  Future<void> disconnect() async {
    debugPrint("[DEBUG] disconnect() 메서드 실행 (연결 종료)");
    try {
      _transcriptBackup = _transcriptHistory.join(' ');

      // 녹음 중지
      await stopRecording(); // 녹음 중지
      await _client.disconnect(); // 소켓 중지

      _isSessionReady = false; // 세션 준비 상태 종료
      _updateStatus("연결 종료 완료");
    } catch (e) {
      _handleError("연결 종료 중 오류", e.toString());
    }
  }

  // [헬퍼 함수]
  // +) 번역 데이터 초기화
  void _clearTranslationData() {
    _currentTranslations.clear();
    _transcriptHistory.clear();
    _translationHistory.clear();
    _updateStatus("번역 데이터 초기화");
  }

  // +) 번역 데이터 수동 초기화 (외부 호출 용)
  void clearAllData() {
    _clearTranslationData(); // (호출) +) 번역 데이터 초기화
  }

  // WebsocketClient 이벤트 리스너 연결 함수
  void _initializeClientListeners() {
    // 1) 서버 메시지 수신
    _client.onMessage = (message) => _handleServerMessage(message);

    // 2) 에러 발생
    _client.onError = (error) => _handleError("통신 오류", error.toString());

    // 3) 연결 끊김 -> 상태 업데이트 + 녹음 중지
    _client.onDisconnected = () {
      _isSessionReady = false;
      stopRecording(); // 끊기면 일단 녹음 중지
      _updateStatus("서버 연결 끊김. 재연결 대기 중...");
    };

    // 4) 재연결 성공
    _client.onReconnected = () async {
      _updateStatus("서버 재연결 성공. 세션을 복구합니다.");
      // 언어 설정이 남아있다면 세션 다시 시작
      if (_currentInputLanguage != null && _currentTargetLanguages != null) {
        await startSession(
          inputLanguage: _currentInputLanguage!,
          targetLanguages: _currentTargetLanguages!,
        );
      }
    };
  }

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
        debugPrint("[DEBUG] 알 수 없는 메시지 형식: ${message.runtimeType}");
        return;
      }

      final type = data['type'];
      switch (type) {
        case 'status':
          _handleStatusMessage(StatusMessage.fromJson(data));
          break;
        case 'result':
          _handleTranslationResult(SpeechTranslationResponse.fromJson(data));
          break;
        default:
          debugPrint("알 수 없는 메시지 타입: $type");
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
        _updateStatus(statusMsg.message ?? '세션 준비 완료');
        startRecording(); // 준비 완료 시 녹음 시작
        break;
      case 'error':
        _isSessionReady = false;
        _handleError(statusMsg.message ?? '서버 오류', statusMsg.errorCode);
        break;
      case 'warning':
        _updateStatus(statusMsg.message ?? '경고');
        break;
      case 'disconnected':
        _isSessionReady = false;
        _updateStatus(statusMsg.message ?? '연결 종료');
        break;
      default:
        _updateStatus(statusMsg.message ?? statusMsg.status);
    }
  }

  // 번역 결과 처리 (SpeechTranslationResponse) (콜백)
  void _handleTranslationResult(SpeechTranslationResponse response) {
    if (response.translations.isNotEmpty) {
      // 1) 현재 번역 결과 업데이트
      _currentTranslations.clear(); //현재 번역 초기화
      String? originalText;

      response.translations.forEach((lang, result) {
        _currentTranslations[lang] = result.resultText;
        originalText ??= result.resultText; // 입력 언어의 텍스트를 원문으로 저장
      });

      // 2) 원문 자막 저장소에 추가
      if (originalText != null &&
          originalText!.isNotEmpty &&
          response.isFinal) {
        _transcriptHistory.add(originalText!);
      }

      // 3) 번역 저장소에 추가
      if (_currentTranslations.isNotEmpty && response.isFinal) {
        _translationHistory.add(Map.from(_currentTranslations));
      }

      // 4) 콜백 호출
      onTranslationReceived?.call(response.translations, response.isFinal);

      // 5) 원문 저장 상태 로그 출력
      if (originalText != null) {
        debugPrint("[DEBUG] 원문 저장: $originalText");
        debugPrint("[DEBUG] 총 원문 개수: ${_transcriptHistory.length}");
      }
    }
  }

  // 상태 업데이트 헬퍼 (콜백)
  void _updateStatus(String status) {
    debugPrint("[STATUS] $status");
    onStatusUpdate?.call(status); // 콜백
  }

  // 에러 처리 헬퍼 (콜백)
  void _handleError(String message, String? errorCode) {
    debugPrint("[ERROR] $message ${errorCode != null ? '($errorCode)' : ''}");
    onError?.call(message, errorCode); // 콜백
  }

  // [리소스 정리]
  void dispose() {
    disconnect();
  }
}
