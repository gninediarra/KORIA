import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/app_provider.dart';

class DroneStatusScreen extends StatelessWidget {
  const DroneStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final t = app.telemetry;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Drone GE-01'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.status.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: t.status.color.withValues(alpha: 0.5),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  t.status.label,
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.status.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        children: [
          _buildMissionCard(context, t),
          const SizedBox(height: 16),
          _buildTelemetryGrid(context, t),
          const SizedBox(height: 16),
          _buildSensorsCard(context, t),
          const SizedBox(height: 16),
          _buildMiniMap(context, t),
          const SizedBox(height: 16),
          _buildFlightStats(context, t),
        ],
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context, DroneTelemetry t) {
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
              Text(
                'MISSION EN COURS',
                style: GoogleFonts.exo2(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${(t.missionProgress * 100).toInt()}%',
                style: GoogleFonts.exo2(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.missionActuelle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
              Text(
                'Distance : ${t.distanceParcourue.toStringAsFixed(1)} km',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Pos : ${t.position.latitude.toStringAsFixed(4)}°N, ${t.position.longitude.toStringAsFixed(4)}°E',
                style: Theme.of(context).textTheme.bodyMedium,
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
            const Icon(Icons.sensors_rounded,
                color: AppColors.cyan, size: 18),
            const SizedBox(width: 8),
            Text('Télémétrie en temps réel',
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
              sub: t.batterie > 50
                  ? 'Suffisant'
                  : t.batterie > 20
                      ? 'Faible'
                      : 'Critique',
              color: t.batterie > 50
                  ? AppColors.green
                  : t.batterie > 20
                      ? AppColors.orange
                      : AppColors.red,
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
              value: '${t.vitesse.toStringAsFixed(1)} km/h',
              sub: 'Vitesse sol',
              color: AppColors.water,
              progress: t.vitesse / 30,
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
              value: '${t.vent.toInt()} km/h',
              sub: t.vent < 20 ? 'Favorable' : 'Turbulent',
              color: t.vent < 20 ? AppColors.green : AppColors.orange,
              progress: t.vent / 50,
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
              const Icon(Icons.camera_alt_outlined,
                  color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text('Capteurs actifs',
                  style: Theme.of(context).textTheme.headlineSmall),
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
            desc: 'Rejets · Anomalies temp.',
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

  Widget _buildMiniMap(BuildContext context, DroneTelemetry t) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: t.position,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.gabeseye.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: t.position,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flight_rounded,
                      color: AppColors.cyan, size: 18),
                ),
              ),
            ],
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
              const Icon(Icons.route_rounded,
                  color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text('Statistiques de vol',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatItem('Distance', '${t.distanceParcourue.toStringAsFixed(1)} km'),
              _StatItem('Mission', '${(t.missionProgress * 100).toInt()}%'),
              _StatItem('Alt. moy.', '${t.altitude.toInt()} m'),
            ],
          ),
        ],
      ),
    );
  }
}

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
              Text(
                label,
                style: GoogleFonts.exo2(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.exo2(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
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
          child: Icon(icon,
              color: active ? color : AppColors.textHint, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
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
              Text(
                active ? 'Actif' : 'Inactif',
                style: GoogleFonts.exo2(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.green : AppColors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.exo2(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
