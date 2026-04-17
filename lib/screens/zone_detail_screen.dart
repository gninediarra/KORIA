import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';

class ZoneDetailScreen extends StatefulWidget {
  final Zone zone;
  const ZoneDetailScreen({super.key, required this.zone});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final statusColor = AppColors.statusColor(zone.status);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.2),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 72, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                zone.status.toUpperCase(),
                                style: GoogleFonts.exo2(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            zone.type.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      zone.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Analysé ${DateFormat('d MMM à HH:mm', 'fr').format(zone.derniereAnalyse)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.cyan,
              labelColor: AppColors.cyan,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.exo2(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  icon: Icon(Icons.grass_rounded, size: 16, color: AppColors.soil),
                  text: 'Sol',
                ),
                Tab(
                  icon: Icon(Icons.water_rounded, size: 16, color: AppColors.water),
                  text: 'Eau',
                ),
                Tab(
                  icon: Icon(Icons.air_rounded, size: 16, color: AppColors.air),
                  text: 'Air',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _SoilTab(zone: zone),
            _WaterTab(zone: zone),
            _AirTab(zone: zone),
          ],
        ),
      ),
    );
  }
}

class _SoilTab extends StatelessWidget {
  final Zone zone;
  const _SoilTab({required this.zone});

  @override
  Widget build(BuildContext context) {
    final s = zone.soil;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ReadingCard('État du sol', s.etat, AppColors.soil, Icons.grass_rounded),
        const SizedBox(height: 14),
        Row(
          children: [
            _MetricCard('Salinité', '${s.salinite} g/L',
                s.salinite > 4 ? AppColors.red : AppColors.green, 'g/L'),
            const SizedBox(width: 12),
            _MetricCard('pH', '${s.ph}',
                s.ph < 6 ? AppColors.red : AppColors.green, ''),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricCard('Humidité', '${s.humidite}%',
                s.humidite < 20 ? AppColors.orange : AppColors.green, '%'),
            const SizedBox(width: 12),
            _MetricCard(
                'Contamination',
                '${s.contamination}%',
                s.contamination > 50
                    ? AppColors.red
                    : s.contamination > 20
                        ? AppColors.orange
                        : AppColors.green,
                '%'),
          ],
        ),
        const SizedBox(height: 20),
        _ProgressBar('Niveau de contamination', s.contamination / 100,
            AppColors.statusColor(zone.status)),
        const SizedBox(height: 20),
        _RecommendationsCard(zone.recommandations),
      ],
    );
  }
}

class _WaterTab extends StatelessWidget {
  final Zone zone;
  const _WaterTab({required this.zone});

  @override
  Widget build(BuildContext context) {
    final w = zone.water;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ReadingCard('État de l\'eau', w.etat, AppColors.water, Icons.water_rounded),
        const SizedBox(height: 14),
        Row(
          children: [
            _MetricCard('Turbidité', '${w.turbidite} NTU',
                w.turbidite > 40 ? AppColors.red : AppColors.green, 'NTU'),
            const SizedBox(width: 12),
            _MetricCard('pH', '${w.ph}',
                w.ph < 6.5 || w.ph > 8.5 ? AppColors.red : AppColors.green, ''),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricCard('Phosphates', '${w.phosphates} mg/L',
                w.phosphates > 5 ? AppColors.red : AppColors.green, 'mg/L'),
            const SizedBox(width: 12),
            _MetricCard('Température', '${w.temperature}°C',
                w.temperature > 28 ? AppColors.orange : AppColors.green, '°C'),
          ],
        ),
        const SizedBox(height: 20),
        _ProgressBar('Indice de pollution',
            (w.turbidite / 100).clamp(0.0, 1.0), AppColors.statusColor(zone.status)),
        const SizedBox(height: 20),
        _RecommendationsCard(zone.recommandations),
      ],
    );
  }
}

class _AirTab extends StatelessWidget {
  final Zone zone;
  const _AirTab({required this.zone});

  @override
  Widget build(BuildContext context) {
    final a = zone.air;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ReadingCard('Qualité de l\'air', a.etat, AppColors.air, Icons.air_rounded),
        const SizedBox(height: 14),
        Row(
          children: [
            _MetricCard('SO₂', '${a.so2} µg/m³',
                a.so2 > 50 ? AppColors.red : AppColors.green, 'µg/m³'),
            const SizedBox(width: 12),
            _MetricCard('H₂S', '${a.h2s} µg/m³',
                a.h2s > 15 ? AppColors.red : AppColors.green, 'µg/m³'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricCard('NH₃', '${a.nh3} µg/m³',
                a.nh3 > 20 ? AppColors.orange : AppColors.green, 'µg/m³'),
            const SizedBox(width: 12),
            _MetricCard('PM2.5', '${a.pm25} µg/m³',
                a.pm25 > 35 ? AppColors.orange : AppColors.green, 'µg/m³'),
          ],
        ),
        const SizedBox(height: 14),
        _AqiBigCard(aqi: a.aqi),
        const SizedBox(height: 20),
        _RecommendationsCard(zone.recommandations),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  final IconData icon;

  const _ReadingCard(this.title, this.content, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.exo2(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(content,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String unit;

  const _MetricCard(this.label, this.value, this.color, this.unit);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.exo2(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.exo2(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
            Text('${(value * 100).toInt()}%',
                style: GoogleFonts.exo2(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _AqiBigCard extends StatelessWidget {
  final int aqi;
  const _AqiBigCard({required this.aqi});

  @override
  Widget build(BuildContext context) {
    final color = aqi > 200
        ? AppColors.red
        : aqi > 100
            ? AppColors.orange
            : AppColors.green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.12), AppColors.card],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            '$aqi',
            style: GoogleFonts.exo2(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AQI',
                  style: GoogleFonts.exo2(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              Text(
                aqi > 200
                    ? 'Dangereux'
                    : aqi > 150
                        ? 'Très mauvais'
                        : aqi > 100
                            ? 'Mauvais'
                            : aqi > 50
                                ? 'Modéré'
                                : 'Excellent',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
              Text(
                'Indice de qualité de l\'air',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final List<String> items;
  const _RecommendationsCard(this.items);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text(
                'Recommandations IA',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: GoogleFonts.exo2(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyan,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
