import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../models/booking_model.dart';

class BookingHistoryApi {
  /// Fetch all bookings (active ones - not past booking date)
  static Future<List<BookingModel>> fetchActiveBookings() async {
    try {
      debugPrint("📡 Fetching booking history from: ${ApiConstants.bookingHistory}");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(ApiConstants.bookingHistory),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("📥 Booking history response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> dataList;
        if (decoded is List) {
          dataList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          dataList = decoded['data'] as List;
        } else {
          debugPrint("❌ Format response booking history tidak valid");
          return [];
        }

        final allBookings = dataList.map((j) => BookingModel.fromJson(j)).toList();

        // Filter: only show bookings whose date >= today
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final activeBookings = allBookings.where((b) {
          try {
            final bookingDate = DateTime.parse(b.bookingDate);
            // Show if it's today/future OR if it has a medical record
            return !bookingDate.isBefore(today) || b.hasMedicalRecord;
          } catch (_) {
            // If date parsing fails, still show it
            return true;
          }
        }).toList();

        // Sort by date (soonest first)
        activeBookings.sort((a, b) {
          try {
            return DateTime.parse(a.bookingDate)
                .compareTo(DateTime.parse(b.bookingDate));
          } catch (_) {
            return 0;
          }
        });

        debugPrint("✅ Active bookings: ${activeBookings.length} of ${allBookings.length} total");
        return activeBookings;
      } else {
        debugPrint("❌ Failed load booking history: HTTP ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching booking history: $e");
      return [];
    }
  }
}
