// [models/status_message_model.dart]
/// DTO 모델
/// [2] 상태 응답 (Response)
class StatusMessage {
  final String type;        // 타입
  final String status;      // 상태 (ready, error, disconnected)
  final String? message;    // 메시지 (nullable)
  final String? errorCode;  // 에러 코드 (nullable)

  StatusMessage({
    required this.type,
    required this.status,
    this.message,
    this.errorCode,
  });

  factory StatusMessage.fromJson(Map<String, dynamic> json) {
    return StatusMessage(
      type: json['type'] ?? 'status',
      status: json['status'] ?? '',
      message: json['message'],
      errorCode: json['error_code'],
    );
  }
}