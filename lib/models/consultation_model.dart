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
  final String? typingAt; // ISO timestamp of when the other party last typed
  final String? doctorAvatar;

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
    this.typingAt,
    this.doctorAvatar,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    final doctorData = json['doctor'];
    final doctorUser = doctorData?['user'];
    final patientUser = json['user'];

    // Determine online status from multiple possible fields
    final bool online = json['is_online'] == 1 ||
        json['is_online'] == true ||
        json['is_active'] == 1 ||
        json['is_active'] == true ||
        doctorData?['is_online'] == 1 ||
        doctorData?['is_online'] == true ||
        doctorUser?['is_online'] == 1 ||
        doctorUser?['is_online'] == true;

    // Doctor avatar: try multiple paths
    final String? docAvatar = doctorData?['photo_url'] ??
        doctorData?['avatar_url'] ??
        doctorUser?['avatar_url'] ??
        doctorUser?['avatar'];

    return ConsultationModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      userName: patientUser?['name'] ?? doctorUser?['name'] ?? json['user_name'] ?? '',
      userAvatar: patientUser?['avatar_url'] ??
          patientUser?['avatar'] ??
          doctorUser?['avatar_url'] ??
          doctorUser?['avatar'],
      doctorName: doctorData?['name'],
      doctorAvatar: docAvatar,
      status: json['status'] ?? 'active',
      lastMessage: json['last_message']?['message'] ?? json['last_message'],
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: json['updated_at'],
      isOnline: online,
      lastMessageStatus: json['last_message_status'],
      typingAt: json['typing_at'],
    );
  }

  /// Whether the other party is currently typing (within the last 5 seconds)
  bool get isTyping {
    if (typingAt == null) return false;
    try {
      final dt = DateTime.parse(typingAt!).toUtc();
      return DateTime.now().toUtc().difference(dt).inSeconds < 5;
    } catch (_) {
      return false;
    }
  }
}
