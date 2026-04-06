class ConsultationModel {
  final int id;
  final int doctorId;
  final String userName;
  final String userPhone;
  final String status;
  final String? createdAt;

  ConsultationModel({
    required this.id,
    required this.doctorId,
    required this.userName,
    required this.userPhone,
    required this.status,
    this.createdAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'],
      doctorId: json['doctor_id'],
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'],
    );
  }
}
