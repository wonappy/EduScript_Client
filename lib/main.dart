import 'package:client/providers/mode_provider.dart';
import 'package:client/screens/start_screen.dart';
import 'package:client/services/websocket_multiple_speech_service.dart';
import 'package:client/services/websocket_stt_service.dart';
import 'package:client/widgets/preview_widget/subtitle_setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/styles/colors_core.dart';

void main() {
  //runApp(const MyApp());
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
      debugShowCheckedModeBanner: true, //디버깅 모드
      title: 'EduScript',
      theme: testTheme,
      home: const StartScreen(),
    );
  }
}
