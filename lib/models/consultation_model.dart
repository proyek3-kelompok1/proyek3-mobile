class ConsultationModel {
  final int id;
  final int doctorId;
  final String userName;
  final String? userAvatar;
  final String? doctorName;
  final String status;
  final String? lastMessage;
  final int unreadCount;
  final String? updatedAt;
  final bool isOnline;
  final String? lastMessageStatus; // 'sent' or 'read'

  ConsultationModel({
    required this.id,
    required this.doctorId,
    required this.userName,
    this.userAvatar,
    this.doctorName,
    required this.status,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
    this.isOnline = false,
    this.lastMessageStatus,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    // If we have 'doctor' and it has 'user', that's probably the doctor's info for a patient
    final doctorUser = json['doctor']?['user'];
    final patientUser = json['user'];

    return ConsultationModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      userName: patientUser?['name'] ?? doctorUser?['name'] ?? json['user_name'] ?? '',
      userAvatar: patientUser?['avatar_url'] ?? patientUser?['avatar'] ?? doctorUser?['avatar_url'] ?? doctorUser?['avatar'],
      doctorName: json['doctor']?['name'],
      status: json['status'] ?? 'active',
      lastMessage: json['last_message']?['message'],
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: json['updated_at'],
      isOnline: json['is_online'] ?? false,
      lastMessageStatus: json['last_message_status'],
    );
  }
}
