class MedicalRecordModel {
  final int? id;
  final String kodeRekamMedis;
  final String namaHewan;
  final String jenisHewan;
  final String diagnosa;
  final String? tindakan;
  final String? resepObat;
  final String? catatanDokter;
  final String dokter;
  final String tanggalPemeriksaan;
  final String? kunjunganBerikutnya;
  final String status;

  MedicalRecordModel({
    this.id,
    required this.kodeRekamMedis,
    required this.namaHewan,
    required this.jenisHewan,
    required this.diagnosa,
    this.tindakan,
    this.resepObat,
    this.catatanDokter,
    required this.dokter,
    required this.tanggalPemeriksaan,
    this.kunjunganBerikutnya,
    required this.status,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id'],
      kodeRekamMedis: json['kode_rekam_medis'] ?? '',
      namaHewan: json['nama_hewan'] ?? '',
      jenisHewan: json['jenis_hewan'] ?? '',
      diagnosa: json['diagnosa'] ?? '',
      tindakan: json['tindakan'],
      resepObat: json['resep_obat'],
      catatanDokter: json['catatan_dokter'],
      dokter: json['dokter'] ?? '',
      tanggalPemeriksaan: json['tanggal_pemeriksaan'] ?? '',
      kunjunganBerikutnya: json['kunjungan_berikutnya'],
      status: json['status'] ?? '',
    );
  }
}

class BookingModel {
  final String bookingCode;
  final int nomorAntrian;
  final String serviceName;
  final String doctorName;
  final String bookingDate;
  final String bookingTime;
  final int totalPrice;
  final String? namaHewan;
  final String? jenisHewan;
  final String? status;
  final bool hasMedicalRecord;
  final List<MedicalRecordModel> medicalRecords;

  BookingModel({
    required this.bookingCode,
    required this.nomorAntrian,
    required this.serviceName,
    required this.doctorName,
    required this.bookingDate,
    required this.bookingTime,
    required this.totalPrice,
    this.namaHewan,
    this.jenisHewan,
    this.status,
    this.hasMedicalRecord = false,
    this.medicalRecords = const [],
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    var mrList = json['medical_records'] as List? ?? [];
    List<MedicalRecordModel> mrs = mrList.map((i) => MedicalRecordModel.fromJson(i)).toList();

    return BookingModel(
      bookingCode: json['booking_code'] ?? '',
      nomorAntrian: json['nomor_antrian'] ?? 0,
      serviceName: json['service_name'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      bookingTime: json['booking_time'] ?? '',
      totalPrice: json['total_price'] != null ? double.tryParse(json['total_price'].toString())?.toInt() ?? 0 : 0,
      namaHewan: json['nama_hewan'],
      jenisHewan: json['jenis_hewan'],
      status: json['status'],
      hasMedicalRecord: json['has_medical_record'] ?? false,
      medicalRecords: mrs,
    );
  }
}
