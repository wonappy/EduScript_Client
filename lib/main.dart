import 'package:client/screens/preview_screen.dart';
import 'package:flutter/material.dart';
import 'core/styles/colors_core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true, //디버깅 모드
      title: 'EduScript',
      theme: testTheme,
      home: const PreviewScreen(),
    );
  }
}
