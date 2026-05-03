import '../core/constants/api_constants.dart';

class MessageModel {
  final int id;
  final String senderType; // 'user' or 'doctor'
  final String message;
  final String? createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderType,
    required this.message,
    this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderType: json['sender_type'] ?? 'user',
      message: json['message'] ?? '',
      createdAt: json['created_at'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_type': senderType,
      'message': message,
    };
  }
}
