import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../models/education_model.dart';

class EducationService {
  Future<List<Education>> fetchEducation() async {
    final response = await http.get(
      Uri.parse(ApiConstants.education),
    );

    print(response.body); // DEBUG

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List list = data['data'];

      return list.map((e) => Education.fromJson(e)).toList();
    } else {
      throw Exception("Gagal load data");
    }
  }

  Future<void> incrementView(int id) async {
    try {
      // Memanggil endpoint detail untuk men-trigger increment view di backend
      // Biasanya di Laravel: GET /api/education/{id} akan menambah views++
      await http.get(
        Uri.parse("${ApiConstants.education}/$id"),
      );
    } catch (e) {
      print("Error incrementing view: $e");
    }
  }
}
