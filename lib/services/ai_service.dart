import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiService {
  static String get _base =>
      Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';

  static const Map<String, String> _h = {'Content-Type': 'application/json'};

  // ── Chat multi-tour ────────────────────────────────────────────────────────
  // POST /agent/chat
  static Future<AiResponse> chat({
    required String message,
    required List<Map<String, String>> history,
    String role = 'citoyen',
    String langue = 'fr',
    String zoneId = 'gct',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/agent/chat'),
            headers: _h,
            body: jsonEncode({
              'message': message,
              'history': history,
              'role': role,
              'langue': langue,
              'zone_id': zoneId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        return AiResponse.fromJson(
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
      }
      return AiResponse.error('Erreur serveur (${res.statusCode})');
    } on SocketException {
      return AiResponse.error(
          'Backend hors ligne — vérifiez que le serveur tourne sur le port 8000.');
    } catch (e) {
      return AiResponse.error('Erreur réseau: $e');
    }
  }

  // ── Agent ponctuel par rôle ────────────────────────────────────────────────
  // POST /agent/agriculteur | /agent/pecheur | /agent/citoyen | /agent/autorite
  static Future<AiResponse> agent({
    required String role,
    String langue = 'fr',
    String question = '',
    String zoneId = 'gct',
  }) async {
    final endpoint = _endpointForRole(role);
    try {
      final res = await http
          .post(
            Uri.parse('$_base/agent/$endpoint'),
            headers: _h,
            body: jsonEncode({
              'zone_id': zoneId,
              'langue': langue,
              'question': question,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        return AiResponse.fromJson(
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
      }
      return AiResponse.error('Erreur serveur (${res.statusCode})');
    } on SocketException {
      return AiResponse.error('Backend hors ligne.');
    } catch (e) {
      return AiResponse.error('Erreur: $e');
    }
  }

  // ── Risque santé personnalisé ──────────────────────────────────────────────
  // POST /agent/health-risk
  static Future<AiResponse> healthRisk({
    required int age,
    required List<String> conditions,
    required String activite,
    String langue = 'fr',
    String zoneId = 'gct',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/agent/health-risk'),
            headers: _h,
            body: jsonEncode({
              'zone_id': zoneId,
              'langue': langue,
              'profil': {
                'age': age,
                'conditions': conditions,
                'activite': activite,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        return AiResponse.fromJson(
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
      }
      return AiResponse.error('Erreur serveur (${res.statusCode})');
    } catch (e) {
      return AiResponse.error('Erreur: $e');
    }
  }

  // ── Image analysis via Groq vision ────────────────────────────────────────
  // POST /agent/analyze-image (multipart)
  static Future<AiResponse> analyzeImage({
    required File imageFile,
    String question = '',
    String langue = 'fr',
    String zoneId = 'gct',
  }) async {
    try {
      final uri = Uri.parse('$_base/agent/analyze-image');
      final req = http.MultipartRequest('POST', uri)
        ..fields['question'] = question
        ..fields['langue'] = langue
        ..fields['zone_id'] = zoneId
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        return AiResponse.fromJson(
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
      }
      return AiResponse.error('Erreur analyse image (${res.statusCode})');
    } on SocketException {
      return AiResponse.error('Backend hors ligne.');
    } catch (e) {
      return AiResponse.error('Erreur: $e');
    }
  }

  static String _endpointForRole(String role) {
    switch (role) {
      case 'agriculteur':
        return 'agriculteur';
      case 'pecheur':
        return 'pecheur';
      case 'autorite':
        return 'autorite';
      default:
        return 'citoyen';
    }
  }
}

class AiResponse {
  final String text;
  final String? role;
  final String? langue;
  final bool isError;
  final String? timestamp;

  const AiResponse({
    required this.text,
    this.role,
    this.langue,
    this.isError = false,
    this.timestamp,
  });

  factory AiResponse.fromJson(Map<String, dynamic> j) => AiResponse(
        text: (j['response'] ?? j['text'] ?? j['message'] ?? '').toString(),
        role: j['role']?.toString() ?? j['agent']?.toString(),
        langue: j['langue']?.toString(),
        timestamp: j['timestamp']?.toString(),
      );

  factory AiResponse.error(String msg) => AiResponse(text: msg, isError: true);
}

  // ── Message de bienvenue avec données réelles ──────────────────────────────
  // GET /agent/welcome?role=...&langue=...&zone_id=...
  static Future<AiResponse> welcome({
    String role = 'citoyen',
    String langue = 'fr',
    String zoneId = 'gct',
  }) async {
    try {
      final uri = Uri.parse(
        '$_base/agent/welcome?role=$role&langue=$langue&zone_id=$zoneId',
      );
      final res = await http
          .get(uri, headers: _h)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        return AiResponse.fromJson(
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
      }
      return AiResponse.error('Erreur serveur (${res.statusCode})');
    } on SocketException {
      return AiResponse.error('Backend hors ligne.');
    } catch (e) {
      return AiResponse.error('Erreur: $e');
    }
  }
