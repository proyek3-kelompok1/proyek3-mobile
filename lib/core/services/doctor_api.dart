import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/doctor_model.dart';
import '../constants/api_constants.dart';

class DoctorApi {
  static Future<List<DoctorModel>> fetchDoctors() async {
    final response = await http.get(
      Uri.parse(ApiConstants.doctors),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      // Support both array and { data: [...] } format
      if (jsonData is List) {
        return jsonData.map((e) => DoctorModel.fromJson(e)).toList();
      }
      if (jsonData is Map && jsonData['data'] is List) {
        final List data = jsonData['data'];
        return data.map((e) => DoctorModel.fromJson(e)).toList();
      }

      throw Exception("Invalid doctor response format");
    } else {
      throw Exception("Failed to load doctors");
    }
  }

  static Future<DoctorModel> fetchDoctor(int id) async {
    final response = await http.get(
      Uri.parse("${ApiConstants.doctors}/$id"),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map && jsonData['data'] != null) {
        return DoctorModel.fromJson(jsonData['data']);
      }
      return DoctorModel.fromJson(jsonData);
    } else {
      throw Exception("Failed to load doctor");
    }
  }
}
