import 'dart:convert';
import 'dart:async';
import 'package:client/core/global_core.dart';
import 'package:flutter/foundation.dart';
import 'package:client/services/postprocessor_service.dart';
import 'package:client/services/websocket_stt_service.dart';
import 'package:client/services/websocket_multiple_speech_service.dart';
import 'package:client/screens/end_lecture_and_save_screen.dart';
import 'package:http/http.dart' as http;
import 'package:client/core/enum_core.dart';

// end_lecture_and_save_screen 으로 넘길때 _llm-service로 넘김
abstract class BasePostProcessorService {
  Future<Map<String, dynamic>?> refineText({
    required String fullText,
    required String fileName,
    required String fileFormat,
    bool enableSummarize,
    bool enableKeypoints,
    bool enableScript,
    bool enableNote,
    });

  // 언어 목록을 반환하는 메소드 (ko, en)
  List<String> resolvedLanguages();
}

// 강의용 정제 요청 서비스
class LecturePostProcessorService implements BasePostProcessorService {
  @override
  Future<Map<String, dynamic>?> refineText({
    required String fullText,
    required String fileName,
    required String fileFormat,
    bool enableSummarize = false,
    bool enableKeypoints = false,
    bool enableScript = false,
    bool enableNote = false,
  }) async {
    final body = {
      "full_text": fullText,
      "fileName": fileName,
      "fileFormat": fileFormat,
      "language_list": resolvedLanguages(),
      "enable_refine": true,
      "enable_summarize": enableSummarize,
      "enable_keypoints": enableKeypoints,
      "processing_mode": "lecture"
    };

    return await _postToServer(body, "lecture");
  }

  // 자녀 클래스에서 구현된 언어 목록을 반환
  @override
  List<String> resolvedLanguages() {
    return WebSocketSTTService().currentTargetLanguages ?? ['ko'];
  }
}

// 회의용 정제 요청 서비스
class ConferencePostProcessorService implements BasePostProcessorService {
  @override
  Future<Map<String, dynamic>?> refineText({
    required String fullText,
    required String fileName,
    required String fileFormat,
    bool enableSummarize = false, // note
    bool enableKeypoints = false, // 무시됨
    bool enableScript = true,
    bool enableNote = false,
  }) async {
    final body = {
      "full_text": fullText,
      "fileName": fileName,
      "fileFormat": fileFormat,
      "language_list": resolvedLanguages(),
      "enable_script": enableScript,
      "enable_note": enableNote,
      "processing_mode": "conference"
    };

    return await _postToServer(body, "conference");
  }

  // 자녀 클래스에서 구현된 언어 목록을 반환
  @override
  List<String> resolvedLanguages() {
    return WebSocketMultipleSTTService().currentTargetLanguages ?? ['ko'];
  }
}

  // 서버에 정제 POST 요청을 보내는 메소드
  Future<Map<String, dynamic>?> _postToServer(Map<String, dynamic> body, String processingMode,) async {
  try {
    final mode = body['processing_mode'] ?? processingMode;
    // 회의면 위, 강의면 아래
    final endpoint = mode == 'conference'
        ? "/api/routes/language/refinement/conference"
        : "/api/routes/language/refinement";

    final response = await http.post(
      Uri.parse("$httpBaseUrl$endpoint"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint("❌ 서버 오류: ${response.body}");
      return null;
    }
  } catch (e) {
    debugPrint("❌ 네트워크 오류: $e");
    return null;
  }
}
