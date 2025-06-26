// [models/multiple_config_message_model.dart]
/// 다중인식 언어 설정 DTO 모델
/// [1] 언어 설정 (Request)
class MultipleConfigMessage {
  final String type; // 타입(setting)
  final List<String> inputLanguages; // 입력 언어 (국가)
  final List<String> targetLanguages; // 번역할 언어 (국가)

  MultipleConfigMessage({
    this.type = "setting",
    required this.inputLanguages,
    required this.targetLanguages,
  });

  // JSON으로 매핑 -> 전송
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'input_language': inputLanguages,
      'target_languages': targetLanguages,
    };
  }

  @override
  String toString() {
    String result =
        'MultipleConfigMessage(type: $type, '
        'inputLanguages: "$inputLanguages",'
        'targetLanguages: "$targetLanguages" )';

    return result;
  }
}
