import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/pet_profile_model.dart';

class PetProfileApi {
  static const String baseUrl = 'http://192.168.18.23:8000/api'; // Sesuaikan IP

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<List<PetProfileModel>> getProfiles() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pet-profiles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List list = data['data'];
          return list.map((e) => PetProfileModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching pet profiles: $e');
      return [];
    }
  }

  static Future<PetProfileModel?> getProfileDetail(int id) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pet-profiles/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return PetProfileModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching pet detail: $e');
      return null;
    }
  }

  static Future<bool> createProfile(Map<String, String> fields, File? photoFile) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/pet-profiles'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields.addAll(fields);

      if (photoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
      }

      var streamedResponse = await request.send();
      return streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201;
    } catch (e) {
      print('Error creating pet profile: $e');
      return false;
    }
  }

  static Future<bool> deleteProfile(int id) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pet-profiles/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting pet: $e');
      return false;
    }
  }
}
