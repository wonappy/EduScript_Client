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

  List<String> resolvedLanguages();
}

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

  @override
  List<String> resolvedLanguages() {
    return WebSocketSTTService().currentTargetLanguages ?? ['ko'];
  }
}

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

  @override
  List<String> resolvedLanguages() {
    return WebSocketMultipleSTTService().currentTargetLanguages ?? ['ko'];
  }
}


  Future<Map<String, dynamic>?> _postToServer(Map<String, dynamic> body, String processingMode,) async {
  try {
    final mode = body['processing_mode'] ?? processingMode;
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
