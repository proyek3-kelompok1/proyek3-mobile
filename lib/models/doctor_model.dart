class DoctorModel {
  final int id;
  final String name;
  final String specialty;
  final String? photo;
  final double rating;
  final int queue;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.photo,
    required this.rating,
    required this.queue,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'],
      name: json['name'],
      specialty: json['specialty'] ?? '',
      photo: json['photo'],
      rating: (json['rating'] ?? 0).toDouble(),
      queue: json['queue'] ?? 0,
    );
  }
}
