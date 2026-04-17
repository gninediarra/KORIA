import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/screens/drone_status_screen.dart';
import 'package:gabeseye/screens/alert_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.user!;
    final alerts = app.alertsForRole(user.role).take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, user, app),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildAqiCard(context, app),
                const SizedBox(height: 16),
                _buildStatRow(context, app),
                const SizedBox(height: 20),
                _buildDroneCard(context, app),
                const SizedBox(height: 20),
                _buildSectionHeader(context, 'Alertes récentes', Icons.notifications_outlined),
                const SizedBox(height: 12),
                if (alerts.isEmpty)
                  _buildEmptyAlerts(context)
                else
                  ...alerts.map((a) => _AlertTile(alert: a)),
                const SizedBox(height: 16),
                _buildZonesSummary(context, app),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AppUser user, AppProvider app) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Bonjour'
        : now.hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';

    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      snap: true,
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$greeting, ${user.name.split(' ').first}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      '${user.role.label} · ${DateFormat('EEEE d MMMM', 'fr').format(now)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: user.role.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: user.role.color.withValues(alpha: 0.3)),
                ),
                child: Icon(user.role.icon, color: user.role.color, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAqiCard(BuildContext context, AppProvider app) {
    final aqi = app.zones.map((z) => z.air.aqi).reduce((a, b) => a > b ? a : b);
    final (label, color, icon) = _aqiInfo(aqi);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.air_rounded, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'INDICE QUALITÉ AIR',
                      style: GoogleFonts.exo2(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$aqi',
                      style: GoogleFonts.exo2(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 8),
                      child: Text(
                        'AQI',
                        style: GoogleFonts.exo2(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _AqiGauge(aqi: aqi, color: color),
        ],
      ),
    );
  }

  (String, Color, IconData) _aqiInfo(int aqi) {
    if (aqi <= 50) return ('Excellent', AppColors.green, Icons.sentiment_very_satisfied_rounded);
    if (aqi <= 100) return ('Modéré', AppColors.orange, Icons.sentiment_neutral_rounded);
    if (aqi <= 150) return ('Mauvais', AppColors.orange, Icons.sentiment_dissatisfied_rounded);
    if (aqi <= 200) return ('Très mauvais', AppColors.red, Icons.sentiment_very_dissatisfied_rounded);
    return ('Dangereux', AppColors.red, Icons.warning_rounded);
  }

  Widget _buildStatRow(BuildContext context, AppProvider app) {
    final zones = app.zones;
    final redCount = zones.where((z) => z.status == 'rouge').length;
    final orangeCount = zones.where((z) => z.status == 'orange').length;
    final greenCount = zones.where((z) => z.status == 'vert').length;

    return Row(
      children: [
        _StatCard(
          icon: Icons.grass_rounded,
          label: 'Sol',
          value: '${zones.length} zones',
          sub: '$redCount critique',
          color: AppColors.soil,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.water_rounded,
          label: 'Eau',
          value: '${zones.where((z) => z.water.turbidite > 30).length} alertes',
          sub: 'Turbidité élevée',
          color: AppColors.water,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.cloud_rounded,
          label: 'Air',
          value: '$orangeCount zones',
          sub: '$greenCount ok',
          color: AppColors.air,
        ),
      ],
    );
  }

  Widget _buildDroneCard(BuildContext context, AppProvider app) {
    final t = app.telemetry;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DroneStatusScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: t.status.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: t.status.color.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.flight_rounded,
                  color: t.status.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Drone GE-01',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 8),
                      _StatusDot(color: t.status.color),
                      const SizedBox(width: 4),
                      Text(
                        t.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: t.status.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.missionActuelle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniStat(Icons.battery_charging_full_rounded,
                          '${t.batterie.toInt()}%', AppColors.green),
                      const SizedBox(width: 16),
                      _MiniStat(Icons.height_rounded,
                          '${t.altitude.toInt()}m', AppColors.cyan),
                      const SizedBox(width: 16),
                      _MiniStat(Icons.speed_rounded,
                          '${t.vitesse.toStringAsFixed(1)} km/h', AppColors.orange),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cyan, size: 18),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildEmptyAlerts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.green, size: 24),
          const SizedBox(width: 12),
          Text(
            'Aucune alerte active pour votre zone',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildZonesSummary(BuildContext context, AppProvider app) {
    final zones = app.zones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'État des zones', Icons.location_on_outlined),
        const SizedBox(height: 12),
        ...zones.map((z) => _ZoneTile(zone: z)),
      ],
    );
  }
}

class _AqiGauge extends StatelessWidget {
  final int aqi;
  final Color color;
  const _AqiGauge({required this.aqi, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = (aqi / 400).clamp(0.0, 1.0);
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: GoogleFonts.exo2(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.exo2(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.exo2(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.exo2(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final DroneAlert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = alert.severite.color;
    return GestureDetector(
      onTap: () {
        context.read<AppProvider>().markAsRead(alert.id);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: alert)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: alert.lue ? AppColors.card : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: alert.lue
                ? AppColors.cardBorder
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(alert.severite.icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.titre,
                          style: GoogleFonts.exo2(
                            fontSize: 13,
                            fontWeight:
                                alert.lue ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!alert.lue)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert.zone,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ZoneTile extends StatelessWidget {
  final Zone zone;
  const _ZoneTile({required this.zone});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(zone.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.4), blurRadius: 6)
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              zone.name,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              zone.air.aqi.toString(),
              style: GoogleFonts.exo2(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
