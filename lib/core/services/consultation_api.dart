import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/consultation_model.dart';
import '../../models/message_model.dart';
import '../constants/api_constants.dart';

class ConsultationApi {
  /// Create or get a consultation session
  static Future<ConsultationModel> createConsultation({
    required int doctorId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse(ApiConstants.consultations),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "doctor_id": doctorId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return ConsultationModel.fromJson(data['data'] ?? data);
    } else {
      throw Exception("Gagal membuat konsultasi: ${response.body}");
    }
  }

  /// List all consultation sessions (for doctor or user)
  static Future<List<ConsultationModel>> fetchSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse(ApiConstants.consultations),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['data'] ?? [];
      return data.map((e) => ConsultationModel.fromJson(e)).toList();
    } else {
      throw Exception("Gagal memuat daftar konsultasi");
    }
  }

  /// Fetch messages for a consultation
  static Future<List<MessageModel>> fetchMessages(int consultationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse("${ApiConstants.consultations}/$consultationId/messages"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['data'] ?? [];
      return data.map((e) => MessageModel.fromJson(e)).toList();
    } else {
      throw Exception("Gagal memuat pesan");
    }
  }

  /// Send a new message
  static Future<MessageModel> sendMessage({
    required int consultationId,
    required String message,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse("${ApiConstants.consultations}/$consultationId/messages"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "message": message,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return MessageModel.fromJson(data['data'] ?? data);
    } else {
      throw Exception("Gagal mengirim pesan");
    }
  }

  /// Delete a consultation session
  static Future<void> deleteConsultation(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.delete(
      Uri.parse("${ApiConstants.consultations}/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Gagal menghapus konsultasi: ${response.body}");
    }
  }
}
