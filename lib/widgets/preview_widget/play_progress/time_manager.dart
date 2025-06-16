// lib/core/timer_manager.dart
// 타이머만 관리하는 클래스
import 'dart:async';
import 'package:flutter/material.dart';

//전역 타이머 상태 (사용자가 UI 줄일 때 재생시간 초기화 방지)
Timer? _globaltimer; //타이머 객체
bool _isGlobalPlaying = false; //재생 상태
int _globalElapsedSeconds = 0; //경과 시간 (초 단위)
DateTime? _globalStartTime; //타이머 시작 시간
final List<VoidCallback> _globalTimerListeners = []; //타이머 리스너 목록

class TimerManager {
  static bool get isPlaying => _isGlobalPlaying; // 현재 재생 상태
  static int get elapsedSeconds => _globalElapsedSeconds; 

  static String get formattedTime {
    int hours = _globalElapsedSeconds ~/ 3600;
    int minutes = (_globalElapsedSeconds % 3600) ~/ 60;
    int seconds = _globalElapsedSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:"
           "${minutes.toString().padLeft(2, '0')}:"
           "${seconds.toString().padLeft(2, '0')}";
  }

  static void addListener(VoidCallback listener){
    _globalTimerListeners.add(listener);
  }

  static void removeListener(VoidCallback listener){
    _globalTimerListeners.remove(listener);
  }

  static void _notifyListeners() {
    for(var listener in _globalTimerListeners) {
      listener();
    }
  }

  static void start() {
    if (!_isGlobalPlaying) {
      _isGlobalPlaying = true;
      _globalStartTime = DateTime.now().subtract(Duration(seconds: _globalElapsedSeconds));
      _startTimer();
      _notifyListeners();
    }
  }

  static void pause() {
    if (_isGlobalPlaying) {
      _isGlobalPlaying = false;
      _stopTimer();
      _notifyListeners();
    }
  }

  static void reset() {
    _stopTimer();
    _globalElapsedSeconds = 0;
    _isGlobalPlaying = false;
    _globalStartTime = null;
    _notifyListeners();
  }

  static void _startTimer() {
    _globaltimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGlobalPlaying && _globalStartTime != null) {
        _globalElapsedSeconds = DateTime.now().difference(_globalStartTime!).inSeconds;
        _notifyListeners();
      }
    });
  }

  static void _stopTimer() {
    _globaltimer?.cancel();
    _globaltimer = null;
  }
}