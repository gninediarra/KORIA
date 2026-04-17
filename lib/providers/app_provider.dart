import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/data/mock_data.dart';
import 'package:latlong2/latlong.dart';

class AppProvider extends ChangeNotifier {
  String _mapLayer = 'sol';
  List<Zone> _zones = MockData.zones;
  List<DroneAlert> _alerts = MockData.alerts;
  DroneTelemetry _telemetry = MockData.initialTelemetry;
  Timer? _telemetryTimer;
  final Random _rng = Random();

  String get mapLayer => _mapLayer;
  List<Zone> get zones => _zones;
  List<DroneAlert> get alerts => _alerts;
  DroneTelemetry get telemetry => _telemetry;

  int get unreadCount => _alerts.where((a) => !a.lue).length;

  AppProvider() {
    _startTelemetrySimulation();
  }

  void setMapLayer(String layer) {
    _mapLayer = layer;
    notifyListeners();
  }

  List<DroneAlert> alertsForRole(UserRole role) =>
      _alerts.where((a) => a.rolesTarget.contains(role)).toList();

  void markAsRead(String id) {
    _alerts = _alerts
        .map((a) => a.id == id ? a.copyWith(lue: true) : a)
        .toList();
    notifyListeners();
  }

  void markAllAsRead(UserRole role) {
    _alerts = _alerts.map((a) {
      if (a.rolesTarget.contains(role)) return a.copyWith(lue: true);
      return a;
    }).toList();
    notifyListeners();
  }

  void _startTelemetrySimulation() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final lat = _telemetry.position.latitude + (_rng.nextDouble() - 0.5) * 0.002;
      final lng = _telemetry.position.longitude + (_rng.nextDouble() - 0.5) * 0.002;

      _telemetry = _telemetry.copyWith(
        batterie: (_telemetry.batterie - 0.08).clamp(0.0, 100.0),
        altitude: (_telemetry.altitude + (_rng.nextDouble() - 0.5) * 4).clamp(80.0, 200.0),
        vitesse: (_telemetry.vitesse + (_rng.nextDouble() - 0.5) * 2).clamp(8.0, 22.0),
        signalForce: (_telemetry.signalForce + (_rng.nextDouble() - 0.5) * 3).clamp(60.0, 100.0),
        position: LatLng(lat, lng),
        vent: (_telemetry.vent + (_rng.nextDouble() - 0.5) * 1.5).clamp(5.0, 30.0),
        distanceParcourue: _telemetry.distanceParcourue + 0.06,
        missionProgress: (_telemetry.missionProgress + 0.002).clamp(0.0, 1.0),
      );
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
