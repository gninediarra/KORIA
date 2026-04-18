import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/providers/locale_provider.dart';
import 'package:gabeseye/data/mock_data.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final locale = context.watch<LocaleProvider>();
    final l = locale.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(l('reports_title')),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AdaptiveColors.of(context).textSecondary,
          labelStyle: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: l('reports_tab_air')),
            Tab(text: l('reports_tab_contamination')),
            Tab(text: l('reports_tab_summary')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AqiTab(l: l),
          _ContaminationTab(app: app, l: l),
          _SummaryTab(app: app, l: l),
        ],
      ),
    );
  }
}

class _AqiTab extends StatelessWidget {
  final String Function(String) l;
  const _AqiTab({required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final data = MockData.aqiHistory;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      children: [
        _buildHeader(context, l('reports_aqi_evolution'), Icons.show_chart_rounded),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (_) => FlLine(color: c.divider, strokeWidth: 1),
                getDrawingVerticalLine: (_) => FlLine(color: c.divider, strokeWidth: 0.5),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: GoogleFonts.exo2(fontSize: 10, color: c.textHint),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      return Text(
                        data[i]['jour'] as String,
                        style: GoogleFonts.exo2(
                          fontSize: 10,
                          color: c.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: 400,
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), (e.value['aqi'] as int).toDouble()))
                      .toList(),
                  isCurved: true,
                  color: AppColors.cyan,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, _, _) {
                      final aqi = spot.y.toInt();
                      final color = aqi > 200
                          ? AppColors.red
                          : aqi > 100
                              ? AppColors.orange
                              : AppColors.green;
                      return FlDotCirclePainter(
                        radius: 5,
                        color: color,
                        strokeColor: c.bg,
                        strokeWidth: 2,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.cyan.withValues(alpha: 0.06),
                  ),
                ),
                LineChartBarData(
                  spots: List.generate(7, (i) => FlSpot(i.toDouble(), 100)),
                  isCurved: false,
                  color: AppColors.orange.withValues(alpha: 0.4),
                  barWidth: 1,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Legend(AppColors.cyan, l('reports_aqi_legend')),
            const SizedBox(width: 16),
            _Legend(AppColors.orange, l('reports_threshold')),
          ],
        ),
        const SizedBox(height: 20),
        _buildAqiScale(context, c),
      ],
    );
  }

  Widget _buildAqiScale(BuildContext context, AdaptiveColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l('reports_aqi_scale'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ...[
            ('0–50', l('aqi_excellent'), AppColors.green),
            ('51–100', l('aqi_moderate'), AppColors.orange),
            ('101–150', l('aqi_sensitive'), AppColors.orange),
            ('151–200', l('aqi_bad'), AppColors.red),
            ('200+', l('aqi_dangerous'), AppColors.red),
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: e.$3.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      e.$1,
                      style: GoogleFonts.exo2(
                          fontSize: 11, fontWeight: FontWeight.w700, color: e.$3),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.$2,
                      style: GoogleFonts.inter(fontSize: 13, color: c.textPrimary),
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

class _ContaminationTab extends StatelessWidget {
  final AppProvider app;
  final String Function(String) l;
  const _ContaminationTab({required this.app, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final data = MockData.contaminationByZone;
    final zones = app.zones;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      children: [
        _buildHeader(context, l('reports_contamination'), Icons.bar_chart_rounded),
        const SizedBox(height: 16),
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: GoogleFonts.exo2(fontSize: 9, color: c.textHint),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          data[i]['zone'] as String,
                          style: GoogleFonts.exo2(
                            fontSize: 9,
                            color: c.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (_) => FlLine(color: c.divider, strokeWidth: 0.8),
                getDrawingVerticalLine: (_) => FlLine(color: Colors.transparent),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                final val = (e.value['valeur'] as double);
                final color = val > 60
                    ? AppColors.red
                    : val > 30
                        ? AppColors.orange
                        : AppColors.green;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: val,
                      color: color,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: c.cardBorder,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...zones.map((z) => _ZoneStatRow(zone: z)),
      ],
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final AppProvider app;
  final String Function(String) l;
  const _SummaryTab({required this.app, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final zones = app.zones;
    final rouge = zones.where((z) => z.status == 'rouge').length;
    final orange = zones.where((z) => z.status == 'orange').length;
    final vert = zones.where((z) => z.status == 'vert').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      children: [
        _buildHeader(context, l('reports_summary'), Icons.pie_chart_outline_rounded),
        const SizedBox(height: 16),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        value: rouge.toDouble(),
                        color: AppColors.red,
                        title: '$rouge',
                        radius: 50,
                        titleStyle: GoogleFonts.exo2(
                            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: orange.toDouble(),
                        color: AppColors.orange,
                        title: '$orange',
                        radius: 50,
                        titleStyle: GoogleFonts.exo2(
                            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: vert.toDouble(),
                        color: AppColors.green,
                        title: '$vert',
                        radius: 50,
                        titleStyle: GoogleFonts.exo2(
                            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PieLegend(AppColors.red, l('reports_pie_critical'), '$rouge ${l('reports_zones')}'),
                    const SizedBox(height: 12),
                    _PieLegend(AppColors.orange, l('reports_pie_watch'), '$orange ${l('reports_zones')}'),
                    const SizedBox(height: 12),
                    _PieLegend(AppColors.green, l('reports_pie_normal'), '$vert ${l('reports_zones')}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildKpiGrid(context, zones.length, rouge),
        const SizedBox(height: 20),
        _buildLastScanCard(context, c),
      ],
    );
  }

  Widget _buildKpiGrid(BuildContext context, int total, int rouge) {
    return Row(
      children: [
        _KpiCard(l('reports_total_zones'), '$total', AppColors.cyan),
        const SizedBox(width: 12),
        _KpiCard(
            l('reports_active_alerts'),
            '${MockData.alerts.where((a) => a.severite == AlertSeverity.critique).length}',
            AppColors.red),
        const SizedBox(width: 12),
        _KpiCard(l('reports_drone_missions'), '14', AppColors.green),
      ],
    );
  }

  Widget _buildLastScanCard(BuildContext context, AdaptiveColors c) {
    final ago = l('reports_ago');
    String timeAgo(String duration) =>
        ago.isEmpty ? duration : '$ago $duration';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text(l('reports_last_scans'), style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            ('Secteur GCT', timeAgo('8 min'), AppColors.red),
            ('Zone Portuaire', timeAgo('15 min'), AppColors.orange),
            ('Oasis Chenini', timeAgo('22 min'), AppColors.orange),
            ('Gabès-Ville', timeAgo('5 min'), AppColors.green),
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.$1,
                      style: GoogleFonts.inter(fontSize: 13, color: c.textPrimary),
                    ),
                  ),
                  Text(
                    e.$2,
                    style: GoogleFonts.inter(fontSize: 12, color: c.textHint),
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

// Shared helpers

Widget _buildHeader(BuildContext context, String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, color: AppColors.cyan, size: 20),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
    ],
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary)),
      ],
    );
  }
}

class _ZoneStatRow extends StatelessWidget {
  final Zone zone;
  const _ZoneStatRow({required this.zone});

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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              zone.name,
              style: GoogleFonts.inter(fontSize: 13, color: c.textPrimary),
            ),
          ),
          Text(
            '${zone.soil.contamination.toInt()}%',
            style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String sub;
  const _PieLegend(this.color, this.label, this.sub);

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.exo2(
                    fontSize: 12, fontWeight: FontWeight.w600, color: c.textPrimary)),
            Text(sub, style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.exo2(fontSize: 26, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
