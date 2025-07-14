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

class WebSocketMultipleSTTService {
  // [WebSocket 통신]
  WebSocketChannel? _webSocketChannel; // 실시간 통신 채널
  final String _serverEndpoint =
      "/api/routes/speech-translation/connect/multiple-mode";

  // [연결 상태 변수]
  bool _isConnected = false; // 서버 연결 상태
  bool _isSessionReady = false; // 음성 인식 세션 준비 여부
  bool _isReconnecting = false; // 재연결 상태

  // [오디오 녹음 관련]
  final AudioRecorder _audioRecorder = AudioRecorder(); // 오디오 캡쳐 객체
  bool _isRecording = false; // 현재 녹음 상태
  StreamSubscription<Uint8List>? _audioStreamSubscription; // 오디오 스트림 구독 관리

  final List<int> _audioBuffer = []; //오디오 버퍼 저장
  Timer? _bufferSendTimer; //오디오 전송 시간

  // [현재 언어 설정]
  List<String>? _currentInputLanguages; // 현재 입력 언어 (국가)
  List<String>? _currentTargetLanguages; // 현재 타켓 언어 (국가)

  //[번역 결과 저장]
  final Map<String, String> _currentTranslations = {}; // 현재 번역 결과
  final List<String> _transcriptHistory = []; // 원문 자막 저장소 - 다국어 인식 결과 저장
  final Map<String, List<String>> _languageTextHistory = {}; // 각 나라 별 자막 저장소
  final List<Map<String, String>> _translationHistory =
      []; // 번역 히스토리 (약 3개 정도만 저장)

  // [서버 연결 재시도 처리 관련]
  Timer? _reconnectTimer; // 재시도 타이머
  int _reconnectAttempts = 0; // 재시도 횟수
  final int _maxReconnectAttempts = 3; // 최대 재시도 가능 횟수 (무한 재시도 방지)
  final List<int> _reconnectDelays = [2, 6, 10]; // 대기 시간 증가
  bool _shouldAutoReconnect = true; // 재연결 기능 on/off
  bool _wasRecordingBeforeDisconnect = false; // 연결 끊어지기 전 상태

  // [콜백 함수]
  Function(Map<String, TranslationResult>, bool, String)?
  onTranslationReceived; // 번역 결과 콜백
  Function(String)? onStatusUpdate; // 상태 변경 콜백
  Function(String, String?)? onError; // 에러 콜백

  // [싱글톤 패턴]
  static final WebSocketMultipleSTTService _instance =
      WebSocketMultipleSTTService._internal();
  factory WebSocketMultipleSTTService() => _instance;
  WebSocketMultipleSTTService._internal();

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

  // 각 나라 원문 텍스트 (하나의 문자열로) -> LLM 활용
  // String get LanguageTranscriptText => _languageTextHistory.join(" ");

  // [1] WebSocket 연결 (상태 응답 - StatusMessage)
  Future<bool> connectToServer({bool isRetry = false}) async {
    debugPrint("[DEBUG 1] connectToServer 메서드 실행 (웹소켓 연결)");
    // 기존 웹소켓 정리
    if (_webSocketChannel != null) {
      try {
        //debugPrint("[🐟 DEBUG 1] 이전 웹소켓 정리 시도 - $_countWebSocketChannel차");
        // 1) 기존 웹소켓 채널에 "연결 종료" 신호
        _webSocketChannel!.sink.close().timeout(const Duration(seconds: 2));
        //debugPrint("[🐟 DEBUG 1] 이전 웹소켓 채널을 정리했습니다.");
      } catch (e) {
        // 2) 이미 닫힌 채널 또 닫지 않도록
        debugPrint("[DEBUG 1] 이전 웹소켓 정리 중 오류 발생 (무시 가능) - $e");
      }
      _webSocketChannel = null; // 웹소켓 변수 삭제
    }

    try {
      if (!isRetry) {
        debugPrint("[🐟 DEBUG] === MultiMode 연결 시작 시간 - ${DateTime.now()} ===");
        _updateStatus("[DEBUG 1] 웹소켓 서버 연결 시도");
        // 처음 연결 시 자동 재연결
        _shouldAutoReconnect = true; // 자동 재연결 활성화
        _reconnectAttempts = 0; // 연결 시도 횟수 초기화 (최초 연결 시에만 리셋)
      } else {
        // 재시도 시
        _updateStatus(
          "서버 연결 재시도 ${_reconnectAttempts}/${_maxReconnectAttempts}",
        );
      }

      // 2) 서버에 WebSocket 연결 시도
      final uri = Uri.parse('$serverBaseUrl$_serverEndpoint'); // 서버 엔드포인트
      _webSocketChannel = WebSocketChannel.connect(uri); // WebSocket 연결

      // 3) 서버 연결 완료 확인 - Completer
      final Completer<bool> connectionCompleter = Completer<bool>();

      // 4) 서버 메시지 수신 리스너
      _webSocketChannel!.stream.listen(
        _handleServerMessage,
        onError: (error) {
          if (!isRetry) {
            // "재연결"이 아닐 때에만 콜백 호출
            _handleError("[🐟DEBUG 1] WebSocket 연결 오류", error.toString());
          }
          debugPrint("[🐟DEBUG 1] 메시지 수신 시간 - ${DateTime.now()}");
          debugPrint("[🐟DEBUG 1] 에러 내용 - $error");
          _isConnected = false;
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(false); // 연결 실패로 완료
          }
        },
        onDone: () {
          if (!isRetry) {
            // "재연결"이 아닐 때만 _handleConnectionClosed 호출
            _handleConnectionClosed();
          }
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(false);
          }
          debugPrint("[🐟DEBUG 1] 연결 종료 시간 - ${DateTime.now()}");
          debugPrint("[🐟DEBUG 1] 연결 종료 시점 상태");
          debugPrint("  - isConnected : $_isConnected");
          debugPrint("  - isSessionReady : $_isSessionReady");
          debugPrint("  - isRecording : $_isRecording");

          // _updateStatus("[🐟DEBUG 1] 서버 연결 종료됨");
          // _isConnected = false; // 연결 상태 OFF
          // _isSessionReady = false; // 연결 상태 OFF
        },
      );

      // 5) 타임아웃 예오 ㅣ처리
      try {
        // ready 수신 까지 10초
        await _webSocketChannel!.ready.timeout(
          Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException("WebSocket 연결 타임아웃", Duration(seconds: 10));
          },
        );

        // 웹소켓 연결 성공 시 true 반환
        _isConnected = true; // 연결 상태 ON
        _updateStatus("[DEBUG 1] 서버 연결 성공");
        return true;
      } catch (e) {
        // "재시도"가 아닐 때 예외 처리
        if (!isRetry) {
          if (e is TimeoutException) {
            _handleError("서버 연결 10초 타임아웃", "Connection Timeout");
          } else {
            _handleError("서버 연결 실패", e.toString());
          }
        }
      }
      _isConnected = false;
      return false;
    } catch (e) {
      // "재시도"가 아닐 때만 에러를 보고하도록
      if (!isRetry) {
        _handleError("[ERROR] 서버 연결 실패", e.toString());
      }
      _isConnected = false;
      return false;
    }
  }

  // [2] 음성 인식 세션 시작 (언어 설정 - MultipleConfigMessage)
  Future<bool> startSession({
    required List<String> inputLanguages, // 입력 언어 국가 (다중)
    required List<String> targetLanguages, // 출력 언어 국가 (다중)
  }) async {
    debugPrint("[🐟DEBUG 2] startSession 메서드 실행");

    // 연결이 끊겼을 때
    if (!_isConnected || _webSocketChannel == null) {
      _handleError("[🐟DEBUG 2] 세션 시작 실패", "서버가 연결 되지 않았습니다");
      return false;
    }

    try {
      // 1) 마이크 권한 확인
      if (!await _checkMicrophonePermission()) {
        _handleError("[🐟DEBUG 2] 세션 시작 실패", "마이크 권한이 필요합니다");
        return false;
      }

      // 2) 언어 설정 정보 생성
      final configMessage = MultipleConfigMessage(
        inputLanguages: inputLanguages,
        targetLanguages: targetLanguages,
      );
      debugPrint("[🐟 DEBUG 2] 언어 설정 정보(String) - ${configMessage.toString()}");
      debugPrint("[🐟 DEBUG 2] 언어 설정 정보(Json) - ${configMessage.toJson()}");

      // +) 전송할 메시지
      final jsonMessage = jsonEncode(configMessage.toJson());
      debugPrint("[🐟 DEBUG 2] 전송할 언어 설정 정보 - $jsonMessage");

      // 3) 언어 설정 정보 전송 (JSON 매핑 -> 전송)
      _webSocketChannel!.sink.add(jsonEncode(configMessage.toJson()));
      debugPrint("[🐟 DEBUG 2] 언어 설정 정보 전송 완료 - ${DateTime.now()}");

      // 4) 현재 언어 정보 업데이트
      _currentInputLanguages = inputLanguages;
      _currentTargetLanguages = targetLanguages;

      // 5) 자막 데이터 초기화
      _clearTranslationData();

      _updateStatus("[DEBUG 2] 세션 설정 전송 완료, 서버 응답 대기 중...");
      return true;
    } catch (e) {
      _handleError("[DEBUG 2] 세션 시작 실패", e.toString());
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

      // 2) 오디오 스트림 리스너: 데이터를 버퍼에 추가
      _audioStreamSubscription = stream.listen(
        (audioData) {
          _audioBuffer.addAll(audioData);
        },
        onError: (error) {
          _handleError("오디오 스트림 오류", error.toString());
        },
      );

      // 3) 버퍼 타이머 설정: 250ms 마다 버퍼의 데이터를 서버로 전송
      _bufferSendTimer?.cancel(); // 기존 타이머가 있다면 취소
      _bufferSendTimer = Timer.periodic(const Duration(milliseconds: 250), (
        timer,
      ) {
        // 연결 상태가 정상이면서 버퍼에 데이터가 있을 때만 전송
        if (_isConnected &&
            _webSocketChannel != null &&
            _audioBuffer.isNotEmpty) {
          // 버퍼 데이터 전송
          _webSocketChannel!.sink.add(Uint8List.fromList(_audioBuffer));
          // 버퍼 비움
          _audioBuffer.clear();
        }
      });

      // // 2) 오디오 데이터를 서버로 실시간 전송
      // _audioStreamSubscription = stream.listen(
      //   // 오디오가 들어올 때 콜백
      //   (audioData) {
      //     // 바이너리 음성 데이터
      //     if (_isConnected && _webSocketChannel != null) {
      //       _webSocketChannel!.sink.add(audioData); // 음성 데이터를 실시간으로 전송
      //     }
      //   },
      //   onError: (error) {
      //     _handleError("오디오 스트림 오류", error.toString());
      //   },
      // );

      // 4) 상태 업데이트
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

  // [6] 서버 연결 재시도 처리 관련
  // [6-1] 연결 끊어졌을 때 처리
  // -> 상태 업데이트, 녹음 상태 저장, 재연결 스케줄링
  void _handleConnectionClosed() {
    if (_isReconnecting) {
      // "재연결" 상태면 새로운 재연결 X
      debugPrint("[🐟 DEBUG 6] 이미 재연결 절차가 진행 중이므로 중복 스케줄링 방지함");
      return; // 호출 위치 [1]로 돌아감
    }

    debugPrint("[DEBUG 6] _handleConnectionClosed 메서드 실행 (재연결)");

    _isConnected = false; // 세션 연결 종료
    _isSessionReady = false; // 세션 준비 상태 종료
    _wasRecordingBeforeDisconnect = _isRecording; // 끊어지기 전 상태 저장 (녹음 중이었는지)

    if (_shouldAutoReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      // 자동 재연결, 재시도 횟수 < 3
      _scheduleReconnect(); // (호출) 2) 재연결 예약
    } else {
      // 횟수 초과로 재연결 중단
      _shouldAutoReconnect = false; // 중복 재연결 방지
      _updateStatus("[DEBUG 6] 서버 연결 종료됨");
    }
  }

  // [6-2] 재연결 예약
  void _scheduleReconnect() {
    _isReconnecting = true; // 재연결 상태 ON

    final delay =
    _reconnectDelays[_reconnectAttempts.clamp(
      0,
      _reconnectDelays.length - 1,
    )]; // clamp(최소,최댓값)
    _updateStatus("[DEBUG 6] ${delay}초 후 재연결 시도"); // 2, 6, 10초

    // 2초 뒤에 [3]으로 이동
    _reconnectTimer = Timer(
      Duration(seconds: delay),
      _attemptReconnect,
    ); // (호출) 3) 재연결 시도
  }

  // [6-3] 재연결 시도
  Future<void> _attemptReconnect() async {
    try {
      debugPrint("[🐟 DEBUG] 재연결 시작 시간 - ${DateTime.now()}");
      debugPrint("[🐟 DEBUG] _attemptReconnect 실행 - 현재 : $_reconnectAttempts");
      _reconnectAttempts++; // 재연결 시도 횟수 증가
      debugPrint(
        "[🐟 DEBUG] _attemptReconnect 실행 - 증가 후 : $_reconnectAttempts",
      );

      _updateStatus(
        "서버 연결 재시도 (${_reconnectAttempts}/${_maxReconnectAttempts})",
      );
      // (호출) [1] WebSocket 서버 연결 - 재연결 시도
      final success = await connectToServer(isRetry: true);

      // 1) 재연결 성공
      if (success) {
        _stopReconnectTimer(); // 타이머 중지
        _reconnectAttempts = 0; // 재시도 카운트 리셋 = 0
        _isReconnecting = false; // 재연결 상태 = false

        // (호출) [2] 음성 인식 세션
        await startSession(
          inputLanguages: _currentInputLanguages!, // 입력 언어 국가
          targetLanguages: _currentTargetLanguages!, // 출력 언어 국가
        );

        // 녹음 중 상태였다면 -> (호출) [3] 녹음 재개
        if (_wasRecordingBeforeDisconnect) {
          await resumeRecording();
        }
      }
      // 2) 재연결 실패
      else {
        if (_reconnectAttempts >= _maxReconnectAttempts) {
          // 최대 재시도 초과 시
          _stopReconnectTimer(); // 타이머 중지
          _shouldAutoReconnect = false; // 자동 재연결 끄기
          _isReconnecting = false; // 재연결 상태 OFF
          _handleError("서버 재연결 실패", "최대 재시도 횟수 초과");
        } else {
          // 재시도 횟수 남으면 다시 시도
          _scheduleReconnect(); // (호출) 2) 재연결 예약
        }
      }
    } catch (e) {
      debugPrint("[DEBUG] _attemptReconnect 예외 발생 - $e");
      _isReconnecting = false;
    }
  }

  // [6-4] 재연결 타이머 중지
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel(); // 타이머 객체 취소
    _reconnectTimer = null; // 타이머 객체 삭제
  }

  // [6-5] 재연결 관련 변수 초기화
  void resetReconnectState() {
    _reconnectAttempts = 0;   // 재연결 시도 횟수 0으로 초기화
    _isReconnecting = false;  // 연결 중 상태 OFF
    _stopReconnectTimer();    // 타이머 중지
    debugPrint("[🐟 DEBUG] 재연결 상태 초기화");
  }

  // [7] 연결 종료
  Future<void> disconnect() async {
    debugPrint("[DEBUG 7] disconnect 메서드 실행 (연결 종료)");
    try {
      // 1) 재연결 중지
      _shouldAutoReconnect = false; // 수동 종료 시 자동 재연결 비활성화
      _stopReconnectTimer(); // 재연결 타이머 중지
      // 2) 녹음 중지
      await stopRecording();
      // 3) WebSocket 연결 종료
      await _webSocketChannel?.sink.close();
      _webSocketChannel = null;

      _isConnected = false; // 세션 연결 종료
      _isSessionReady = false;  // 세션 준비 상태 종료
      _updateStatus("[DEBUG 7] 연결 종료 완료");
    } catch (e) {
      _handleError("[ERROR 7] 연결 종료 중 오류", e.toString());
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
  // [1] 서버 메시지 처리
  void _handleServerMessage(dynamic message) {
    debugPrint("[🐟 DEBUG] _handleServerMessage 실행");
    debugPrint("[🐟 DEBUG] 수신 시간 - ${DateTime.now()}");
    debugPrint("[🐟 DEBUG] 메시지 타입 - ${message.runtimeType}");
    debugPrint("[🐟 DEBUG] 메시지 내용 - $message");
    try {
      Map<String, dynamic> data;

      // 1) 메시지 타입 확인 (String 또는 이미 파싱된 Map)
      if (message is String) {
        debugPrint("[🐟 DEBUG] String 메시지 파싱 중 ...");
        data = jsonDecode(message); // 파싱
      } else if (message is Map<String, dynamic>) {
        debugPrint("[🐟 DEBUG] Map 메시지 수신 ...");
        data = message;
      } else {
        debugPrint("[🐟 DEBUG] 알 수 없는 메시지 형식 - ${message.runtimeType}");
        return;
      }

      // 2) 메시지 타입 저장
      final messageType = data['type'] ?? '';
      debugPrint("[🐟 DEBUG] 메시지 타입 - $messageType");

      switch (messageType) {
        case 'status':
          debugPrint("[🐟 DEBUG] Status 메시지 처리");
          _handleStatusMessage(StatusMessage.fromJson(data));
          break;
        case 'result':
          debugPrint("[🐟 DEBUG] Result 메시지 처리");
          debugPrint("[🐟 DEBUG] Result 데이터 - $data");
          _handleTranslationResult(
            SeperatedSpeechTranslationResponse.fromJson(data),
          );
          break;
        default:
          debugPrint("[🐟 ERROR] 알 수 없는 메시지 타입 - $messageType");
      }
    } catch (e) {
      debugPrint("[🐟 ERROR] 메시지 처리 오류 - $e");
      _handleError("메시지 처리 오류", e.toString());
    }
  }

  // [2] 번역 결과 처리 (SeperatedSpeechTranslationResponse) (콜백)
  void _handleTranslationResult(SeperatedSpeechTranslationResponse response) {
    debugPrint("[🐟 DEBUG] _handleTranslationResult 실행");
    debugPrint("[🐟 DEBUG] original 개수 - ${response.original.length}");
    debugPrint("[🐟 DEBUG] translations 개수 - ${response.translations.length}");

    if (response.translations.isNotEmpty && response.original.isNotEmpty) {
      // 1) 현재 번역 결과 업데이트
      _currentTranslations.clear(); // 현재 번역 초기화
      String? originalText;

      debugPrint("[🐟 DEBUG] === 번역 결과 ===");

      // stt recognizing 문장인지의 여부
      debugPrint("완전 문장 여부 : ${response.isFinal}");

      response.translations.forEach((lang, result) {
        debugPrint("[🐟 DEBUG] [$lang]: ${result.resultText}"); // 번역 결과 로그
        _currentTranslations[lang] = result.resultText;

        // 각 국가 언어 저장소에 추가
        // 저장소에 없는 나라면 List 먼저 추가
        if (_languageTextHistory[lang] == null) {
          _languageTextHistory[lang] = [];
        }

        //완전 문장일 경우에만 저장
        if (response.isFinal) {
          // 저장소에 추가
          _languageTextHistory[lang]!.add(result.resultText);
        }
      });

      // 2) 원문 자막 저장소에 추가
      if (response.isFinal) {
        response.original.forEach((lang, result) {
          debugPrint("[🐟 DEBUG] [$lang]: ${result.resultText}"); // 원문 로그
          originalText = result.resultText;
          _transcriptHistory.add(result.resultText);
        });
      }

      // 3) 번역 저장소에 추가
      if (_currentTranslations.isNotEmpty && response.isFinal) {
        _translationHistory.add(Map.from(_currentTranslations));
      }

      // 4) 콜백 호출
      debugPrint("[🐟 DEBUG] 콜백 호출 - 번역 결과 개수 ${response.translations.length}");
      onTranslationReceived?.call(
        response.translations,
        response.isFinal,
        response.original.keys.first,
      );

      // 5) 원문 저장 상태 로그 출력
      if (originalText != null) {
        debugPrint("[🐟 DEBUG] 원문 저장 - $originalText");
        debugPrint("[🐟 DEBUG] 총 원문 개수 - ${_transcriptHistory.length}");
      }
    }
  }

  // [3] 상태 메시지 처리 (StatusMessage)
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

  // [4] 마이크 권한 확인
  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  // [상태 콜백]
  // [1] 상태 업데이트 (콜백)
  void _updateStatus(String status) {
    debugPrint("Status: $status");
    onStatusUpdate?.call(status); // 콜백
  }

  // [2] 에러 (콜백)
  void _handleError(String message, String? errorCode) {
    debugPrint("Error: $message ${errorCode != null ? '($errorCode)' : ''}");
    onError?.call(message, errorCode); // 콜백
  }

  // 리소스 정리
  void dispose() {
    // 완전 종료 전 모든 저장소 내용 출력
    _printAllStoredData();
    disconnect();
  }

  // 모든 저장소 내용 출력 메서드
  void _printAllStoredData() {
    debugPrint("\n${"=" * 60}");
    debugPrint("🔚 WebSocketMultipleSTTService 완전 종료 - 저장소 데이터 출력");
    debugPrint("=" * 60);

    // 1. 기본 통계 정보
    debugPrint("\n📊 기본 통계:");
    debugPrint("  - 총 원문 개수: ${_transcriptHistory.length}개");
    debugPrint("  - 총 번역 히스토리: ${_translationHistory.length}개");
    debugPrint("  - 언어별 저장소 개수: ${_languageTextHistory.length}개 언어");
    debugPrint("  - 현재 번역 결과: ${_currentTranslations.length}개 언어");

    // 2. 현재 설정 정보
    debugPrint("\n⚙️ 현재 설정:");
    debugPrint("  - 입력 언어: ${_currentInputLanguages ?? 'None'}");
    debugPrint("  - 출력 언어: ${_currentTargetLanguages ?? 'None'}");

    // 3. 전체 원문 히스토리
    debugPrint("\n📝 전체 원문 히스토리 (${_transcriptHistory.length}개):");
    if (_transcriptHistory.isEmpty) {
      debugPrint("  (저장된 원문이 없습니다)");
    } else {
      for (int i = 0; i < _transcriptHistory.length; i++) {
        debugPrint("  [$i] ${_transcriptHistory[i]}");
      }
    }

    // 4. 언어별 텍스트 히스토리
    debugPrint("\n🌍 언어별 텍스트 저장소:");
    if (_languageTextHistory.isEmpty) {
      debugPrint("  (저장된 언어별 데이터가 없습니다)");
    } else {
      _languageTextHistory.forEach((language, textList) {
        debugPrint("  📌 $language (${textList.length}개):");
        for (int i = 0; i < textList.length; i++) {
          debugPrint("    [$i] ${textList[i]}");
        }
      });
    }

    // 5. 번역 히스토리
    debugPrint("\n🔄 번역 히스토리 (${_translationHistory.length}개):");
    if (_translationHistory.isEmpty) {
      debugPrint("  (저장된 번역 히스토리가 없습니다)");
    } else {
      for (int i = 0; i < _translationHistory.length; i++) {
        debugPrint("  [히스토리 $i]:");
        _translationHistory[i].forEach((lang, text) {
          debugPrint("    $lang: $text");
        });
      }
    }

    // 7. 전체 원문 텍스트 (연결된 형태)
    debugPrint("\n📄 전체 원문 텍스트 (LLM용):");
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

    // 8. 각 언어별 전체 텍스트
    debugPrint("\n🌐 언어별 전체 텍스트:");
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

    debugPrint("\n${"=" * 60}");
    debugPrint("🔚 데이터 출력 완료");
    debugPrint("=" * 60);
  }
}
