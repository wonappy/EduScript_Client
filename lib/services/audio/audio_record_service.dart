//audio_record_service.dart
//오디오 연결 권한 확보, 오디오 연결 상태 관리
//singleton class

import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:record/record.dart'; // 마이크 오디오 녹음
import 'package:permission_handler/permission_handler.dart'; // 마이크 권한 관리
import 'package:wakelock_plus/wakelock_plus.dart'; // 절전 모드 진입 방지

class AudioRecordService {
  // [변수]
  final AudioRecorder _audioRecorder = AudioRecorder(); // 오디오 캡쳐 객체
  bool _isRecording = false; // 현재 마이크 녹음 상태

  // [Getter]
  bool get isRecording => _isRecording;

  // [싱글톤 패턴]
  static final AudioRecordService _instance = AudioRecordService._internal();
  factory AudioRecordService() => _instance;
  AudioRecordService._internal();

  // 마이크 권한 확인
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  // 녹음 시작 (only 음성 스트림 반환)
  Future<Stream<Uint8List>?> startRecording() async {
    // 중복 녹음 방지 (마이크 리소스 하나만 사용)
    if (isRecording) {
      debugPrint("[DEBUG] 이미 녹음 중입니다. 새 녹음을 시작할 수 없습니다.");
      return null;
    }

    try {
      // 마이크 권한 확인
      if (!await checkMicrophonePermission()) {
        debugPrint("[ERROR] 세션 시작 실패 : 마이크 권한이 필요합니다");
        return null;
      }

      // 오디오 스트림 생성
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits, // PCM 16bit 포맷
          sampleRate: 16000, // 16kHz 샘플레이트
          numChannels: 1, // 모노 채널
        ),
      );

      // 상태 업데이트
      await WakelockPlus.enable(); // 절전 모드 방지 활성화
      _isRecording = true;
      debugPrint("[DEBUG] 마이크 음성 스트림 생성 완료");

      // 스트림 반환
      return stream;
    } catch (e) {
      debugPrint("[ERROR] 녹음 시작 실패 : $e");
      return null;
    }
  }

  // 녹음 중지
  Future<void> stopRecording() async {
    if (!isRecording) {
      debugPrint("[DEBUG] 녹음 중인 스트림이 없습니다. 중지할 스트림이 존재하지 않습니다.");
      return;
    }

    try {
      // 오디오 녹음 중지
      await _audioRecorder.stop();
      debugPrint("[DEBUG] 마이크 하드웨어 중지 완료");
    } catch (e) {
      debugPrint("[ERROR] 녹음 중지 실패 : $e");
    } finally {
      // 상태 업데이트
      await WakelockPlus.disable(); // 절전 모드 진입 방지 비활성화
      _isRecording = false;
      debugPrint("[DEBUG] 오디오 상태 변수 초기화 완료");
    }
  }
}
