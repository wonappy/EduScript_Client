// [services/websocket_multiple_speech_service.dart]
/// 서버 STT + 번역 (Multiple Mode) 엔드포인트 연결
library;

import 'package:flutter/cupertino.dart';
import 'dart:convert'; // JSON 데이터 변환 (인코딩, 디코딩)
import 'dart:typed_data'; // 바이너리 오디오 데이터 처리
import 'dart:async'; // Stream, Timer 등 비동기 처리
import '../models/multiple_config_message_model.dart'; //언어 설정 request dto
import '../models/status_message_model.dart';
import '../models/speech_translation_response_model.dart';
import 'audio/audio_record_service.dart';
import 'network/websocket_client.dart';

class WebSocketMultipleSpeechService {
  // [서비스 객체 변수]
  final WebsocketClient _client = WebsocketClient(); // 웹소켓 클라이언트 객체 변수 저장
  final AudioRecordService _audioService =
      AudioRecordService(); // 오디오 서비스 객체 변수 저장

  // [통신 엔드포인트 변수]
  final String _serverEndpoint =
      "/api/routes/speech-translation/connect/multiple-mode";

  // [오디오 스트림 연결] (오디오 -> 웹소켓)
  StreamSubscription<Uint8List>? _audioStreamSubscription; // 오디오 스트림 구독 관리

  // [상태 변수]
  bool _isSessionReady = false; // 음성 인식 세션 준비 여부

  // [현재 언어 설정] 재연결 시 복구 용도
  List<String>? _currentInputLanguages; // 현재 입력 언어 (국가)
  List<String>? _currentTargetLanguages; // 현재 타켓 언어 (국가)

  // [번역 결과 저장소]
  final Map<String, String> _currentTranslations = {}; // 현재 번역 결과
  final List<String> _transcriptHistory = []; // 원문 자막 저장소 - 다국어 인식 결과 저장
  final Map<String, List<String>> _languageTextHistory = {}; // 각 나라 별 자막 저장소
  final List<Map<String, String>> _translationHistory =
      []; // 번역 히스토리 (약 3개 정도만 저장)

  // [콜백 함수]
  Function(Map<String, TranslationResult>, bool, String)?
  onTranslationReceived; // 번역 결과 콜백
  Function(String)? onStatusUpdate; // 상태 변경 콜백
  Function(String, String?)? onError; // 에러 콜백

  // [싱글톤 패턴]
  static final WebSocketMultipleSpeechService _instance =
      WebSocketMultipleSpeechService._internal();
  factory WebSocketMultipleSpeechService() => _instance;
  WebSocketMultipleSpeechService._internal() {
    _initializeClientListeners();
  }

  // [Getter] 현재 상태 확인
  bool get isConnected => _client.isConnected;
  bool get isSessionReady => _isSessionReady;
  bool get isRecording => _audioService.isRecording;
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

  // [1] 서버에 WebSocket 연결 (상태 응답 - StatusMessage)
  Future<bool> connectToServer({bool isRetry = false}) async {
    debugPrint("[DEBUG] connectToServer 메서드 실행 (웹소켓 연결)");

    if (!isRetry) _updateStatus("서버 연결 시도 (Conference Mode). . .");
    return await _client.connect(endpoint: _serverEndpoint, isRetry: isRetry);
  }

  // [2] 음성 인식 세션 시작 (언어 설정 - MultipleConfigMessage)
  Future<bool> startSession({
    required List<String> inputLanguages, // 입력 언어 국가 (다중)
    required List<String> targetLanguages, // 출력 언어 국가 (다중)
  }) async {
    debugPrint("[DEBUG] startSession 메서드 실행 (세션 시작)");

    if (!isConnected) {
      _handleError("세션 시작 실패", "서버가 연결되지 않았습니다");
      return false;
    }

    try {
      final configMessage = MultipleConfigMessage(
        type: 'setting',
        inputLanguages: inputLanguages,
        targetLanguages: targetLanguages,
      );
      debugPrint("[DEBUG] 언어 설정 정보 - ${configMessage.toJson()}");

      /// JSON 매핑 -> 전송
      _client.send(jsonEncode(configMessage.toJson()));

      // 현재 상태 업데이트
      _currentInputLanguages = inputLanguages;
      _currentTargetLanguages = targetLanguages;
      _clearTranslationData(); //데이터 초기화

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
    debugPrint("[DEBUG] stopRecording() 메서드 (녹음 중지)");

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
    List<String>? newInputLanguages,
    List<String>? newTargetLanguages,
  }) async {
    debugPrint("[DEBUG] changeLanguageSettings 메서드 실행 (세션 중 언어 설정 변경)");

    if (!isConnected) {
      _handleError("언어 설정 변경 실패", "서버가 연결되지 않았습니다");
      return false;
    }

    try {
      final configMessage = MultipleConfigMessage(
        inputLanguages: newInputLanguages ?? _currentInputLanguages!,
        targetLanguages: newTargetLanguages ?? _currentTargetLanguages!,
      );

      _client.send(jsonEncode(configMessage.toJson()));

      if (newInputLanguages != null) _currentInputLanguages = newInputLanguages;
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
    _languageTextHistory.clear();
    _transcriptHistory.clear();
    _translationHistory.clear();
    debugPrint("번역 데이터 초기화");
  }

  // +) 번역 데이터 수동 초기화 (외부 호출 용)
  void clearAllData() {
    _clearTranslationData();
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
      if (_currentInputLanguages != null && _currentTargetLanguages != null) {
        await startSession(
          inputLanguages: _currentInputLanguages!,
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
        data = jsonDecode(message); // 파싱
      } else if (message is Map<String, dynamic>) {
        data = message;
      } else {
        debugPrint("[DEBUG] 알 수 없는 메시지 형식 - ${message.runtimeType}");
        return;
      }

      final type = data['type'];
      switch (type) {
        case 'status':
          _handleStatusMessage(StatusMessage.fromJson(data));
          break;
        case 'result':
          _handleTranslationResult(
            SeperatedSpeechTranslationResponse.fromJson(data),
          );
          break;
        default:
          debugPrint("[ERROR] 알 수 없는 메시지 타입 - $type");
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
        startRecording(); // 녹음 시작
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

  // 번역 결과 처리 (SeperatedSpeechTranslationResponse) (콜백)
  void _handleTranslationResult(SeperatedSpeechTranslationResponse response) {
    if (response.translations.isNotEmpty && response.original.isNotEmpty) {
      // 1) 현재 번역 결과 업데이트
      _currentTranslations.clear(); // 현재 번역 초기화
      String? originalText;

      response.translations.forEach((lang, result) {
        _currentTranslations[lang] = result.resultText;

        // 각 국가 언어 저장소에 추가 -> 저장소에 없는 나라면 List 먼저 추가
        if (_languageTextHistory[lang] == null) {
          _languageTextHistory[lang] = [];
        }
        //완전 문장일 경우에만 저장소에 추가
        if (response.isFinal) {
          _languageTextHistory[lang]!.add(result.resultText);
        }
      });

      // 2) 원문 자막 저장소에 추가
      if (response.isFinal) {
        response.original.forEach((lang, result) {
          originalText = result.resultText;
          _transcriptHistory.add(result.resultText);
        });
      }

      // 3) 번역 저장소에 추가
      if (_currentTranslations.isNotEmpty && response.isFinal) {
        _translationHistory.add(Map.from(_currentTranslations));
      }

      // 4) 콜백 호출
      onTranslationReceived?.call(
        response.translations,
        response.isFinal,
        response.original.keys.first,
      );

      // 5) 원문 저장 상태 로그 출력
      if (originalText != null) {
        debugPrint("[DEBUG] 원문 저장 - $originalText");
        debugPrint("[DEBUG] 총 원문 개수 - ${_transcriptHistory.length}");
      }
    }
  }

  // 상태 업데이트 (콜백)
  void _updateStatus(String status) {
    debugPrint("[STATUS] $status");
    onStatusUpdate?.call(status); // 콜백
  }

  // 에러 출력 (콜백)
  void _handleError(String message, String? errorCode) {
    debugPrint("[ERROR] $message ${errorCode != null ? '($errorCode)' : ''}");
    onError?.call(message, errorCode); // 콜백
  }

  // [리소스 정리]
  void dispose() {
    // 완전 종료 전 모든 저장소 내용 출력
    _printAllStoredData();
    disconnect();
  }

  // 모든 저장소 내용 출력
  void _printAllStoredData() {
    debugPrint("=" * 60);

    // 기본 통계 정보
    debugPrint("기본 통계:");
    debugPrint("  - 총 원문 개수: ${_transcriptHistory.length}개");
    debugPrint("  - 총 번역 히스토리: ${_translationHistory.length}개");

    // 현재 설정 정보
    debugPrint("현재 설정:");
    debugPrint("  - 입력 언어: ${_currentInputLanguages ?? 'None'}");
    debugPrint("  - 출력 언어: ${_currentTargetLanguages ?? 'None'}");

    // 전체 원문 텍스트 (연결된 형태)
    debugPrint("전체 원문 텍스트:");
    final fullText = fullTranscriptText;
    if (fullText.isEmpty) {
      debugPrint("  (전체 텍스트가 없습니다)");
    } else {
      debugPrint("  총 길이: ${fullText.length}자");
      // 너무 길면 일부만 출력
      if (fullText.length > 500) {
        debugPrint("  내용 (처음 500자): ${fullText.substring(0, 500)}...");
      } else {
        debugPrint("  전체 내용: $fullText");
      }
    }

    // 각 언어별 전체 텍스트
    debugPrint("언어별 전체 텍스트:");
    if (_languageTextHistory.isEmpty) {
      debugPrint("  (언어별 데이터가 없습니다)");
    } else {
      _languageTextHistory.forEach((language, textList) {
        final languageFullText = textList.join(" ");
        debugPrint("  $language (${languageFullText.length}자): ");
        if (languageFullText.length > 200) {
          debugPrint("    ${languageFullText.substring(0, 200)}...");
        } else {
          debugPrint("    $languageFullText");
        }
      });
    }

    debugPrint("=" * 60);
  }
}
