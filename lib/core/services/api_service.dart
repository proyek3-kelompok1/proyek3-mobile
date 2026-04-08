import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/services_model.dart';
import '../constants/api_constants.dart';

class ServiceApi {
  static Future<List<ServiceModel>> fetchServices() async {
    try {
      debugPrint("📡 Fetching services from: ${ApiConstants.services}");
      final response = await http.get(Uri.parse(ApiConstants.services));

      debugPrint("📥 Services response status: ${response.statusCode}");
      debugPrint("📥 Services response body: ${response.body.substring(0, response.body.length.clamp(0, 500))}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> dataList;

        // Kalau backend return langsung array
        if (decoded is List) {
          dataList = decoded;
        }
        // Kalau backend return { data: [...] }
        else if (decoded is Map && decoded['data'] is List) {
          dataList = decoded['data'] as List;
        } else {
          debugPrint("❌ Format response services tidak valid: ${decoded.runtimeType}");
          throw Exception("Format response services tidak valid");
        }

        debugPrint("✅ Parsed ${dataList.length} services");
        
        final services = dataList.map((json) => ServiceModel.fromJson(json)).toList();
        
        for (final s in services) {
          debugPrint("  → ${s.name} | type: ${s.serviceType} | price: ${s.formattedPrice} | duration: ${s.formattedDuration}");
        }

        return services;
      } else {
        debugPrint("❌ Failed load services: HTTP ${response.statusCode}");
        throw Exception("Failed load services: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching services: $e");
      rethrow;
    }
  }
}
