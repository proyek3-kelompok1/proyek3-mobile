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
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingCode: json['booking_code'] ?? '',
      nomorAntrian: json['nomor_antrian'] ?? 0,
      serviceName: json['service_name'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      bookingTime: json['booking_time'] ?? '',
      totalPrice: json['total_price'] ?? 0,
      namaHewan: json['nama_hewan'],
      jenisHewan: json['jenis_hewan'],
      status: json['status'],
    );
  }
}
