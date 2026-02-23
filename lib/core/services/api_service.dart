import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/services_model.dart';
import '../constants/api_constants.dart';

class ServiceApi {
  static Future<List<ServiceModel>> fetchServices() async {
    final response = await http.get(Uri.parse(ApiConstants.services));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Kalau backend return langsung array
      if (decoded is List) {
        return decoded.map((json) => ServiceModel.fromJson(json)).toList();
      }

      // Kalau backend return { data: [...] }
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((json) => ServiceModel.fromJson(json))
            .toList();
      }
      print(response.body);

      throw Exception("Format response services tidak valid");
    } else {
      throw Exception("Failed load services");
    }
  }
}
