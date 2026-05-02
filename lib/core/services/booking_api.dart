import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/booking_model.dart';

class BookingApi {
  static Future<BookingModel> createBooking({
    required String namaPemilik,
    required String email,
    required String telepon,
    required String alamat,
    required String namaHewan,
    required String jenisHewan,
    required String jenisKelamin,
    required String ras,
    required int umur,
    required String ciriWarna,
    required int serviceId,
    required String serviceType,
    required int doctorId,
    required String bookingDate,
    required String bookingTime,
    String? catatan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse(ApiConstants.booking),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "nama_pemilik": namaPemilik,
        "email": email,
        "telepon": telepon,
        "alamat": alamat,
        "nama_hewan": namaHewan,
        "jenis_hewan": jenisHewan,
        "jenis_kelamin": jenisKelamin,
        "ras": ras,
        "umur": umur,
        "ciri_warna": ciriWarna,
        "service_id": serviceId,
        "service_type": serviceType,
        "doctor_id": doctorId,
        "booking_date": bookingDate,
        "booking_time": bookingTime,
        "catatan": catatan ?? "",
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return BookingModel.fromJson(data['data']);
    } else {
      throw Exception("Booking gagal: ${response.body}");
    }
  }
}
