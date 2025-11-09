import 'package:client/providers/mode_provider.dart';
import 'package:client/screens/start_screen.dart';
import 'package:client/services/websocket_multiple_speech_service.dart';
import 'package:client/services/websocket_stt_service.dart';
import 'package:client/widgets/preview_widget/subtitle_setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'core/global_core.dart';

void main() async {

  //<최소 창 크기 제한>
  WidgetsFlutterBinding.ensureInitialized();

  // [0] GlobalCore 할당
  await GlobalCore.loadConfig();

  //[1] 창 관리자 초기화
  await windowManager.ensureInitialized();
  //[2] 창 옵션 지정
  WindowOptions windowOptions = WindowOptions(
    size: const Size(1180, 620), //초기 창 크기
    minimumSize: Size(1180, 620), //최소 크기
    //maximumSize: Size(1300, 750), //최대 크기
    center: true, // 화면 중간에서 start
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: "EduScript",
  );

  //[3] 창 옵션 적용 < 화면 준비된 이후
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    //windowManager.setMaximizable(false);
  });



  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SubtitleSettingsProvider()),
        ChangeNotifierProvider(create: (context) => ModeProvider()),
        Provider<WebSocketSTTService>(create: (_) => WebSocketSTTService()),
        Provider<WebSocketMultipleSTTService>(
          create: (_) => WebSocketMultipleSTTService(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //디버깅 모드
      title: 'EduScript',
      //theme: testTheme,
      home: const StartScreen(),
    );
  }
}
