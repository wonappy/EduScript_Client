//자막 출력 모델
class SubtitlesModel {
  String country; //단어 id
  String subtitle; //영어 단어

  SubtitlesModel({required this.country, required this.subtitle});

  //나만의 단어장 api용
  SubtitlesModel.fromJson(Map<String, dynamic> json)
    : country = json['country'],
      subtitle = json['subtitle'];

  @override
  String toString() {
    String result =
        'SubtitlesModel(country: $country, '
        'subtitle: "$subtitle", )';

    return result;
  }
}
