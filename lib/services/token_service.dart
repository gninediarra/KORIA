import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gabeseye/services/api_service.dart';

class TokenService {
  static String get _base => ApiService.baseUrl;

  static Map<String, String> get _h => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiService.currentToken}',
      };

  // ── Balance & transactions ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getBalance() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/tokens/balance'), headers: _h)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return null;
    } catch (_) { return null; }
  }

  static Future<List<dynamic>?> getTransactions({int limit = 50}) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/tokens/transactions?limit=$limit'), headers: _h)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return null;
    } catch (_) { return null; }
  }

  static Future<List<dynamic>?> getLeaderboard({int limit = 10}) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/tokens/leaderboard?limit=$limit'), headers: _h)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return null;
    } catch (_) { return null; }
  }

  // ── Drone priority votes ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> votePriority(String zoneName, int tokensToSpend) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/tokens/vote-priority'),
            headers: _h,
            body: jsonEncode({'zone_name': zoneName, 'tokens_to_spend': tokensToSpend}),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return {'error': (body['detail'] ?? 'Erreur').toString()};
    } catch (_) { return null; }
  }

  static Future<List<dynamic>?> getDronePriority() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/tokens/drone-priority'), headers: _h)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return null;
    } catch (_) { return null; }
  }

  // ── Anomaly reports ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> reportAnomaly({
    required String description,
    required String sensorType,
    required double lat,
    required double lng,
    String? zoneName,
    String? photoUrl,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/api/gamification/report-anomaly'),
            headers: _h,
            body: jsonEncode({
              'description': description,
              'sensor_type': sensorType,
              'lat': lat,
              'lng': lng,
              'zone_name': zoneName,
              'photo_url': photoUrl,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 201) return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return {'error': (body['detail'] ?? 'Erreur').toString()};
    } catch (_) { return null; }
  }

  static Future<List<dynamic>?> getMyReports() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/gamification/my-reports'), headers: _h)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return null;
    } catch (_) { return null; }
  }

  static Future<List<dynamic>?> getAllReports({String? status}) async {
    final q = status != null ? '?status=$status' : '';
    try {
      final res = await http
          .get(Uri.parse('$_base/api/gamification/reports$q'), headers: _h)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return null;
    } catch (_) { return null; }
  }

  // ── Cleanup events ─────────────────────────────────────────────────────────

  static Future<List<dynamic>?> getCleanupEvents() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/gamification/cleanup-events'), headers: _h)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return null;
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> joinCleanupEvent(String eventId) async {
    try {
      final res = await http
          .post(Uri.parse('$_base/api/gamification/cleanup-events/$eventId/join'), headers: _h)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return {'error': (body['detail'] ?? 'Erreur').toString()};
    } catch (_) { return null; }
  }
}
