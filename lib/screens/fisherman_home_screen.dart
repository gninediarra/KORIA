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

class FishermanHomeScreen extends StatelessWidget {
  const FishermanHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final locale = context.watch<LocaleProvider>();
    final l = locale.t;
    final user = auth.user!;

    final waterZones = app.zones
        .where((z) => z.type == ZoneType.maritime || z.type == ZoneType.cotier)
        .toList();
    final displayZones = waterZones.isNotEmpty ? waterZones : app.zones;
    final alerts = app.alertsForRole(UserRole.pecheur).take(3).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, user, l),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                if (user.parcelle != null) _buildZonePecheCard(context, user),
                if (user.parcelle != null) const SizedBox(height: 16),
                if (user.parcelle != null) _buildHistoriqueEauCard(context, displayZones),
                if (user.parcelle != null) const SizedBox(height: 16),
                _buildPasseportZoneCard(context, user),
                const SizedBox(height: 16),
                _buildWaterOverview(context, displayZones),
                const SizedBox(height: 16),
                _buildWaterDetailRow(context, displayZones),
                const SizedBox(height: 20),
                _buildFishingZoneStatus(context, displayZones),
                const SizedBox(height: 20),
                _buildSectionHeader(context, 'Alertes de pêche', Icons.notifications_outlined, AppColors.water),
                const SizedBox(height: 12),
                if (alerts.isEmpty)
                  _buildEmpty(context, 'Aucune alerte active pour votre zone de pêche')
                else
                  ...alerts.map((a) => _AlertTile(alert: a)),
                const SizedBox(height: 16),
                _buildSectionHeader(context, 'Zones maritimes', Icons.water_rounded, AppColors.water),
                const SizedBox(height: 12),
                ...displayZones.map((z) => _ZoneTile(zone: z)),
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
                    Text('$greeting, ${user.name.split(' ').first}',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.anchor_rounded, color: AppColors.water, size: 13),
                        const SizedBox(width: 4),
                        Text('Pêcheur · Golfe de Gabès',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.water)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.water.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.water.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.set_meal, color: AppColors.water, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZonePecheCard(BuildContext context, AppUser user) {
    final c = AdaptiveColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.water.withValues(alpha: 0.12), AppColors.water.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.water.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.water.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.anchor_rounded, color: AppColors.water, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.parcelle!,
                    style: GoogleFonts.exo2(
                        fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.green, size: 13),
                    const SizedBox(width: 4),
                    Text('Zone enregistrée sur blockchain',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.green)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriqueEauCard(BuildContext context, List<Zone> zones) {
    final c = AdaptiveColors.of(context);
    const blockchain = AppColors.water;
    final now = DateTime.now();
    final snapshots = [
      (now.subtract(const Duration(days: 0)),  zones.isNotEmpty ? zones.first.water.turbidite : 18.0,  'vert'),
      (now.subtract(const Duration(days: 30)), zones.isNotEmpty ? zones.first.water.turbidite + 12 : 30.0, 'orange'),
      (now.subtract(const Duration(days: 60)), zones.isNotEmpty ? zones.first.water.turbidite + 5 : 23.0,  'vert'),
      (now.subtract(const Duration(days: 90)), zones.isNotEmpty ? zones.first.water.turbidite + 35 : 53.0, 'rouge'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [blockchain.withValues(alpha: 0.07), c.card],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: blockchain.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_edu_rounded, color: blockchain, size: 18),
              const SizedBox(width: 8),
              Text('Historique Qualité Eau · Blockchain',
                  style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: blockchain.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('IMMUABLE',
                    style: GoogleFonts.exo2(fontSize: 9, fontWeight: FontWeight.w700, color: blockchain, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Chaque mesure est hashée — preuve horodatée contre la pollution industrielle.',
              style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
          const SizedBox(height: 14),
          ...snapshots.map((snap) {
            final color = snap.$3 == 'vert' ? AppColors.green : snap.$3 == 'orange' ? AppColors.orange : AppColors.red;
            final hash = '0x${snap.$1.millisecondsSinceEpoch.toRadixString(16).substring(0, 8)}…';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Column(children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)])),
                    if (snap != snapshots.last)
                      Container(width: 1, height: 22, color: c.cardBorder),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(DateFormat('d MMM yyyy', 'fr').format(snap.$1),
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.textPrimary)),
                            Text('Turbidité: ${snap.$2.toInt()} NTU',
                                style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
                          ]),
                        ),
                        Row(children: [
                          const Icon(Icons.link_rounded, size: 11, color: AppColors.water),
                          const SizedBox(width: 3),
                          Text(hash, style: GoogleFonts.robotoMono(fontSize: 10, color: c.textHint)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.green, size: 13),
            const SizedBox(width: 6),
            Text('Preuve juridique opposable · GabèsEye Blockchain',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  Widget _buildPasseportZoneCard(BuildContext context, AppUser user) {
    final c = AdaptiveColors.of(context);
    final pts = user.nadhafaPoints;
    final unlocked = pts >= 1500;
    const nadhafa = Color(0xFFFFAB00);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? AppColors.green.withValues(alpha: 0.4) : c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: (unlocked ? AppColors.green : nadhafa).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(unlocked ? Icons.folder_open_rounded : Icons.lock_rounded,
                    color: unlocked ? AppColors.green : nadhafa, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Passeport Zone de Pêche',
                      style: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  Text(unlocked ? 'Rapport détaillé déverrouillé' : 'Rapport détaillé verrouillé',
                      style: GoogleFonts.inter(fontSize: 12,
                          color: unlocked ? AppColors.green : c.textSecondary)),
                ]),
              ),
              if (unlocked) const Icon(Icons.verified_rounded, color: AppColors.green, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          if (unlocked) ...[
            _PecheRow(Icons.opacity_rounded,       AppColors.water,  'Phosphates (30j)', 'Courbe stable · moy. 2.1 mg/L'),
            _PecheRow(Icons.thermostat_rounded,    AppColors.orange, 'Température eau',  '24.3°C — Zone favorable'),
            _PecheRow(Icons.biotech_rounded,       AppColors.green,  'Biomasse estimée', 'Bonne — Secteur actif'),
            _PecheRow(Icons.warning_amber_rounded, AppColors.red,    'Zones interdites', '1 secteur GCT fermé actuellement'),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: nadhafa.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: nadhafa.withValues(alpha: 0.2)),
              ),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.blur_on_rounded, color: AppColors.cyan, size: 16),
                  const SizedBox(width: 8),
                  Text('Phosphates 30j, biomasse, zones interdites…',
                      style: GoogleFonts.inter(fontSize: 12, color: c.textHint)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$pts / 1500 pts',
                        style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: nadhafa)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (pts / 1500).clamp(0.0, 1.0),
                        backgroundColor: c.cardBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(nadhafa),
                        minHeight: 6,
                      ),
                    ),
                  ])),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Paiement 10 TND → rapport déverrouillé',
                          style: GoogleFonts.exo2(fontSize: 13)),
                          backgroundColor: AppColors.green),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
                      ),
                      child: Text('10 TND',
                          style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
                    ),
                  ),
                ]),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaterOverview(BuildContext context, List<Zone> zones) {
    final c = AdaptiveColors.of(context);
    final avgTurbidity = zones.isEmpty
        ? 0.0
        : zones.map((z) => z.water.turbidite).reduce((a, b) => a + b) / zones.length;
    final avgPh = zones.isEmpty
        ? 7.0
        : zones.map((z) => z.water.ph).reduce((a, b) => a + b) / zones.length;

    final (label, color) = avgTurbidity > 50
        ? ('Pêche déconseillée', AppColors.red)
        : avgTurbidity > 25
            ? ('Surveillance requise', AppColors.orange)
            : ('Zone sûre pour la pêche', AppColors.green);

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
                    Icon(Icons.water_rounded, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'QUALITÉ DE L\'EAU',
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
                    Text('${avgTurbidity.toInt()}',
                        style: GoogleFonts.exo2(
                            fontSize: 52, fontWeight: FontWeight.w800, color: color, height: 1)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: Text('NTU',
                          style: GoogleFonts.exo2(
                              fontSize: 16, fontWeight: FontWeight.w600,
                              color: color.withValues(alpha: 0.7))),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Text('pH moyen : ${avgPh.toStringAsFixed(1)}',
                    style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary)),
              ],
            ),
          ),
          _TurbidityGauge(turbidity: avgTurbidity, color: color),
        ],
      ),
    );
  }

  Widget _buildWaterDetailRow(BuildContext context, List<Zone> zones) {
    if (zones.isEmpty) return const SizedBox.shrink();
    final z = zones.first;

    return Row(
      children: [
        _WaterCard('Phosphates', '${z.water.phosphates.toStringAsFixed(1)} mg/L',
            Icons.science_outlined, z.water.phosphates > 5 ? AppColors.orange : AppColors.green),
        const SizedBox(width: 10),
        _WaterCard('Température', '${z.water.temperature.toStringAsFixed(1)}°C',
            Icons.thermostat_rounded, z.water.temperature > 30 ? AppColors.red : AppColors.cyan),
        const SizedBox(width: 10),
        _WaterCard('pH', z.water.ph.toStringAsFixed(1),
            Icons.water_drop_outlined, (z.water.ph < 6.5 || z.water.ph > 8.5) ? AppColors.orange : AppColors.green),
      ],
    );
  }

  Widget _buildFishingZoneStatus(BuildContext context, List<Zone> zones) {
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
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.water, size: 18),
              const SizedBox(width: 8),
              Text('Zones de pêche recommandées',
                  style: GoogleFonts.exo2(
                      fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...[
            ('Secteur Sud-Est du golfe', AppColors.green, 'Sûre'),
            ('Côte de Sidi Boulbaba', AppColors.green, 'Sûre'),
            ('Nord du port de Gabès', AppColors.orange, 'Surveillance'),
            ('Secteur GCT — rayon 2 km', AppColors.red, 'Interdite'),
          ].map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: e.$2, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(e.$1,
                        style: GoogleFonts.inter(fontSize: 13, color: c.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: e.$2.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(e.$3,
                      style: GoogleFonts.exo2(
                          fontSize: 11, fontWeight: FontWeight.w600, color: e.$2)),
                ),
              ],
            ),
          )),
        ],
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
}

class _TurbidityGauge extends StatelessWidget {
  final double turbidity;
  final Color color;
  const _TurbidityGauge({required this.turbidity, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final progress = (turbidity / 100).clamp(0.0, 1.0);
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
          Text('${(progress * 100).toInt()}%',
              style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _WaterCard(this.label, this.value, this.icon, this.color);

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
                  Text('Turbidité: ${zone.water.turbidite.toInt()} NTU',
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

class _PecheRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _PecheRow(this.icon, this.color, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
                Text(value, style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
