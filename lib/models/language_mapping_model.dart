//자막 출력 모델
class LanguageMappingModel {
  final String displayName;
  final String speechCode;
  final String translationCode;
  final String previewText;

  LanguageMappingModel({
    required this.displayName,
    required this.speechCode,
    required this.translationCode,
    required this.previewText,
  });

  @override
  String toString() {
    String result =
        'LanguageMappingModel(displayName: $displayName, '
        'speechCode: "$speechCode", '
        'translationCode: "$translationCode",  '
        'previewText: "$previewText", )';

    return result;
  }
}
