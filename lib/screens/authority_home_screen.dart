import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/providers/locale_provider.dart';
import 'package:gabeseye/screens/alert_detail_screen.dart';
import 'package:gabeseye/screens/zone_detail_screen.dart';
import 'package:gabeseye/screens/drone_status_screen.dart';

class AuthorityHomeScreen extends StatelessWidget {
  const AuthorityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final locale = context.watch<LocaleProvider>();
    final l = locale.t;
    final user = auth.user!;
    final zones = app.zones;
    final allAlerts = app.alerts.take(5).toList();

    final critical = zones.where((z) => z.status == 'rouge').length;
    final watch = zones.where((z) => z.status == 'orange').length;
    final normal = zones.where((z) => z.status == 'vert').length;
    final unreadAlerts = app.alerts.where((a) => !a.lue).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, user, l),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildKpiRow(context, critical, watch, normal, unreadAlerts),
                const SizedBox(height: 16),
                _buildPollutionMatrix(context, zones),
                const SizedBox(height: 20),
                _buildDroneCard(context, app),
                const SizedBox(height: 16),
                _buildDeadManSwitch(context, zones),
                const SizedBox(height: 16),
                _buildMissionTraceability(context, app),
                const SizedBox(height: 20),
                _buildQuickActions(context, app),
                const SizedBox(height: 20),
                _buildSectionHeader(context, 'Toutes les alertes', Icons.notifications_outlined),
                const SizedBox(height: 12),
                ...allAlerts.map((a) => _AlertTile(alert: a)),
                const SizedBox(height: 16),
                _buildSectionHeader(context, 'Toutes les zones', Icons.location_on_outlined),
                const SizedBox(height: 12),
                ...zones.map((z) => _ZoneTile(zone: z)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AppUser user, String Function(String) l) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? l('home_greeting_morning')
        : now.hour < 18
            ? l('home_greeting_afternoon')
            : l('home_greeting_evening');
    final c = AdaptiveColors.of(context);
    const purple = Color(0xFF8E24AA);

    return SliverAppBar(
      expandedHeight: 110,
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
                    Text('$greeting, ${user.name.split(' ').first}',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.account_balance, color: purple, size: 13),
                        const SizedBox(width: 4),
                        const Text('Autorité · Tableau de bord environnemental',
                            style: TextStyle(fontSize: 12, color: purple)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: purple.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.account_balance, color: purple, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, int critical, int watch, int normal, int unread) {
    return Row(
      children: [
        _KpiCard('Critiques', '$critical', AppColors.red, Icons.warning_rounded),
        const SizedBox(width: 10),
        _KpiCard('Surveillance', '$watch', AppColors.orange, Icons.visibility_rounded),
        const SizedBox(width: 10),
        _KpiCard('Normales', '$normal', AppColors.green, Icons.check_circle_rounded),
        const SizedBox(width: 10),
        _KpiCard('Alertes', '$unread', AppColors.cyan, Icons.notifications_active_rounded),
      ],
    );
  }

  Widget _buildPollutionMatrix(BuildContext context, List<Zone> zones) {
    final c = AdaptiveColors.of(context);
    final avgAqi = zones.isEmpty
        ? 0
        : (zones.map((z) => z.air.aqi).reduce((a, b) => a + b) / zones.length).toInt();
    final avgContam = zones.isEmpty
        ? 0.0
        : zones.map((z) => z.soil.contamination).reduce((a, b) => a + b) / zones.length;
    final avgTurbid = zones.isEmpty
        ? 0.0
        : zones.map((z) => z.water.turbidite).reduce((a, b) => a + b) / zones.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text('Matrice de pollution — Gabès',
                  style: GoogleFonts.exo2(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          _PollutionBar('Qualité Air (AQI)', avgAqi / 400, '$avgAqi AQI',
              AppColors.air, context),
          const SizedBox(height: 10),
          _PollutionBar('Contamination Sol', avgContam / 100,
              '${avgContam.toInt()}%', AppColors.soil, context),
          const SizedBox(height: 10),
          _PollutionBar('Turbidité Eau', avgTurbid / 100,
              '${avgTurbid.toInt()} NTU', AppColors.water, context),
        ],
      ),
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
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: t.status.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
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
                      Text('Drone GE-01',
                          style: GoogleFonts.exo2(
                              fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(color: t.status.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(t.status.label,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: t.status.color, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(t.missionActuelle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: t.missionProgress,
                    backgroundColor: c.cardBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, color: c.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadManSwitch(BuildContext context, List<Zone> zones) {
    final c = AdaptiveColors.of(context);
    final maxSo2 = zones.isEmpty ? 0.0 : zones.map((z) => z.air.so2).reduce((a, b) => a > b ? a : b);
    final triggered = maxSo2 >= 500;
    final nearThreshold = maxSo2 >= 300;
    final color = triggered ? AppColors.red : nearThreshold ? AppColors.orange : AppColors.green;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), c.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: triggered ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  triggered ? Icons.gpp_bad_rounded : Icons.gpp_good_rounded,
                  color: color, size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dead Man\'s Switch — SO₂',
                        style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
                    Text(
                      triggered
                          ? 'DÉCLENCHÉ — Notification ANPE envoyée'
                          : nearThreshold
                              ? 'SURVEILLANCE — Seuil approché'
                              : 'Nominal — Sous le seuil d\'alerte',
                      style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _So2Gauge(value: maxSo2, threshold: 500, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DmsRow('SO₂ actuel', '${maxSo2.toInt()} µg/m³', color),
                    _DmsRow('Seuil de déclenchement', '500 µg/m³', c.textSecondary),
                    _DmsRow('Destinataire', 'ANPE · anpe@environnement.tn', AppColors.cyan),
                    if (triggered)
                      _DmsRow('Notifié le', DateFormat('d MMM yyyy HH:mm', 'fr').format(now), AppColors.orange),
                  ],
                ),
              ),
            ],
          ),
          if (triggered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.green, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Smart contract verrouillé — preuve que l\'État a été prévenu et n\'a pas agi.',
                      style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissionTraceability(BuildContext context, AppProvider app) {
    final c = AdaptiveColors.of(context);
    final t = app.telemetry;
    final now = DateTime.now();
    final missions = [
      (now.subtract(const Duration(hours: 2)), 'Oasis Chenini · Analyse sol', true, '0x3f8a…c21d'),
      (now.subtract(const Duration(hours: 8)), 'Golfe de Gabès · Phosphates', true, '0xa14b…9e07'),
      (now.subtract(const Duration(days: 1)), 'Zone GCT · SO₂ critique', true, '0x7c2f…11aa'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text('Smart Contract de Vol',
                  style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('VERROUILLÉ',
                    style: GoogleFonts.exo2(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.cyan, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Chaque vol est signé au décollage et verrouillé à l\'atterrissage — données inaltérables.',
              style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
          const SizedBox(height: 14),
          if (t.status == DroneStatus.enVol)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flight_takeoff_rounded, color: AppColors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mission en cours · Contrat signé · ${t.missionActuelle}',
                      style: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green),
                    ),
                  ),
                ],
              ),
            ),
          ...missions.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, color: AppColors.green, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.$2, style: GoogleFonts.inter(fontSize: 12, color: c.textPrimary, fontWeight: FontWeight.w500)),
                      Text(DateFormat('d MMM · HH:mm', 'fr').format(m.$1),
                          style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
                    ],
                  ),
                ),
                Text(m.$4, style: GoogleFonts.robotoMono(fontSize: 10, color: c.textHint)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppProvider app) {
    final c = AdaptiveColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actions rapides',
              style: GoogleFonts.exo2(
                  fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              _ActionButton(
                'Lancer mission',
                Icons.flight_takeoff_rounded,
                AppColors.cyan,
                () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mission lancée sur zone critique',
                        style: GoogleFonts.exo2(fontSize: 13)),
                    backgroundColor: AppColors.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ActionButton(
                'Émettre alerte',
                Icons.campaign_rounded,
                AppColors.orange,
                () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Alerte diffusée aux citoyens',
                        style: GoogleFonts.exo2(fontSize: 13)),
                    backgroundColor: AppColors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ActionButton(
                'Rapport ANPE',
                Icons.description_rounded,
                const Color(0xFF8E24AA),
                () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rapport généré pour l\'ANPE',
                        style: GoogleFonts.exo2(fontSize: 13)),
                    backgroundColor: const Color(0xFF8E24AA),
                  ),
                ),
              ),
            ],
          ),
        ],
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
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _KpiCard(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.exo2(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: GoogleFonts.inter(fontSize: 9, color: c.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PollutionBar extends StatelessWidget {
  final String label;
  final double progress;
  final String valueLabel;
  final Color color;
  final BuildContext ctx;
  const _PollutionBar(this.label, this.progress, this.valueLabel, this.color, this.ctx);

  @override
  Widget build(BuildContext ctx2) {
    final c = AdaptiveColors.of(ctx2);
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary)),
            ),
            Text(valueLabel,
                style: GoogleFonts.exo2(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: clamped,
          backgroundColor: c.cardBorder,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.exo2(
                      fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: alert)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: alert.lue ? c.card : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: alert.lue ? c.cardBorder : color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(alert.severite.icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.titre,
                      style: GoogleFonts.exo2(
                          fontSize: 13,
                          fontWeight: alert.lue ? FontWeight.w500 : FontWeight.w700,
                          color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${alert.zone} · ${alert.severite.label}',
                      style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary)),
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
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => ZoneDetailScreen(zone: zone))),
      child: Container(
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
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: c.textPrimary, fontWeight: FontWeight.w500)),
                  Text('${zone.type.label} · AQI ${zone.air.aqi}',
                      style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                zone.status == 'rouge'
                    ? 'CRITIQUE'
                    : zone.status == 'orange'
                        ? 'SURVEILL.'
                        : 'NORMAL',
                style: GoogleFonts.exo2(
                    fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: c.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

class _So2Gauge extends StatelessWidget {
  final double value;
  final double threshold;
  final Color color;
  const _So2Gauge({required this.value, required this.threshold, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final progress = (value / threshold).clamp(0.0, 1.0);
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72, height: 72,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: c.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.toInt()}',
                  style: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
              Text('µg/m³',
                  style: GoogleFonts.inter(fontSize: 9, color: color.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }
}

class _DmsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DmsRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: GoogleFonts.exo2(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

