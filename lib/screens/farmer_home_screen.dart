import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/providers/locale_provider.dart';
import 'package:gabeseye/screens/alert_detail_screen.dart';
import 'package:gabeseye/screens/zone_detail_screen.dart';

class FarmerHomeScreen extends StatelessWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final locale = context.watch<LocaleProvider>();
    final l = locale.t;
    final user = auth.user!;

    final agriZones = app.zones.where((z) => z.type == ZoneType.agricole).toList();
    final displayZones = agriZones.isNotEmpty ? agriZones : app.zones;
    final alerts = app.alertsForRole(UserRole.agriculteur).take(3).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, user, l),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                if (user.parcelle != null) _buildParcelleCard(context, user),
                if (user.parcelle != null) const SizedBox(height: 16),
                _buildSoilOverview(context, displayZones),
                const SizedBox(height: 16),
                _buildSoilDetailRow(context, displayZones),
                const SizedBox(height: 20),
                _buildDroneScanCard(context, app),
                const SizedBox(height: 20),
                _buildSectionHeader(context, 'Alertes agricoles', Icons.notifications_outlined, AppColors.soil),
                const SizedBox(height: 12),
                if (alerts.isEmpty)
                  _buildEmpty(context, 'Aucune alerte active pour votre parcelle')
                else
                  ...alerts.map((a) => _AlertTile(alert: a)),
                const SizedBox(height: 16),
                _buildSectionHeader(context, 'Zones agricoles', Icons.grass_rounded, AppColors.soil),
                const SizedBox(height: 12),
                ...displayZones.map((z) => _ZoneTile(zone: z)),
                const SizedBox(height: 20),
                _buildEcoCard(context),
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
                    Text(
                      '$greeting, ${user.name.split(' ').first}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.agriculture, color: AppColors.soil, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          'Agriculteur · Gabès',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.soil),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.soil.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.soil.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.agriculture, color: AppColors.soil, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParcelleCard(BuildContext context, AppUser user) {
    final c = AdaptiveColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.soil.withValues(alpha: 0.12), AppColors.soil.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.soil.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.soil.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.agriculture, color: AppColors.soil, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.parcelle!,
                  style: GoogleFonts.exo2(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.green, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Enregistrée sur blockchain',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (user.walletAddress != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.cardBorder),
              ),
              child: Text(
                '${user.walletAddress!.substring(0, 6)}…${user.walletAddress!.substring(user.walletAddress!.length - 4)}',
                style: GoogleFonts.robotoMono(fontSize: 10, color: c.textHint),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSoilOverview(BuildContext context, List<Zone> zones) {
    final c = AdaptiveColors.of(context);
    final avgContam = zones.isEmpty
        ? 0.0
        : zones.map((z) => z.soil.contamination).reduce((a, b) => a + b) / zones.length;
    final avgPh = zones.isEmpty
        ? 7.0
        : zones.map((z) => z.soil.ph).reduce((a, b) => a + b) / zones.length;

    final (label, color) = avgContam > 50
        ? ('Contamination critique', AppColors.red)
        : avgContam > 20
            ? ('Surveillance requise', AppColors.orange)
            : ('Sol en bonne santé', AppColors.green);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
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
                    Icon(Icons.grass_rounded, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'SANTÉ DU SOL',
                      style: GoogleFonts.exo2(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: c.textSecondary, letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${avgContam.toInt()}',
                      style: GoogleFonts.exo2(
                        fontSize: 52, fontWeight: FontWeight.w800, color: color, height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: Text('%',
                          style: GoogleFonts.exo2(
                            fontSize: 18, fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.7),
                          )),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'pH moyen : ${avgPh.toStringAsFixed(1)}',
                  style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
          _SoilGauge(contamination: avgContam, color: color),
        ],
      ),
    );
  }

  Widget _buildSoilDetailRow(BuildContext context, List<Zone> zones) {
    if (zones.isEmpty) return const SizedBox.shrink();
    final z = zones.first;

    return Row(
      children: [
        _SoilCard('Salinité', '${z.soil.salinite.toStringAsFixed(1)} g/L',
            Icons.water_drop_outlined, z.soil.salinite > 5 ? AppColors.red : AppColors.green),
        const SizedBox(width: 10),
        _SoilCard('Humidité', '${z.soil.humidite.toInt()}%',
            Icons.opacity_rounded, z.soil.humidite < 20 ? AppColors.orange : AppColors.green),
        const SizedBox(width: 10),
        _SoilCard('pH', z.soil.ph.toStringAsFixed(1),
            Icons.science_outlined, (z.soil.ph < 5.5 || z.soil.ph > 7.5) ? AppColors.orange : AppColors.green),
      ],
    );
  }

  Widget _buildDroneScanCard(BuildContext context, AppProvider app) {
    final c = AdaptiveColors.of(context);
    final t = app.telemetry;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande de scan envoyée — +15 ECT à la validation',
                style: GoogleFonts.exo2(fontSize: 13)),
            backgroundColor: AppColors.soil,
            duration: const Duration(seconds: 3),
          ),
        );
      },
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
              ),
              child: Icon(Icons.flight_rounded, color: t.status.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Demander un scan drone',
                      style: GoogleFonts.exo2(
                          fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Analyse multispectrale de votre parcelle · +50 ECT',
                      style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.soil.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.soil.withValues(alpha: 0.3)),
              ),
              child: Text('+50 ECT',
                  style: GoogleFonts.exo2(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.soil)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, String msg) {
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
          Expanded(child: Text(msg, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildEcoCard(BuildContext context) {
    final c = AdaptiveColors.of(context);
    const ect = Color(0xFF00E676);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ect.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.token_rounded, color: ect, size: 18),
              const SizedBox(width: 8),
              Text('Gagner des EcoTokens',
                  style: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            ('+50 ECT', 'Signaler une anomalie validée', Icons.report_outlined),
            ('+100 ECT', 'Participer à un nettoyage drone', Icons.cleaning_services_rounded),
            ('+15 ECT', 'Demander un scan de parcelle', Icons.flight_rounded),
          ].map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ect.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(e.$1,
                      style: GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w700, color: ect)),
                ),
                const SizedBox(width: 10),
                Icon(e.$3, color: c.textHint, size: 14),
                const SizedBox(width: 6),
                Text(e.$2, style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _SoilGauge extends StatelessWidget {
  final double contamination;
  final Color color;
  const _SoilGauge({required this.contamination, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final progress = (contamination / 100).clamp(0.0, 1.0);
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
            '${progress * 100 ~/ 1}%',
            style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _SoilCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SoilCard(this.label, this.value, this.icon, this.color);

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
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.exo2(
                    fontSize: 10, color: c.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
          ],
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
                color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10),
              ),
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
                  Text(alert.zone, style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary)),
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name,
                      style: GoogleFonts.inter(fontSize: 13, color: c.textPrimary, fontWeight: FontWeight.w500)),
                  Text('Contamination: ${zone.soil.contamination.toInt()}%',
                      style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
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
