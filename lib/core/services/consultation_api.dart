import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/consultation_model.dart';
import '../../models/message_model.dart';
import '../constants/api_constants.dart';

class ConsultationApi {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String? token) => {
    "Accept": "application/json",
    "Authorization": "Bearer $token",
  };

  static Map<String, String> _jsonHeaders(String? token) => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer $token",
  };

  /// Create or get a consultation session
  static Future<ConsultationModel> createConsultation({
    required int doctorId,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(ApiConstants.consultations),
      headers: _jsonHeaders(token),
      body: jsonEncode({"doctor_id": doctorId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return ConsultationModel.fromJson(data['data'] ?? data);
    } else {
      throw Exception("Gagal membuat konsultasi: ${response.body}");
    }
  }

  /// Fetch a single consultation session (for realtime online/typing status)
  static Future<ConsultationModel?> fetchConsultation(int id) async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.consultations}/$id"),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ConsultationModel.fromJson(jsonData['data'] ?? jsonData);
      }
    } catch (_) {}
    return null;
  }

  /// Notify server that current user is typing
  static Future<void> sendTyping(int consultationId) async {
    final token = await _getToken();
    try {
      await http.post(
        Uri.parse("${ApiConstants.consultations}/$consultationId/typing"),
        headers: _jsonHeaders(token),
      );
    } catch (_) {}
  }

  /// List all consultation sessions (for doctor or user)
  static Future<List<ConsultationModel>> fetchSessions() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(ApiConstants.consultations),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData is List) {
        return jsonData.map((e) => ConsultationModel.fromJson(e)).toList();
      }
      if (jsonData is Map && jsonData['data'] is List) {
        final List data = jsonData['data'];
        return data.map((e) => ConsultationModel.fromJson(e)).toList();
      }

      return [];
    } else {
      throw Exception("Gagal memuat daftar konsultasi");
    }
  }

  /// Fetch messages for a consultation
  static Future<List<MessageModel>> fetchMessages(int consultationId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("${ApiConstants.consultations}/$consultationId/messages"),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['data'] ?? jsonData;
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
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("${ApiConstants.consultations}/$consultationId/messages"),
      headers: _jsonHeaders(token),
      body: jsonEncode({"message": message}),
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
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse("${ApiConstants.consultations}/$id"),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Gagal menghapus konsultasi: ${response.body}");
    }
  }
}
