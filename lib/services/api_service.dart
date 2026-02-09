import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://127.0.0.1:8000';
  static const String baseUrl = 'http://127.0.0.1:8000';
  // static const String baseUrl = 'http://10.0.2.2:8000';
  // static const String baseUrl = 'http://10.0.2.2:8000';



  // -----------------------------
  // SEND OTP
  // -----------------------------
  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    final url = Uri.parse('$baseUrl/api/send-otp');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // -----------------------------
  // VERIFY OTP (UPDATED)
  // -----------------------------
  static Future<Map<String, dynamic>> verifyOtp(
      String mobile, String otp) async {
    final url = Uri.parse('$baseUrl/api/verify-otp');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'otp': otp}),
    );

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    // Save token if success
    if (res.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);

      // Optional: store has_business_details in storage
      if (data.containsKey('has_business_details')) {
        await prefs.setBool(
            'has_business_details', data['has_business_details']);
      }
    }

    return data;
  }

  // -----------------------------
  // SUBMIT BUSINESS DETAILS
  // -----------------------------
  static Future<Map<String, dynamic>> submitBusinessDetails(
      Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/api/business-details');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // -----------------------------
  // GET USER PROFILE (CHECK BUSINESS DETAILS)
  // -----------------------------
  static Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/api/me');

    final res = await http.get(
      url,
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // -----------------------------
  // SAVE TOKEN - EXTERNAL USE
  // -----------------------------
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }
}
