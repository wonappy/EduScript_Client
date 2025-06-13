//색상
import 'package:flutter/material.dart';

//기본 테마
final ThemeData testTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.black,
    brightness: Brightness.dark,
  ),
  iconTheme: IconThemeData(color: Colors.red, size: 60),
  shadowColor: Colors.black.withValues(alpha: 0.1),
);

//배경 색상
const backgroundcolorOnWord = Color(0xFF808080);

//텍스트 색상
const previewOnWord = Colors.white;
