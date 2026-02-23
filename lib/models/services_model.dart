class ServiceModel {
  final int id;
  final String name;
  final String description;
  final String details;
  final String icon;
  final String formattedPrice;
  final String formattedDuration;
  final String serviceType;
  final String serviceTypeLabel;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.details,
    required this.icon,
    required this.formattedPrice,
    required this.formattedDuration,
    required this.serviceType,
    required this.serviceTypeLabel,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      details: json['details'],
      icon: json['icon'],
      formattedPrice: json['formatted_price'],
      formattedDuration: json['formatted_duration'],
      serviceType: json['service_type'],
      serviceTypeLabel: json['service_type_label'],
    );
  }
}
