import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:gabeseye/models/models.dart';

class ApiService {
  static String get baseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';

  static String? _token;

  static void setToken(String? token) => _token = token;
  static bool get hasToken => _token != null;
  static String? get currentToken => _token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return {'error': (body['detail'] ?? 'Email ou mot de passe incorrect').toString()};
    } catch (_) {
      return {'network_error': true};
    }
  }

  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/users/me'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? quartier,
    String? parcelle,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
              'quartier': quartier,
              'parcelle': parcelle,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 201) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return {'error': (body['detail'] ?? 'Erreur inconnue').toString()};
    } catch (_) {
      return null;
    }
  }

  // ── Zones ─────────────────────────────────────────────────────────────────

  static Future<List<Zone>?> getZones() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/map/zones'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return data.map((j) => Zone.fromJson(j as Map<String, dynamic>)).toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Alerts ────────────────────────────────────────────────────────────────

  static Future<List<DroneAlert>?> getAlerts() async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/alerts/?active_only=true&limit=50'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return data
            .map((j) => DroneAlert.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
