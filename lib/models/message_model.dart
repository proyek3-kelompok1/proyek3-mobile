class MessageModel {
  final int id;
  final String senderType; // 'user' or 'doctor'
  final String message;
  final String? createdAt;

  MessageModel({
    required this.id,
    required this.senderType,
    required this.message,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderType: json['sender_type'] ?? 'user',
      message: json['message'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_type': senderType,
      'message': message,
    };
  }
}
