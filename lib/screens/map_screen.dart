import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/providers/locale_provider.dart';
import 'package:gabeseye/screens/zone_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapCtrl = MapController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final locale = context.watch<LocaleProvider>();
    final c = AdaptiveColors.of(context);
    final l = locale.t;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: const MapOptions(
              initialCenter: LatLng(33.8839, 10.0982),
              initialZoom: 11.5,
              minZoom: 9,
              maxZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gabeseye.app',
              ),
              PolygonLayer(
                polygons: app.zones
                    .where((z) => z.polygon.isNotEmpty)
                    .map((z) => _buildPolygon(z, app.mapLayer))
                    .toList(),
              ),
              MarkerLayer(
                markers: app.zones
                    .map((z) => _buildZoneMarker(context, z, c))
                    .toList(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: app.telemetry.position,
                    width: 44,
                    height: 44,
                    child: _DroneMarker(status: app.telemetry.status),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map_rounded,
                            color: AppColors.cyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l('map_title'),
                          style: GoogleFonts.exo2(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary),
                        ),
                        const Spacer(),
                        _LiveBadge(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LayerToggle(
                    selected: app.mapLayer,
                    onChanged: app.setMapLayer,
                    l: l,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 90,
            left: 16,
            child: _Legend(l: l),
          ),

          Positioned(
            bottom: 90,
            right: 16,
            child: _DroneMiniInfo(app: app),
          ),

          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: _ZoneStatusStrip(zones: app.zones, l: l),
          ),
        ],
      ),
    );
  }

  Polygon _buildPolygon(Zone zone, String layer) {
    Color fill;
    Color border;

    if (layer == 'sol') {
      fill = zone.soil.contamination > 50
          ? AppColors.redZone
          : zone.soil.contamination > 20
              ? AppColors.orangeZone
              : AppColors.greenZone;
      border = zone.soil.contamination > 50
          ? AppColors.red
          : zone.soil.contamination > 20
              ? AppColors.orange
              : AppColors.green;
    } else if (layer == 'eau') {
      fill = zone.water.turbidite > 50
          ? AppColors.redZone
          : zone.water.turbidite > 25
              ? AppColors.orangeZone
              : AppColors.greenZone;
      border = zone.water.turbidite > 50
          ? AppColors.red
          : zone.water.turbidite > 25
              ? AppColors.orange
              : AppColors.green;
    } else {
      fill = AppColors.statusZoneColor(zone.status);
      border = AppColors.statusColor(zone.status);
    }

    return Polygon(
      points: zone.polygon,
      color: fill,
      borderColor: border,
      borderStrokeWidth: 1.5,
    );
  }

  Marker _buildZoneMarker(BuildContext context, Zone zone, AdaptiveColors c) {
    final color = AppColors.statusColor(zone.status);
    return Marker(
      point: zone.center,
      width: 130,
      height: 44,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ZoneDetailScreen(zone: zone)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.8),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      zone.name.split(' ').take(2).join(' '),
                      style: GoogleFonts.exo2(
                          fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // triangle pointer
            CustomPaint(painter: _TrianglePainter(color: color), size: const Size(10, 5)),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.92);
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

class _ZoneStatusStrip extends StatelessWidget {
  final List<Zone> zones;
  final String Function(String) l;
  const _ZoneStatusStrip({required this.zones, required this.l});

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) return const SizedBox.shrink();
    final c = AdaptiveColors.of(context);
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: zones.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final zone = zones[i];
          final color = AppColors.statusColor(zone.status);
          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ZoneDetailScreen(zone: zone))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        zone.name.split(' ').take(2).join(' '),
                        style: GoogleFonts.exo2(
                            fontSize: 11, fontWeight: FontWeight.w700, color: c.textPrimary),
                      ),
                      Text(
                        zone.status.toUpperCase(),
                        style: GoogleFonts.exo2(
                            fontSize: 9, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DroneMarker extends StatefulWidget {
  final DroneStatus status;
  const _DroneMarker({required this.status});

  @override
  State<_DroneMarker> createState() => _DroneMarkerState();
}

class _DroneMarkerState extends State<_DroneMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.7, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44 * _pulse.value,
            height: 44 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: 0.1 * _pulse.value),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c.bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyan, width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.4), blurRadius: 8)
              ],
            ),
            child: const Icon(Icons.flight_rounded,
                color: AppColors.cyan, size: 16),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red.withValues(alpha: 0.5 + _ctrl.value * 0.5),
            ),
          ),
          const SizedBox(width: 5),
          Text('LIVE',
              style: GoogleFonts.exo2(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.red,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  final String Function(String) l;

  const _LayerToggle(
      {required this.selected, required this.onChanged, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          _LayerBtn('sol', Icons.grass_rounded, l('map_layer_soil'),
              AppColors.soil, selected, onChanged),
          _LayerBtn('eau', Icons.water_rounded, l('map_layer_water'),
              AppColors.water, selected, onChanged),
          _LayerBtn('air', Icons.air_rounded, l('map_layer_air'),
              AppColors.air, selected, onChanged),
        ],
      ),
    );
  }
}

class _LayerBtn extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  final String selected;
  final void Function(String) onChanged;

  const _LayerBtn(
      this.id, this.icon, this.label, this.color, this.selected, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final active = selected == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? Border.all(color: color.withValues(alpha: 0.4)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? color : c.textHint, size: 16),
              const SizedBox(width: 5),
              Text(label,
                  style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? color : c.textHint)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String Function(String) l;
  const _Legend({required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l('map_legend'),
            style: GoogleFonts.exo2(
                fontSize: 9,
                color: c.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          _LegendItem(AppColors.red, l('map_critical')),
          _LegendItem(AppColors.orange, l('map_watch')),
          _LegendItem(AppColors.green, l('map_normal')),
          _LegendItem(AppColors.cyan, l('map_drone')),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: color, width: 1.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
        ],
      ),
    );
  }
}

class _DroneMiniInfo extends StatelessWidget {
  final AppProvider app;
  const _DroneMiniInfo({required this.app});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final t = app.telemetry;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flight_rounded, color: AppColors.cyan, size: 13),
              const SizedBox(width: 4),
              Text('GE-01',
                  style: GoogleFonts.exo2(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyan)),
            ],
          ),
          const SizedBox(height: 5),
          _MiniRow('Alt', '${t.altitude.toInt()}m'),
          _MiniRow('Bat', '${t.batterie.toInt()}%'),
          _MiniRow('Vit', '${t.vitesse.toStringAsFixed(1)}km/h'),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final String label;
  final String value;
  const _MiniRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(label,
                style: GoogleFonts.exo2(
                    fontSize: 10,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          Text(value,
              style: GoogleFonts.exo2(
                  fontSize: 10,
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
