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
  final double? price;
  final int? durationMinutes;

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
    this.price,
    this.durationMinutes,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Handle price — bisa dari formatted_price atau generate dari price
    String fmtPrice = json['formatted_price'] ?? '';
    if (fmtPrice.isEmpty && json['price'] != null) {
      final p = (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as num).toDouble();
      if (p > 0) {
        fmtPrice = 'Rp ${_formatNumber(p.toInt())}';
      } else {
        fmtPrice = 'Konsultasi';
      }
    }
    if (fmtPrice.isEmpty) fmtPrice = 'Konsultasi';

    // Handle duration — bisa dari formatted_duration atau generate dari duration_minutes
    String fmtDuration = json['formatted_duration'] ?? '';
    if (fmtDuration.isEmpty && json['duration_minutes'] != null) {
      final mins = json['duration_minutes'] as int;
      if (mins >= 60) {
        final hours = mins ~/ 60;
        final remainder = mins % 60;
        fmtDuration = remainder > 0 ? '$hours jam $remainder menit' : '$hours jam';
      } else {
        fmtDuration = '$mins menit';
      }
    }
    if (fmtDuration.isEmpty) fmtDuration = '-';

    // Handle service_type_label
    final sType = json['service_type'] ?? 'general';
    String sLabel = json['service_type_label'] ?? '';
    if (sLabel.isEmpty) {
      const types = {
        'general': 'Umum',
        'vaccination': 'Vaksinasi',
        'surgery': 'Operasi',
        'grooming': 'Grooming',
        'dental': 'Perawatan Gigi',
        'laboratory': 'Laboratorium',
        'inpatient': 'Rawat Inap',
        'emergency': 'Darurat',
        'vaksinasi': 'Vaksinasi',
        'konsultasi_umum': 'Umum',
        'perawatan_gigi': 'Perawatan Gigi',
        'pemeriksaan_darah': 'Laboratorium',
        'sterilisasi': 'Operasi',
      };
      sLabel = types[sType] ?? sType;
    }

    return ServiceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      details: json['details'] ?? json['description'] ?? '',
      icon: json['icon'] ?? 'medical_services',
      formattedPrice: fmtPrice,
      formattedDuration: fmtDuration,
      serviceType: sType,
      serviceTypeLabel: sLabel,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      durationMinutes: json['duration_minutes'] as int?,
    );
  }

  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
