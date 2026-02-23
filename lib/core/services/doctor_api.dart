import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/doctor_model.dart';
import '../constants/api_constants.dart';

class DoctorApi {
  static Future<List<DoctorModel>> fetchDoctors() async {
    final response = await http.get(
      Uri.parse(ApiConstants.services),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List data = jsonData['data'];

      return data.map((e) => DoctorModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load doctors");
    }
    
  }
}
