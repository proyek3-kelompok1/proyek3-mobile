import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class QueueApi {
  /// Fetch queue list for a given date and optional service type filter
  static Future<Map<String, dynamic>> fetchQueueData({
    required String date,
    String serviceType = 'all',
  }) async {
    try {
      final url = '${ApiConstants.queueList}?date=$date&service_type=$serviceType';
      debugPrint("📡 Fetching queue from: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
        },
      );

      debugPrint("📥 Queue response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception("Gagal memuat data antrian: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching queue: $e");
      rethrow;
    }
  }

  /// Check queue status by booking code
  static Future<Map<String, dynamic>> checkMyQueue({
    required String bookingCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.checkQueue),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "booking_code": bookingCode,
        }),
      );

      debugPrint("📥 Check queue response: ${response.statusCode}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Kode booking tidak ditemukan");
      }
    } catch (e) {
      debugPrint("❌ Error checking queue: $e");
      rethrow;
    }
  }
}
