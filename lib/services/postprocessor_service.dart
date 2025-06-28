import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:client/services/postprocessor_service.dart';
import 'package:client/services/websocket_stt_service.dart';
import 'package:client/screens/end_lecture_and_save_screen.dart';
import 'package:http/http.dart' as http;

class PostProcessorService {
  // http 통신 설정
  final String _serverBaseUrl = "http://192.168.1.2:8000"; // 서버 엔드포인트
  final String _serverEndpoint = "/api/routes/language/refinement";

  bool _isProcessing = false;
  String? _lastRequest;
  String _fileFormat = 'txt';
  Map<String, dynamic>? _lastResponse;

  // [요청 설정]
  bool _enableRefine = true;
  bool _enableSummarize = false;
  bool _enableKeypoints = false;

  // [싱글톤 패턴]
  static final PostProcessorService _instance =
      PostProcessorService._internal();
  factory PostProcessorService() => _instance;
  PostProcessorService._internal();

  // [Getter]
  bool get isProcessing => _isProcessing;
  String? get lastRequest => _lastRequest;
  String get fileFormat => _fileFormat;
  Map<String, dynamic>? get lastResponse => _lastResponse;
  bool get enableRefine => _enableRefine;
  bool get enableSummarize => _enableSummarize;
  bool get enableKeypoints => _enableKeypoints;

  // [설정 변경]
  void updateSettings({
    bool? enableRefine,
    bool? enableSummarize,
    bool? enableKeypoints,
  }) {
    if (enableRefine != null) _enableRefine = enableRefine;
    if (enableSummarize != null) _enableSummarize = enableSummarize;
    if (enableKeypoints != null) _enableKeypoints = enableKeypoints;
  }

  // [메인 기능] STT 서비스와 연동하여 정제 요청
  Future<Map<String, dynamic>?> processSTTTranscript({
    bool? enableSummarize,
    bool? enableKeypoints,
  }) async {
    final sttService = WebSocketSTTService();
    final fullText = sttService.fullTranscriptText;

    if (fullText.trim().isEmpty) {
      debugPrint("[LLM] 오류: STT 서비스에 정제할 텍스트가 없습니다");
      return null;
    }

    return await refineText(
      fullText: fullText,
      enableSummarize: enableSummarize,
      enableKeypoints: enableKeypoints,
    );
  }

  // [핵심 기능] 텍스트 정제 요청
  Future<Map<String, dynamic>?> refineText({
    required String fullText,
    bool? enableSummarize,
    bool? enableKeypoints,
    String fileFormat = 'txt', // 파일 형식 (기본값은 txt)
  }) async {
    // 중복 요청 방지
    if (_isProcessing) {
      return _lastResponse; // 마지막 결과 반환
    }

    // 입력 검증
    if (fullText.trim().isEmpty) {
      return null;
    }

    try {
      _isProcessing = true;
      _lastRequest = fullText;

      debugPrint("[LLM] 정제 요청 시작 (${fullText.length}자)");

      // 요청 데이터 생성
      final requestBody = {
        'full_text': fullText,
        'fileFormat': fileFormat.replaceAll('.', ''),
        'enable_refine': _enableRefine,
        'enable_summarize': enableSummarize ?? _enableSummarize,
        'enable_keypoints': enableKeypoints ?? _enableKeypoints,
      };

      debugPrint("요청 데이터 원문 전문 : $fullText");
      debugPrint("[LLM] 서버로 데이터 전송 중...");

      // HTTP POST 요청
      final response = await http.post(
        Uri.parse('$_serverBaseUrl$_serverEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // 응답 처리
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        _lastResponse = responseData;

        debugPrint("[LLM] ✅ 정제 완료!");
        //_printResults(responseData); // 결과 출력

        return responseData;
      } else {
        final errorMsg = "서버 오류 (${response.statusCode}): ${response.body}";
        debugPrint("[LLM] ❌ $errorMsg");
        return null;
      }
    } on TimeoutException {
      debugPrint("[LLM] ❌ 요청 타임아웃 (30초 초과)");
      return null;
    } catch (e) {
      debugPrint("[LLM] ❌ 네트워크 오류: $e");
      return null;
    } finally {
      _isProcessing = false;
    }
  }
}
