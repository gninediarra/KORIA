import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/data/mock_data.dart';
import 'package:gabeseye/services/api_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Thresholds for auto-alerts
const double _kSo2Threshold  = 100.0;  // µg/m³ WHO limit
const double _kAqiThreshold  = 150.0;  // Unhealthy level
const double _kPm25Threshold = 35.0;   // µg/m³ 24h average

class AppProvider extends ChangeNotifier {
  String _mapLayer = 'sol';
  List<Zone> _zones = MockData.zones;
  List<DroneAlert> _alerts = MockData.alerts;
  DroneTelemetry _telemetry = MockData.initialTelemetry;
  Timer? _refreshTimer;
  bool _isLoadingData = false;
  bool _droneConnected = false;

  WebSocketChannel? _droneChannel;
  WebSocketChannel? _liveChannel;
  StreamSubscription? _droneSub;
  StreamSubscription? _liveSub;

  final FlutterLocalNotificationsPlugin _notif = FlutterLocalNotificationsPlugin();
  final Set<String> _firedAlertKeys = {};
  int _notifId = 100;

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(
      const InitializationSettings(android: android),
    );
  }

  Future<void> _showNotification(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'gabeseye_alerts', 'Alertes GabèsEye',
        channelDescription: 'Alertes environnementales automatiques',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _notif.show(_notifId++, title, body, details);
  }

  void _checkThresholds(String zoneId, Map<String, dynamic> aq) {
    final so2  = (aq['so2']  as num?)?.toDouble() ?? 0;
    final aqi  = (aq['aqi']  as num?)?.toDouble() ?? 0;
    final pm25 = (aq['pm25'] as num?)?.toDouble() ?? 0;

    void maybeAlert(String key, String titre, String desc, AlertSeverity sev,
        List<String> recs) {
      if (_firedAlertKeys.contains(key)) return;
      _firedAlertKeys.add(key);
      final alert = DroneAlert(
        id: 'auto_${key}_${DateTime.now().millisecondsSinceEpoch}',
        titre: titre,
        description: desc,
        severite: sev,
        rolesTarget: UserRole.values,
        zone: zoneId.toUpperCase(),
        timestamp: DateTime.now(),
        recommandations: recs,
      );
      _alerts = [alert, ..._alerts];
      notifyListeners();
      _showNotification(titre, desc);
    }

    if (so2 > _kSo2Threshold) {
      maybeAlert(
        '${zoneId}_so2_${(so2 / 50).floor()}',
        '⚠️ SO₂ critique — Zone ${zoneId.toUpperCase()}',
        'Concentration SO₂ = ${so2.toStringAsFixed(1)} µg/m³ (seuil OMS: ${_kSo2Threshold.toInt()} µg/m³)',
        so2 > 200 ? AlertSeverity.critique : AlertSeverity.avertissement,
        [
          'Fermez les fenêtres et restez à l\'intérieur.',
          'Évitez tout effort physique en extérieur.',
          'Portez un masque FFP2 si vous devez sortir.',
          'Contactez le centre médical si vous ressentez des difficultés respiratoires.',
        ],
      );
    } else {
      _firedAlertKeys.remove('${zoneId}_so2_${(so2 / 50).floor()}');
    }

    if (aqi > _kAqiThreshold) {
      maybeAlert(
        '${zoneId}_aqi_${(aqi / 50).floor()}',
        '🔴 Qualité air mauvaise — Zone ${zoneId.toUpperCase()}',
        'AQI = ${aqi.toInt()} — Niveau: MAUVAIS (seuil: ${_kAqiThreshold.toInt()})',
        aqi > 200 ? AlertSeverity.critique : AlertSeverity.avertissement,
        [
          'Limitez les activités en plein air.',
          'Les personnes vulnérables doivent rester chez elles.',
          'Consultez la carte GabèsEye pour les zones moins polluées.',
        ],
      );
    }

    if (pm25 > _kPm25Threshold) {
      maybeAlert(
        '${zoneId}_pm25_${(pm25 / 20).floor()}',
        '🟠 PM2.5 élevé — Zone ${zoneId.toUpperCase()}',
        'PM2.5 = ${pm25.toStringAsFixed(1)} µg/m³ (seuil OMS: ${_kPm25Threshold.toInt()} µg/m³)',
        AlertSeverity.avertissement,
        [
          'Portez un masque en extérieur.',
          'Évitez les zones à fort trafic ou industrielles.',
        ],
      );
    }
  }

  String get mapLayer => _mapLayer;
  List<Zone> get zones => _zones;
  List<DroneAlert> get alerts => _alerts;
  DroneTelemetry get telemetry => _telemetry;
  bool get isLoadingData => _isLoadingData;
  bool get droneConnected => _droneConnected;

  int get unreadCount => _alerts.where((a) => !a.lue).length;

  // ── Chargement initial depuis l'API Mané ─────────────────────────────────

  Future<void> loadFromApi({String role = 'citoyen'}) async {
    _isLoadingData = true;
    notifyListeners();

    await _initNotifications();

    await Future.wait([
      _fetchZonesWithAnalysis(),
      _fetchAlerts(),
    ]);

    _isLoadingData = false;
    notifyListeners();

    // Connexion WebSocket drone
    _connectDroneWs('mission_gabes_01');

    // Connexion WebSocket mises à jour environnementales par rôle
    _connectLiveWs(role);

    // Rafraîchissement périodique des alertes (30 s)
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchAlerts(),
    );
  }

  // ── Zones + analyses sol/eau/air ──────────────────────────────────────────

  Future<void> _fetchZonesWithAnalysis() async {
    final result = await ApiService.getZones();
    if (result != null && result.isNotEmpty) {
      _zones = result;
    }
    // Si backend indisponible → garde les zones mock
  }

  // ── Alertes générées depuis /air/{zone_id}/realtime ───────────────────────

  Future<void> _fetchAlerts() async {
    final result = await ApiService.getAlerts();
    if (result.isNotEmpty) {
      final readIds = {
        for (final a in _alerts)
          if (a.lue) a.id
      };
      _alerts = result
          .map((a) => readIds.contains(a.id) ? a.copyWith(lue: true) : a)
          .toList();
      notifyListeners();
    }
    // Si backend vide → garde les alertes mock
  }

  // ── Rechargement manuel d'une zone ───────────────────────────────────────

  Future<void> refreshZone(String zoneId) async {
    final rawZonesFuture = ApiService.getZonesRaw();
    final analysisFuture = Future.wait([
      ApiService.getSolAnalysis(zoneId),
      ApiService.getEauAnalysis(zoneId),
      ApiService.getAirAnalysis(zoneId),
    ]);

    final rawZones = await rawZonesFuture;
    final analysis = await analysisFuture;

    if (rawZones == null) return;
    final rawZone = rawZones.firstWhere(
      (z) => z['id'] == zoneId,
      orElse: () => {},
    );
    if (rawZone.isEmpty) return;

    final idx = _zones.indexWhere((z) => z.id == zoneId);
    final updated = Zone.fromBackend(
      rawZone,
      sol: analysis[0],
      eau: analysis[1],
      air: analysis[2],
    );
    if (idx >= 0) {
      _zones[idx] = updated;
    } else {
      _zones.add(updated);
    }
    notifyListeners();
  }

  // ── WebSocket drone telemetry ─────────────────────────────────────────────

  void _connectDroneWs(String missionId) {
    _droneSub?.cancel();
    try {
      _droneChannel = WebSocketChannel.connect(
        Uri.parse(ApiService.droneWsUrl(missionId)),
      );
      _droneConnected = true;
      _droneSub = _droneChannel!.stream.listen(
        (msg) => _onDronePacket(msg as String),
        onError: (_) => _onDroneDisconnected(),
        onDone: _onDroneDisconnected,
      );
    } catch (_) {
      _droneConnected = false;
      // Telemetry mock reste active
    }
  }

  void _onDronePacket(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final pos = j['position'] as Map<String, dynamic>?;
      final sensors = j['sensors'] as Map<String, dynamic>?;
      final jetson = j['jetson_status'] as Map<String, dynamic>?;
      final phase = j['phase'] as String? ?? 'idle';

      _telemetry = DroneTelemetry(
        batterie:
            (j['battery_pct'] as num? ?? _telemetry.batterie).toDouble(),
        altitude:
            (pos?['altitude_m'] as num? ?? _telemetry.altitude).toDouble(),
        vitesse:
            (sensors?['speed_m_s'] as num? ?? _telemetry.vitesse).toDouble(),
        signalForce: _telemetry.signalForce,
        position: pos != null
            ? LatLng(
                (pos['lat'] as num).toDouble(),
                (pos['lon'] as num).toDouble(),
              )
            : _telemetry.position,
        status: _phaseToStatus(phase),
        temperature:
            (jetson?['temp_c'] as num? ?? _telemetry.temperature).toDouble(),
        missionActuelle: 'Mission Gabès — Phase: $phase',
        missionProgress: _phaseToProgress(phase),
        multispectralActif: phase == 'scanning',
        thermiqueActif: phase == 'scanning',
        atmospheriqueActif: phase == 'scanning',
        vent: _telemetry.vent,
        distanceParcourue: _telemetry.distanceParcourue +
            (sensors?['speed_m_s'] as num? ?? 0).toDouble() / 1000,
      );
      notifyListeners();
    } catch (_) {}
  }

  void _onDroneDisconnected() {
    _droneConnected = false;
    notifyListeners();
    Future.delayed(const Duration(seconds: 5), () {
      if (!_droneConnected) _connectDroneWs('mission_gabes_01');
    });
  }

  DroneStatus _phaseToStatus(String phase) {
    switch (phase) {
      case 'takeoff':
      case 'transit':
      case 'scanning':
      case 'return':
        return DroneStatus.enVol;
      case 'idle':
      case 'landing':
      case 'complete':
        return DroneStatus.pause;
      default:
        return DroneStatus.deconnecte;
    }
  }

  double _phaseToProgress(String phase) {
    switch (phase) {
      case 'idle':
        return 0.0;
      case 'takeoff':
        return 0.1;
      case 'transit':
        return 0.3;
      case 'scanning':
        return 0.6;
      case 'return':
        return 0.85;
      case 'landing':
      case 'complete':
        return 1.0;
      default:
        return 0.0;
    }
  }

  // ── WebSocket live updates par rôle ──────────────────────────────────────

  void _connectLiveWs(String role) {
    _liveSub?.cancel();
    try {
      _liveChannel = WebSocketChannel.connect(
        Uri.parse(ApiService.liveWsUrl(role)),
      );
      _liveSub = _liveChannel!.stream.listen(
        (msg) => _onLiveUpdate(msg as String),
        onError: (_) {},
        onDone: () {},
      );
    } catch (_) {}
  }

  void _onLiveUpdate(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final zoneId = j['zone_id'] as String?;
      if (zoneId == null) return;

      final idx = _zones.indexWhere((z) => z.id == zoneId);
      if (idx < 0) return;

      final airData = j['air'] as Map<String, dynamic>?;
      if (airData == null) return;

      final aq = airData['air_quality'] as Map<String, dynamic>? ?? {};
      _checkThresholds(zoneId, aq);
      final newAir = AirReadings(
        so2: (aq['so2'] as num? ?? _zones[idx].air.so2).toDouble(),
        h2s: _zones[idx].air.h2s,
        nh3: _zones[idx].air.nh3,
        pm25: (aq['pm25'] as num? ?? _zones[idx].air.pm25).toDouble(),
        aqi: (aq['aqi'] as num? ?? _zones[idx].air.aqi).toInt(),
        etat: aq['alert_level'] as String? ?? _zones[idx].air.etat,
      );
      final z = _zones[idx];
      _zones[idx] = Zone(
        id: z.id,
        name: z.name,
        type: z.type,
        status: airData['global_alert_level'] as String? ?? z.status,
        center: z.center,
        polygon: z.polygon,
        soil: z.soil,
        water: z.water,
        air: newAir,
        recommandations: z.recommandations,
        derniereAnalyse: DateTime.now(),
      );
      notifyListeners();
    } catch (_) {}
  }

  // ── Couche carte ──────────────────────────────────────────────────────────

  void setMapLayer(String layer) {
    _mapLayer = layer;
    notifyListeners();
  }

  // ── Alertes ───────────────────────────────────────────────────────────────

  List<DroneAlert> alertsForRole(UserRole role) =>
      _alerts.where((a) => a.rolesTarget.contains(role)).toList();

  void markAsRead(String id) {
    _alerts =
        _alerts.map((a) => a.id == id ? a.copyWith(lue: true) : a).toList();
    notifyListeners();
  }

  void markAllAsRead(UserRole role) {
    _alerts = _alerts.map((a) {
      if (a.rolesTarget.contains(role)) return a.copyWith(lue: true);
      return a;
    }).toList();
    notifyListeners();
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _droneSub?.cancel();
    _liveSub?.cancel();
    _droneChannel?.sink.close();
    _liveChannel?.sink.close();
    super.dispose();
  }
}
