//변수

/// 반응형 폰트 크기 계산
double getResponsiveFontSize(double screenWidth) {
  // 기본 폰트 크기를 화면 너비에 비례하여 계산
  double baseFontSize = screenWidth * 0.015;

  // 최소, 최대 폰트 크기 제한
  return baseFontSize.clamp(12.0, 24.0);
}
