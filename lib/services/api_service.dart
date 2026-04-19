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
      return {
        'error':
            (body['detail'] ?? 'Email ou mot de passe incorrect').toString()
      };
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

  // ── Status & Health ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getStatus() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/status'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Zones ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>?> getZonesRaw() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/zones'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Récupère toutes les zones + analyses sol/eau/air en parallèle
  static Future<List<Zone>?> getZones() async {
    final rawZones = await getZonesRaw();
    if (rawZones == null) return null;

    final List<Zone> zones = [];
    for (final zoneData in rawZones) {
      final id = zoneData['id'] as String;
      final results = await Future.wait([
        getSolAnalysis(id),
        getEauAnalysis(id),
        getAirAnalysis(id),
      ]);
      zones.add(Zone.fromBackend(
        zoneData,
        sol: results[0],
        eau: results[1],
        air: results[2],
      ));
    }
    return zones;
  }

  // ── Sol ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getSolAnalysis(String zoneId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/sol/$zoneId'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getSolTimeline(
      String zoneId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/sol/$zoneId/timeline'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getSolPrediction(
    String zoneId, {
    int steps = 12,
    String freq = 'monthly',
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '$baseUrl/sol/$zoneId/predict?steps=$steps&freq=$freq'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSolCropYield(String zoneId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/sol/$zoneId/crop-yield'),
              headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Eau ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getEauAnalysis(String zoneId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/eau/$zoneId'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getEauPrediction(
    String zoneId, {
    int steps = 12,
    String freq = 'monthly',
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '$baseUrl/eau/$zoneId/predict?steps=$steps&freq=$freq'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Air ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getAirAnalysis(String zoneId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/air/$zoneId/realtime'), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getAirPrediction(
    String zoneId, {
    int steps = 30,
    String freq = 'daily',
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '$baseUrl/air/$zoneId/predict?steps=$steps&freq=$freq'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getGaussianPlume(
    String zoneId, {
    double emissionRate = 500,
    double stackHeight = 60,
    double windSpeed = 5,
    String stability = 'D',
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '$baseUrl/air/plume/$zoneId?emission_rate=$emissionRate&stack_height=$stackHeight&wind_speed=$windSpeed&stability=$stability'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/dashboard'), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Drone ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getDroneStatus() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/drone/status'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDroneThermal({
    required double lat,
    required double lon,
    String zoneId = 'gct',
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse(
                '$baseUrl/drone/thermal?lat=$lat&lon=$lon&zone_id=$zoneId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Carte vivante ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getLivingMap() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/map/living'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Alertes (générées depuis air realtime) ────────────────────────────────

  static Future<List<DroneAlert>> getAlerts() async {
    final rawZones = await getZonesRaw();
    if (rawZones == null) return [];

    final alerts = <DroneAlert>[];
    for (final z in rawZones) {
      final zoneId = z['id'] as String;
      final air = await getAirAnalysis(zoneId);
      if (air == null) continue;

      final level = air['global_alert_level'] as String? ?? 'vert';
      if (level == 'vert') continue;

      final ep = air['episode_prediction'] as Map<String, dynamic>? ?? {};
      final aq = air['air_quality'] as Map<String, dynamic>? ?? {};
      final recs = (air['recommendations'] as List? ?? [])
          .map((r) => (r['message'] ?? '').toString())
          .toList();

      final severite = level == 'rouge'
          ? AlertSeverity.critique
          : AlertSeverity.avertissement;

      final isCritical = ep['is_critical'] as bool? ?? false;
      alerts.add(DroneAlert(
        id: '${zoneId}_${DateTime.now().millisecondsSinceEpoch}',
        titre: isCritical
            ? 'Épisode critique — ${z['name']}'
            : 'Alerte qualité air — ${z['name']}',
        description:
            'AQI ${aq['aqi'] ?? '?'} · SO₂ ${aq['so2'] ?? '?'} µg/m³ · PM2.5 ${aq['pm25'] ?? '?'} µg/m³',
        severite: severite,
        rolesTarget: _rolesForLevel(level),
        zone: z['name'] as String? ?? zoneId,
        timestamp: DateTime.tryParse(air['timestamp'] as String? ?? '') ??
            DateTime.now(),
        recommandations: recs,
      ));
    }
    return alerts;
  }

  static List<UserRole> _rolesForLevel(String level) {
    if (level == 'rouge') {
      return UserRole.values;
    }
    return [UserRole.autorite, UserRole.citoyen];
  }

  // ── TTS / Transcription ───────────────────────────────────────────────────

  static Uri ttsUri(String text, {String lang = 'fr'}) =>
      Uri.parse('$baseUrl/api/tts?text=${Uri.encodeComponent(text)}&lang=$lang');

  static Future<Map<String, dynamic>?> transcribe(
    List<int> audioBytes, {
    String lang = 'fr',
    String mimeType = 'audio/webm',
  }) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/transcribe?lang=$lang'),
      );
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: 'recording.webm',
      ));
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── WebSocket URLs ────────────────────────────────────────────────────────

  static String get wsBase =>
      Platform.isAndroid ? 'ws://10.0.2.2:8000' : 'ws://127.0.0.1:8000';

  static String droneWsUrl(String missionId) =>
      '$wsBase/ws/drone/$missionId';

  static String liveWsUrl(String role) => '$wsBase/ws/live/$role';
}
