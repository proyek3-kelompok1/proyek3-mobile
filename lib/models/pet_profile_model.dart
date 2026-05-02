class PetProfileModel {
  final int id;
  final String name;
  final String type;
  final String? breed;
  final int? ageMonths;
  final double? weightKg;
  final String? photoUrl;
  final String? healthHistoryNotes;
  final bool needsVaccine;
  final bool needsGrooming;
  final String ageFormatted;
  final String healthStatus;
  final List<String> smartRecommendations;

  PetProfileModel({
    required this.id,
    required this.name,
    required this.type,
    this.breed,
    this.ageMonths,
    this.weightKg,
    this.photoUrl,
    this.healthHistoryNotes,
    required this.needsVaccine,
    required this.needsGrooming,
    required this.ageFormatted,
    required this.healthStatus,
    this.smartRecommendations = const [],
  });

  factory PetProfileModel.fromJson(Map<String, dynamic> json) {
    return PetProfileModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      breed: json['breed'],
      ageMonths: json['age_months'],
      weightKg: json['weight_kg'] != null ? double.parse(json['weight_kg'].toString()) : null,
      photoUrl: json['photo_url'],
      healthHistoryNotes: json['health_history_notes'],
      needsVaccine: json['needs_vaccine'] ?? false,
      needsGrooming: json['needs_grooming'] ?? false,
      ageFormatted: json['age_formatted'] ?? 'Umur tidak diketahui',
      healthStatus: json['health_status'] ?? 'Sehat',
      smartRecommendations: json['smart_recommendations'] != null 
          ? List<String>.from(json['smart_recommendations']) 
          : [],
    );
  }
}
