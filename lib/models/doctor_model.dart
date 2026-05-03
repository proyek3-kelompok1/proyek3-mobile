class DoctorModel {
  final int id;
  final String name;
  final String specialization;
  final String? schedule;
  final String? photo;
  final String? photoUrl;
  final String? description;
  final double rating;
  final int queue;
  final bool isOnline;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialization,
    this.schedule,
    this.photo,
    this.photoUrl,
    this.description,
    required this.rating,
    required this.queue,
    this.isOnline = false,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'] ?? json['specialty'] ?? '',
      schedule: json['schedule'],
      photo: json['photo'],
      photoUrl: json['photo_url'],
      description: json['description'],
      rating: (json['rating'] ?? 0).toDouble(),
      queue: json['queue'] ?? 0,
      isOnline: json['is_online'] == 1 || json['is_online'] == true || json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}
