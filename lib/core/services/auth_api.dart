import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AuthApi {
  // Masukkan Web Client ID di sini agar bisa digunakan untuk verifikasi di Backend
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '862174055865-01ibuo61k344k9aaonhne4p76tpach1s.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  ); 

  // Sign In with Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('Memulai proses Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign-In dibatalkan oleh user.');
        return null;
      }

      print('Google Sign-In Berhasil: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Kita kirim accessToken atau idToken. Laravel Socialite biasanya butuh accessToken.
      final String? accessToken = googleAuth.accessToken;
      print('Token didapat: ${accessToken?.substring(0, 10)}...');

      if (accessToken != null) {
        return await _sendTokenToBackend(accessToken);
      }
      
      print('Error: Access Token bernilai NULL');
      return null;
    } catch (error) {
      print('CRITICAL Google Sign-In Error: $error');
      // Berikan error ke UI agar bisa ditampilkan di Snackbar
      throw error;
    }
  }

  // Login with Email and Password
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String accessToken = data['access_token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', accessToken);
        await prefs.setString('user_data', jsonEncode(data['user']));

        return data;
      } else {
        print('Login Gagal: ${response.body}');
        // Kembalikan body agar UI bisa baca pesan error 'not_verified'
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>?> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Verifikasi Gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Verifikasi Error: $e');
      return null;
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>?> resendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.resendOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Resend OTP Gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Resend OTP Error: $e');
      return null;
    }
  }

  // Register with Email and Password
  Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Registrasi Gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Registrasi Error: $e');
      return null;
    }
  }

  // Kirim Token ke Laravel
  Future<Map<String, dynamic>?> _sendTokenToBackend(String token) async {
    try {
      print('Mengirim token ke backend: ${ApiConstants.googleLogin}');
      final response = await http.post(
        Uri.parse(ApiConstants.googleLogin),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'token': token}),
      );

      print('Response Backend Status: ${response.statusCode}');
      print('Response Backend Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String accessToken = data['access_token'];
        
        // Simpan token ke lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', accessToken);
        await prefs.setString('user_data', jsonEncode(data['user']));

        print('Login Berhasil! Token disimpan.');
        return data;
      } else {
        print('Gagal Verifikasi Backend: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Koneksi ke Backend Error: $e');
      return null;
    }
  }

  // Get Profile Data
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('user_data', jsonEncode(data));
        return data;
      }
      return null;
    } catch (e) {
      print('Get Profile Error: $e');
      return null;
    }
  }

  // Update Profile (With Optional Avatar)
  Future<bool> updateProfile({required String name, required String phone, String? imagePath}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.updateProfile));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = name;
      request.fields['phone'] = phone;

      if (imagePath != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('user_data', jsonEncode(data['user']));
        return true;
      }
      print('Update Profile Failed: ${response.body}');
      return false;
    } catch (e) {
      print('Update Profile Error: $e');
      return false;
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        await http.post(
          Uri.parse(ApiConstants.logout),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }

      await _googleSignIn.signOut();
      await prefs.clear();
      return true;
    } catch (e) {
      print('Logout Error: $e');
      return false;
    }
  }

  // Cek apakah sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }
}
