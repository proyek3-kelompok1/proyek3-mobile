import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/consultation_model.dart';
import '../../models/message_model.dart';
import '../constants/api_constants.dart';

class ConsultationApi {
  /// Create a new consultation session
  static Future<ConsultationModel> createConsultation({
    required int doctorId,
    required String userName,
    required String userPhone,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.consultations),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "doctor_id": doctorId,
        "user_name": userName,
        "user_phone": userPhone,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return ConsultationModel.fromJson(data['data'] ?? data);
    } else {
      throw Exception("Gagal membuat konsultasi: ${response.body}");
    }
  }

  /// Fetch messages for a consultation
  static Future<List<MessageModel>> fetchMessages(int consultationId) async {
    final response = await http.get(
      Uri.parse("${ApiConstants.consultations}/$consultationId/messages"),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      List data;
      if (jsonData is List) {
        data = jsonData;
      } else if (jsonData is Map && jsonData['data'] is List) {
        data = jsonData['data'];
      } else {
        throw Exception("Invalid messages format");
      }

      return data.map((e) => MessageModel.fromJson(e)).toList();
    } else {
      throw Exception("Gagal memuat pesan: ${response.body}");
    }
  }

  /// Send a new message
  static Future<MessageModel> sendMessage({
    required int consultationId,
    required String senderType,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.consultations}/$consultationId/messages"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "sender_type": senderType,
        "message": message,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return MessageModel.fromJson(data['data'] ?? data);
    } else {
      throw Exception("Gagal mengirim pesan: ${response.body}");
    }
  }
}
