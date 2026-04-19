import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/providers/locale_provider.dart';
import 'package:gabeseye/screens/drone_status_screen.dart';
import 'package:gabeseye/screens/alert_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final locale = context.watch<LocaleProvider>();
    final l = locale.t;
    final user = auth.user!;
    final alerts = app.alertsForRole(user.role).take(3).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, user, app, l, locale.locale.languageCode),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildAqiCard(context, app, l),
                const SizedBox(height: 16),
                _buildStatRow(context, app, l),
                const SizedBox(height: 20),
                _buildDroneCard(context, app),
                const SizedBox(height: 16),
                _buildPartDeRespiration(context, user, app),
                const SizedBox(height: 20),
                _buildSectionHeader(context, l('home_recent_alerts'), Icons.notifications_outlined),
                const SizedBox(height: 12),
                if (alerts.isEmpty)
                  _buildEmptyAlerts(context, l)
                else
                  ...alerts.map((a) => _AlertTile(alert: a)),
                const SizedBox(height: 16),
                _buildZonesSummary(context, app, l),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    AppUser user,
    AppProvider app,
    String Function(String) l,
    String langCode,
  ) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? l('home_greeting_morning')
        : now.hour < 18
            ? l('home_greeting_afternoon')
            : l('home_greeting_evening');
    final c = AdaptiveColors.of(context);

    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      snap: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: c.surface,
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
                      '${user.role.label} · ${DateFormat('EEEE d MMMM', langCode).format(now)}',
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
                  border: Border.all(color: user.role.color.withValues(alpha: 0.3)),
                ),
                child: Icon(user.role.icon, color: user.role.color, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAqiCard(BuildContext context, AppProvider app, String Function(String) l) {
    final c = AdaptiveColors.of(context);
    final aqi = app.zones.isEmpty
        ? 0
        : app.zones.map((z) => z.air.aqi).reduce((a, b) => a > b ? a : b);
    final (label, color, icon) = _aqiInfo(aqi, l);

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
                      l('home_aqi_label'),
                      style: GoogleFonts.exo2(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
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

  (String, Color, IconData) _aqiInfo(int aqi, String Function(String) l) {
    if (aqi <= 50) return (l('aqi_excellent'), AppColors.green, Icons.sentiment_very_satisfied_rounded);
    if (aqi <= 100) return (l('aqi_moderate'), AppColors.orange, Icons.sentiment_neutral_rounded);
    if (aqi <= 150) return (l('aqi_bad'), AppColors.orange, Icons.sentiment_dissatisfied_rounded);
    if (aqi <= 200) return (l('aqi_very_bad'), AppColors.red, Icons.sentiment_very_dissatisfied_rounded);
    return (l('aqi_dangerous'), AppColors.red, Icons.warning_rounded);
  }

  Widget _buildStatRow(BuildContext context, AppProvider app, String Function(String) l) {
    final zones = app.zones;
    final redCount = zones.where((z) => z.status == 'rouge').length;
    final orangeCount = zones.where((z) => z.status == 'orange').length;
    final greenCount = zones.where((z) => z.status == 'vert').length;

    return Row(
      children: [
        _StatCard(
          icon: Icons.grass_rounded,
          label: l('layer_soil'),
          value: '${zones.length} ${l('home_zones_count')}',
          sub: '$redCount ${l('home_critical_count')}',
          color: AppColors.soil,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.water_rounded,
          label: l('layer_water'),
          value: '${zones.where((z) => z.water.turbidite > 30).length} ${l('home_alerts_water')}',
          sub: l('home_turbid'),
          color: AppColors.water,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.cloud_rounded,
          label: l('layer_air'),
          value: '$orangeCount ${l('home_zones_count')}',
          sub: '$greenCount ${l('home_ok')}',
          color: AppColors.air,
        ),
      ],
    );
  }

  Widget _buildDroneCard(BuildContext context, AppProvider app) {
    final c = AdaptiveColors.of(context);
    final t = app.telemetry;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DroneStatusScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: t.status.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.status.color.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.flight_rounded, color: t.status.color, size: 26),
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
            Icon(Icons.chevron_right_rounded, color: c.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cyan, size: 18),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildEmptyAlerts(BuildContext context, String Function(String) l) {
    final c = AdaptiveColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l('home_no_alert'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartDeRespiration(BuildContext context, AppUser user, AppProvider app) {
    final c = AdaptiveColors.of(context);
    const cyan = AppColors.cyan;

    final quartiers = [
      (user.quartier ?? 'Votre quartier', 142, true),
      ('Chott Salem', 118, false),
      ('Chenini', 97, false),
      ('Jara', 85, false),
      ('Boulbaba', 61, false),
    ];
    final maxPts = quartiers.map((q) => q.$2).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cyan.withValues(alpha: 0.07), c.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: cyan, size: 18),
              const SizedBox(width: 8),
              Text('Part de Respiration',
                  style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('SEMAINE',
                    style: GoogleFonts.exo2(fontSize: 9, fontWeight: FontWeight.w700, color: cyan, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Le quartier le plus vigilant obtient un survol drone prioritaire la semaine suivante.',
            style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary),
          ),
          const SizedBox(height: 14),
          ...quartiers.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final q = entry.value;
            final progress = q.$2 / maxPts;
            final rankColor = rank == 1 ? const Color(0xFFFFD700) : rank == 2 ? const Color(0xFFC0C0C0) : rank == 3 ? const Color(0xFFCD7F32) : c.textHint;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank.',
                      style: GoogleFonts.exo2(fontSize: rank <= 3 ? 16 : 12, color: rankColor, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              q.$1,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: q.$3 ? FontWeight.w700 : FontWeight.w500,
                                color: q.$3 ? cyan : c.textPrimary,
                              ),
                            ),
                            if (q.$3) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: cyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('vous',
                                    style: GoogleFonts.exo2(fontSize: 9, color: cyan, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: c.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(rank == 1 ? cyan : c.textHint),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${q.$2} pts',
                      style: GoogleFonts.exo2(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rank == 1 ? cyan : c.textSecondary)),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_rounded, color: Color(0xFFFFD700), size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le gagnant décide : école, jardin public ou marché — le drone survole en priorité.',
                    style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesSummary(BuildContext context, AppProvider app, String Function(String) l) {
    final zones = app.zones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, l('home_zones_state'), Icons.location_on_outlined),
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
    final c = AdaptiveColors.of(context);
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
              backgroundColor: c.cardBorder,
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
    final c = AdaptiveColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
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
                color: c.textSecondary,
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
                color: c.textPrimary,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: c.textSecondary,
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
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
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
    final c = AdaptiveColors.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.exo2(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
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
    final c = AdaptiveColors.of(context);
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
          color: alert.lue ? c.card : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: alert.lue ? c.cardBorder : color.withValues(alpha: 0.3),
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
                            fontWeight: alert.lue ? FontWeight.w500 : FontWeight.w700,
                            color: c.textPrimary,
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
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert.zone,
                    style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textHint, size: 18),
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
    final c = AdaptiveColors.of(context);
    final color = AppColors.statusColor(zone.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              zone.name,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: c.textPrimary,
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
