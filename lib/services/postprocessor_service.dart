import 'dart:convert';
import 'dart:async';
import 'package:client/core/global_core.dart';
import 'package:flutter/foundation.dart';
import 'package:client/services/websocket_single_speech_service.dart';
import 'package:client/services/websocket_multiple_speech_service.dart';
import 'package:http/http.dart' as http;
import 'package:client/core/enum_core.dart';

// end_lecture_and_save_screen 으로 넘길때 postprocessor-service로 넘김
class PostProcessorService {
  // 텍스트 정제 메소드 (통합)
  Future<Map<String, dynamic>?> refineText({
    required Mode mode,
    required String fullText,
    required String fileName,
    required String fileFormat,
    bool enableSummarize = false,
    bool enableKeypoints = false,
    bool enableScript = false,
    bool enableNote = false,
  }) async {
    final bool isConference= mode == Mode.conference;

    // 1. 모드에 따른 동적 설정
    final String endpoint = isConference
        ? "/api/routes/language/refinement/conference"
        : "/api/routes/language/refinement";

    final List<String> languages = isConference
        ? (WebSocketMultipleSpeechService().currentTargetLanguages ?? ['ko'])
        : (WebSocketSingleSpeechService().currentTargetLanguages ?? ['ko']);
    
    final Map<String, dynamic> body = {
      "full_text": fullText,
      "fileName": fileName,
      "fileFormat": fileFormat,
      "language_list": languages,
      "processing_mode": mode.apiValue,

      if (!isConference) ...{
        "enable_refine": true,
        "enable_summarize": enableSummarize,
        "enable_keypoints": enableKeypoints,
      } else ...{
        "enable_script": enableScript,
        "enable_note": enableNote,
      },
    };    
    
    return await _postToServer(endpoint, body);
  }
}

  // 서버에 정제 POST 요청을 보내는 메소드
Future<Map<String, dynamic>?> _postToServer(String endpoint,
  Map<String, dynamic> body
) async {
  try {
    final url = Uri.parse("${GlobalCore.httpBaseUrl.trim()}$endpoint");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint("[ERROR] 서버 오류 - ${response.body}");
      return null;
    }
  } catch (e) {
    debugPrint("[ERROR] 네트워크 오류 - $e");
    return null;
  }
}