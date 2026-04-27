import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../models/booking_model.dart';

class MedicalRecordApi {
  static Future<List<MedicalRecordModel>> fetchAllMedicalRecords() async {
    try {
      debugPrint("📡 Fetching ALL medical records from: ${ApiConstants.medicalRecords}");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(ApiConstants.medicalRecords),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("📥 Medical records response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        debugPrint("📥 Raw Medical Records: ${response.body}");
        final decoded = json.decode(response.body);

        if (decoded['success'] == true) {
          final List<dynamic> data = decoded['data'];
          try {
            return data.map((j) => MedicalRecordModel.fromJson(j)).toList();
          } catch (pe) {
            debugPrint("❌ Error parsing medical record JSON: $pe");
            rethrow;
          }
        }
        return [];
      } else {
        debugPrint("❌ Failed load medical records: HTTP ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching medical records: $e");
      return [];
    }
  }
}
