import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/services/api_service.dart';

// ── Waypoints de la mission Gabès ─────────────────────────────────────────────

const _waypoints = [
  LatLng(33.8820, 9.9780), // Base GabèsEye
  LatLng(33.8900, 9.9900), // GCT Nord
  LatLng(33.8650, 9.9820), // GCT Centre
  LatLng(33.8480, 9.9700), // GCT Sud
  LatLng(33.8600, 9.9500), // GCT Ouest
  LatLng(33.8820, 9.9780), // Retour base
];

// Contamination zones for overlay
const _contamZones = [
  _ContamZone(LatLng(33.860, 9.975), 1200, 'GCT Usine', Colors.red, 0.35),
  _ContamZone(LatLng(33.855, 9.985), 800, 'Zone phosphate', Colors.orange, 0.28),
  _ContamZone(LatLng(33.875, 9.990), 600, 'Rejet mer', Colors.deepOrange, 0.22),
];

class _ContamZone {
  final LatLng center;
  final double radiusMeters;
  final String label;
  final Color color;
  final double opacity;
  const _ContamZone(this.center, this.radiusMeters, this.label, this.color, this.opacity);
}

// ── Main screen ───────────────────────────────────────────────────────────────

class DroneStatusScreen extends StatefulWidget {
  const DroneStatusScreen({super.key});

  @override
  State<DroneStatusScreen> createState() => _DroneStatusScreenState();
}

class _DroneStatusScreenState extends State<DroneStatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _droneAnim;
  late AnimationController _pulseAnim;
  late AnimationController _scanAnim;
  late MapController _mapCtrl;

  bool _mapMode = true; // true = 2D satellite map, false = telemetry dashboard

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _droneAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _droneAnim.dispose();
    _pulseAnim.dispose();
    _scanAnim.dispose();
    super.dispose();
  }

  // Interpolate position along waypoints
  LatLng _getDronePosition(double progress, double missionProgress) {
    // Use mission progress if connected, else animate locally
    final t = missionProgress > 0 ? missionProgress : progress;
    final segments = _waypoints.length - 1;
    final segT = (t * segments).clamp(0.0, segments.toDouble());
    final segIdx = segT.floor().clamp(0, segments - 1);
    final segFrac = segT - segIdx;
    final a = _waypoints[segIdx];
    final b = _waypoints[(segIdx + 1).clamp(0, _waypoints.length - 1)];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * segFrac,
      a.longitude + (b.longitude - a.longitude) * segFrac,
    );
  }

  double _getDroneHeading(double progress, double missionProgress) {
    final t = missionProgress > 0 ? missionProgress : progress;
    final segments = _waypoints.length - 1;
    final segT = (t * segments).clamp(0.0, segments.toDouble());
    final segIdx = segT.floor().clamp(0, segments - 1);
    final a = _waypoints[segIdx];
    final b = _waypoints[(segIdx + 1).clamp(0, _waypoints.length - 1)];
    final dLon = b.longitude - a.longitude;
    final dLat = b.latitude - a.latitude;
    return math.atan2(dLon, dLat);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final t = app.telemetry;
    final wsConnected = app.droneConnected;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Full-screen map or dashboard
          _mapMode
              ? _buildSatelliteMap(app, t)
              : _buildDashboard(context, t),

          // Top app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context, t, wsConnected),
          ),

          // Mode toggle FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'center',
                  backgroundColor: AppColors.card,
                  onPressed: () {
                    if (_mapMode) {
                      _mapCtrl.move(t.position, 14);
                    }
                  },
                  child: const Icon(Icons.my_location_rounded,
                      color: AppColors.cyan, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'toggle',
                  backgroundColor: AppColors.cyan,
                  onPressed: () => setState(() => _mapMode = !_mapMode),
                  child: Icon(
                    _mapMode ? Icons.dashboard_rounded : Icons.map_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Bottom telemetry strip (always visible in map mode)
          if (_mapMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildTelemetryStrip(t),
            ),
        ],
      ),
    );
  }

  // ── Satellite map with drone overlay ──────────────────────────────────────

  Widget _buildSatelliteMap(AppProvider app, DroneTelemetry t) {
    return AnimatedBuilder(
      animation: _droneAnim,
      builder: (context, child) {
        final dronePos = _getDronePosition(_droneAnim.value, t.missionProgress);
        final heading = _getDroneHeading(_droneAnim.value, t.missionProgress);
        final isScanning = t.multispectralActif ||
            t.missionActuelle.contains('scanning') ||
            t.missionProgress > 0.3 && t.missionProgress < 0.85;

        return FlutterMap(
          mapController: _mapCtrl,
          options: const MapOptions(
            initialCenter: LatLng(33.869, 9.978),
            initialZoom: 13.5,
            maxZoom: 18,
            minZoom: 10,
          ),
          children: [
            // Satellite tile layer (ESRI WorldImagery)
            TileLayer(
              urlTemplate:
                  'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'com.gabeseye.app',
              maxZoom: 18,
            ),

            // Contamination zone overlays
            CircleLayer(
              circles: [
                ..._contamZones.map((z) => CircleMarker(
                      point: z.center,
                      radius: z.radiusMeters / 111320 * 1000,
                      useRadiusInMeter: true,
                      color: z.color.withValues(alpha: z.opacity),
                      borderColor: z.color,
                      borderStrokeWidth: 2,
                    )),
                // Scan pulse ring (when scanning)
                if (isScanning)
                  CircleMarker(
                    point: dronePos,
                    radius: 200 + 150 * _pulseAnim.value,
                    useRadiusInMeter: true,
                    color: AppColors.cyan.withValues(alpha: 0.06 * (1 - _pulseAnim.value)),
                    borderColor: AppColors.cyan.withValues(alpha: 0.5 - 0.3 * _pulseAnim.value),
                    borderStrokeWidth: 1.5,
                  ),
              ],
            ),

            // Safe zone indicator
            CircleLayer(
              circles: [
                CircleMarker(
                  point: const LatLng(33.882, 10.020),
                  radius: 600,
                  useRadiusInMeter: true,
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderColor: AppColors.green.withValues(alpha: 0.5),
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),

            // Flight path (planned route)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _waypoints,
                  strokeWidth: 1.5,
                  color: AppColors.cyan.withValues(alpha: 0.4),
                  strokeCap: StrokeCap.round,
                ),
                // Completed path
                Polyline(
                  points: _waypoints.sublist(
                    0,
                    ((_droneAnim.value * (_waypoints.length - 1)).floor() + 2)
                        .clamp(0, _waypoints.length),
                  ),
                  strokeWidth: 2.5,
                  color: AppColors.cyan.withValues(alpha: 0.8),
                ),
              ],
            ),

            // Waypoint markers
            MarkerLayer(
              markers: _waypoints
                  .asMap()
                  .entries
                  .map((e) => Marker(
                        point: e.value,
                        width: 10,
                        height: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.cyan,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            // Contamination zone labels
            MarkerLayer(
              markers: _contamZones
                  .map((z) => Marker(
                        point: z.center,
                        width: 100,
                        height: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: z.color.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            z.label,
                            style: GoogleFonts.exo2(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            // Safe zone label
            MarkerLayer(
              markers: [
                Marker(
                  point: const LatLng(33.882, 10.020),
                  width: 90,
                  height: 22,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Zone saine',
                        style: GoogleFonts.exo2(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),

            // Animated drone marker
            MarkerLayer(
              markers: [
                Marker(
                  point: dronePos,
                  width: 56,
                  height: 56,
                  child: _DroneMarker(
                    heading: heading,
                    isScanning: isScanning,
                    pulseAnim: _pulseAnim,
                    scanAnim: _scanAnim,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, DroneTelemetry t, bool wsConnected) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Drone icon with pulse
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15 + 0.08 * _pulseAnim.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.2 + 0.15 * _pulseAnim.value),
                      blurRadius: 10 + 5 * _pulseAnim.value,
                    ),
                  ],
                ),
                child: const Icon(Icons.flight_rounded, color: AppColors.cyan, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('GE-01 · Mission Gabès',
                          style: GoogleFonts.exo2(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      if (wsConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('LIVE',
                              style: GoogleFonts.exo2(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.green,
                                  letterSpacing: 0.5)),
                        ),
                    ],
                  ),
                  Text(
                    '${(t.missionProgress * 100).toInt()}% · Alt ${t.altitude.toInt()}m · ${t.vitesse.toStringAsFixed(1)} m/s',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Status dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: t.status.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: t.status.color.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom telemetry strip ─────────────────────────────────────────────────

  Widget _buildTelemetryStrip(DroneTelemetry t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 90, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
            icon: Icons.battery_charging_full_rounded,
            value: '${t.batterie.toInt()}%',
            color: t.batterie > 50 ? AppColors.green : AppColors.orange,
          ),
          _MiniStat(
            icon: Icons.height_rounded,
            value: '${t.altitude.toInt()}m',
            color: AppColors.cyan,
          ),
          _MiniStat(
            icon: Icons.speed_rounded,
            value: '${t.vitesse.toStringAsFixed(1)}m/s',
            color: AppColors.water,
          ),
          _MiniStat(
            icon: Icons.wifi_rounded,
            value: '${t.signalForce.toInt()}%',
            color: AppColors.green,
          ),
          _MiniStat(
            icon: Icons.thermostat_rounded,
            value: '${t.temperature.toInt()}°C',
            color: t.temperature < 50 ? AppColors.green : AppColors.red,
          ),
        ],
      ),
    );
  }

  // ── Full telemetry dashboard ───────────────────────────────────────────────

  Widget _buildDashboard(BuildContext context, DroneTelemetry t) {
    final app = context.read<AppProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
      children: [
        _buildMissionCard(context, t, app.droneConnected),
        const SizedBox(height: 16),
        _buildContaminationLegend(context),
        const SizedBox(height: 16),
        _buildTelemetryGrid(context, t),
        const SizedBox(height: 16),
        _buildSensorsCard(context, t),
        const SizedBox(height: 16),
        _buildFlightStats(context, t),
      ],
    );
  }

  Widget _buildMissionCard(BuildContext context, DroneTelemetry t, bool wsConnected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.12),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_rounded, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text('MISSION EN COURS',
                  style: GoogleFonts.exo2(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyan,
                      letterSpacing: 1.5)),
              const Spacer(),
              if (wsConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('LIVE',
                      style: GoogleFonts.exo2(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                          letterSpacing: 1)),
                ),
              const SizedBox(width: 8),
              Text('${(t.missionProgress * 100).toInt()}%',
                  style: GoogleFonts.exo2(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyan)),
            ],
          ),
          const SizedBox(height: 10),
          Text(t.missionActuelle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: t.missionProgress,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance : ${t.distanceParcourue.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                  'Pos : ${t.position.latitude.toStringAsFixed(4)}°N',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContaminationLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.legend_toggle_rounded,
                  color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text('Légende contamination',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),
          ..._contamZones.map((z) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: z.color.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: z.color, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(z.label,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: z.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('CONTAMINÉ',
                          style: GoogleFonts.exo2(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: z.color)),
                    ),
                  ],
                ),
              )),
          const Divider(height: 16),
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.green, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text('Zone Ville — Saine',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('SAINE',
                    style: GoogleFonts.exo2(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(BuildContext context, DroneTelemetry t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sensors_rounded, color: AppColors.cyan, size: 18),
            const SizedBox(width: 8),
            Text('Télémétrie temps réel',
                style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _TelemetryCard(
              icon: Icons.battery_charging_full_rounded,
              label: 'Batterie',
              value: '${t.batterie.toInt()}%',
              sub: t.batterie > 50 ? 'Suffisant' : t.batterie > 20 ? 'Faible' : 'Critique',
              color: t.batterie > 50 ? AppColors.green : t.batterie > 20 ? AppColors.orange : AppColors.red,
              progress: t.batterie / 100,
            ),
            _TelemetryCard(
              icon: Icons.height_rounded,
              label: 'Altitude',
              value: '${t.altitude.toInt()} m',
              sub: 'Niveau de vol',
              color: AppColors.cyan,
              progress: t.altitude / 200,
            ),
            _TelemetryCard(
              icon: Icons.speed_rounded,
              label: 'Vitesse',
              value: '${t.vitesse.toStringAsFixed(1)} m/s',
              sub: 'Vitesse sol',
              color: AppColors.water,
              progress: t.vitesse / 15,
            ),
            _TelemetryCard(
              icon: Icons.wifi_rounded,
              label: 'Signal',
              value: '${t.signalForce.toInt()}%',
              sub: t.signalForce > 70 ? 'Excellent' : 'Correct',
              color: t.signalForce > 70 ? AppColors.green : AppColors.orange,
              progress: t.signalForce / 100,
            ),
            _TelemetryCard(
              icon: Icons.thermostat_rounded,
              label: 'Temp. drone',
              value: '${t.temperature.toInt()}°C',
              sub: t.temperature < 50 ? 'Normal' : 'Élevée',
              color: t.temperature < 50 ? AppColors.green : AppColors.red,
              progress: t.temperature / 80,
            ),
            _TelemetryCard(
              icon: Icons.air_rounded,
              label: 'Vent',
              value: '${t.vent.toStringAsFixed(1)} m/s',
              sub: t.vent < 5 ? 'Favorable' : 'Turbulent',
              color: t.vent < 5 ? AppColors.green : AppColors.orange,
              progress: t.vent / 15,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorsCard(BuildContext context, DroneTelemetry t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt_outlined, color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text('Capteurs actifs', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 14),
          _SensorRow(
            icon: Icons.photo_camera_outlined,
            label: 'Caméra Multispectrale',
            desc: 'Sol · Végétation · Eau',
            active: t.multispectralActif,
            color: AppColors.soil,
          ),
          const Divider(height: 20),
          _SensorRow(
            icon: Icons.thermostat_outlined,
            label: 'Caméra Thermique',
            desc: 'Rejets industriels · Anomalies',
            active: t.thermiqueActif,
            color: AppColors.red,
          ),
          const Divider(height: 20),
          _SensorRow(
            icon: Icons.cloud_outlined,
            label: 'Capteurs Atmosphériques',
            desc: 'SO₂ · H₂S · NH₃ · PM2.5',
            active: t.atmospheriqueActif,
            color: AppColors.air,
          ),
        ],
      ),
    );
  }

  Widget _buildFlightStats(BuildContext context, DroneTelemetry t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text('Statistiques de vol', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatItem('Distance', '${t.distanceParcourue.toStringAsFixed(2)} km'),
              _StatItem('Mission', '${(t.missionProgress * 100).toInt()}%'),
              _StatItem('Alt. moy.', '${t.altitude.toInt()} m'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Animated drone marker ─────────────────────────────────────────────────────

class _DroneMarker extends StatelessWidget {
  final double heading;
  final bool isScanning;
  final Animation<double> pulseAnim;
  final Animation<double> scanAnim;

  const _DroneMarker({
    required this.heading,
    required this.isScanning,
    required this.pulseAnim,
    required this.scanAnim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring
            if (isScanning)
              Container(
                width: 50 + 6 * pulseAnim.value,
                height: 50 + 6 * pulseAnim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withValues(
                      alpha: 0.1 + 0.08 * (1 - pulseAnim.value)),
                ),
              ),
            // Scan sector arc
            if (isScanning)
              AnimatedBuilder(
                animation: scanAnim,
                builder: (_, child) => Transform.rotate(
                  angle: scanAnim.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(54, 54),
                    painter: _ScanSectorPainter(),
                  ),
                ),
              ),
            // Drone body
            Transform.rotate(
              angle: heading,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cyan, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(
                          alpha: 0.3 + 0.2 * pulseAnim.value),
                      blurRadius: 10 + 4 * pulseAnim.value,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flight_rounded,
                  color: AppColors.cyan,
                  size: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScanSectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.cyan.withValues(alpha: 0),
          AppColors.cyan.withValues(alpha: 0.4),
          AppColors.cyan.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.25, 0.5],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Mini stat in telemetry strip ──────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.exo2(
              fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ── Telemetry card ────────────────────────────────────────────────────────────

class _TelemetryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final double progress;

  const _TelemetryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.exo2(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Text(value,
              style: GoogleFonts.exo2(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sensor row ────────────────────────────────────────────────────────────────

class _SensorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final bool active;
  final Color color;

  const _SensorRow({
    required this.icon,
    required this.label,
    required this.desc,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.12)
                : AppColors.cardBorder.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: active ? color : AppColors.textHint, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(desc,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active
                ? AppColors.green.withValues(alpha: 0.12)
                : AppColors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.green : AppColors.red,
                ),
              ),
              const SizedBox(width: 5),
              Text(active ? 'Actif' : 'Inactif',
                  style: GoogleFonts.exo2(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.green : AppColors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stat item ─────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.exo2(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
