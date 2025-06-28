// [models/config_message_model.dart]
/// DTO 모델
/// [1]-1 일반 언어 설정 (Request)
class ConfigMessage {
  final String type; // 타입(setting)
  final String inputLanguage; // 입력 언어 (국가)
  final List<String> targetLanguages; // 번역할 언어 (국가)

  ConfigMessage({
    this.type = "setting",
    required this.inputLanguage,
    required this.targetLanguages,
  });

  // JSON으로 매핑 -> 전송
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'input_language': inputLanguage,
      'target_languages': targetLanguages,
    };
  }
}
