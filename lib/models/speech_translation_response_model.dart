// [models/speech_translation_response_model.dart]
/// DTO 모델
/// [3]-1 번역 응답 (Response)
class SpeechTranslationResponse {
  final String type; // 타입
  final Map<String, TranslationResult> translations; // 번역 결과

  SpeechTranslationResponse({this.type = "result", required this.translations});

  factory SpeechTranslationResponse.fromJson(Map<String, dynamic> json) {
    Map<String, TranslationResult> translationMap = {};

    if (json['translations'] != null) {
      Map<String, dynamic> translationsJson = json['translations'];
      translationsJson.forEach((key, value) {
        translationMap[key] = TranslationResult.fromJson(value);
      });
    }

    return SpeechTranslationResponse(
      type: json['type'] ?? 'result',
      translations: translationMap,
    );
  }
}

/// [3]-2 번역 응답 (Response)
class SeperatedSpeechTranslationResponse {
  final String type; // 타입
  final Map<String, TranslationResult> original; // 원문
  final Map<String, TranslationResult> translations; // 번역 결과

  SeperatedSpeechTranslationResponse({
    this.type = "result",
    required this.original,
    required this.translations,
  });

  factory SeperatedSpeechTranslationResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    Map<String, TranslationResult> originalMap = {};
    Map<String, TranslationResult> translationMap = {};

    if (json['original'] != null) {
      Map<String, dynamic> originalJson = json['original'];
      originalJson.forEach((key, value) {
        originalMap[key] = TranslationResult.fromJson(value);
      });
    }

    if (json['translations'] != null) {
      Map<String, dynamic> translationsJson = json['translations'];
      translationsJson.forEach((key, value) {
        translationMap[key] = TranslationResult.fromJson(value);
      });
    }

    return SeperatedSpeechTranslationResponse(
      type: json['type'] ?? 'result',
      original: originalMap,
      translations: translationMap,
    );
  }
}

// [4] 번역 결과 모델 (SpeechTranslationResponse)
class TranslationResult {
  final String targetLang; // 번역한 언어 (국가)
  final String resultText; // 번역 결과

  TranslationResult({required this.targetLang, required this.resultText});

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      targetLang: json['target_lang'] ?? '', // null일 때 빈문자열로 표시
      resultText: json['result_text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'target_lang': targetLang, 'result_text': resultText};
  }
}
