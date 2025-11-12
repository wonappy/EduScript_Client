import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// IP 설정 config
class GlobalCore {
  // 기본 IP (localhost)
  static String serverBaseUrl = "ws://192.168.0.149:8000"; // 서버 엔드포인트
  static String httpBaseUrl = "http://192.168.0.149:8000"; // 서버 엔드포인트
  static String configPath = "";
  static Future<void> loadConfig() async {
    if (kIsWeb) return; // 실제 실행 중인 경우에만 파일 접근 시도
    if (kReleaseMode) {
      // exe 파일로 실행할 경우
      configPath = 'config.json';
    } else {
      // IDE로 실행할 경우
      configPath =
          r"C:\Users\user\Documents\GitHub\EduScript_Client\lib\config.json";
    }

    try {
      final file = File(configPath); // <- exe와 같은 폴더
      if (!await file.exists()) {
        debugPrint('config.json 파일이 없습니다. localhost로 실행합니다.');
        return;
      }

      final contents = await file.readAsString(); // config.json 파일 불러오기
      final json = jsonDecode(contents);

      // IP 설정 파일에서 값을 읽어와 변수에 할당
      String? ip = json['server_ip'];
      String? port = json['server_port']?.toString();

      // IP 설정 파일에서 IP:PORT 읽어오기
      if (ip != null && port != null) {
        serverBaseUrl = "ws://$ip:$port";
        httpBaseUrl = "http://$ip:$port";
        debugPrint('Config loaded: HTTP: $httpBaseUrl, WS: $serverBaseUrl');
      } else {
        // [예외] 파일에 ip, port가 존재하지 않을 때 -> 기본 IP로 실행
        debugPrint(
          '"server_ip" 또는 "server_port"가 존재하지 않습니다.  localhost로 실행합니다.',
        );
      }
    } catch (e) {
      // [예외]
      debugPrint('config.json 파일을 불러오지 못 했습니다. Error: $e');
    }
  }
}

//함수
// /// 반응형 폰트 크기 계산
// double getResponsiveFontSize(double screenWidth) {
//   // 기본 폰트 크기를 화면 너비에 비례하여 계산
//   double baseFontSize = screenWidth * 0.015;
//
//   // 최소, 최대 폰트 크기 제한
//   return baseFontSize.clamp(12.0, 20.0);
// }
