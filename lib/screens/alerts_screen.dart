import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/screens/alert_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertSeverity? _filter;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.user!;

    var alerts = app.alertsForRole(user.role);
    if (_filter != null) {
      alerts = alerts.where((a) => a.severite == _filter).toList();
    }

    final unread = alerts.where((a) => !a.lue).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Alertes'),
            if (unread > 0)
              Text(
                '$unread non lues',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => app.markAllAsRead(user.role),
              child: Text(
                'Tout lire',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: alerts.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: alerts.length,
                    itemBuilder: (_, i) => _AlertCard(
                      alert: alerts[i],
                      onTap: () {
                        app.markAsRead(alerts[i].id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AlertDetailScreen(alert: alerts[i]),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'Tout',
            active: _filter == null,
            color: AppColors.cyan,
            onTap: () => setState(() => _filter = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Critique',
            active: _filter == AlertSeverity.critique,
            color: AppColors.red,
            onTap: () => setState(() => _filter = _filter == AlertSeverity.critique
                ? null
                : AlertSeverity.critique),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Avert.',
            active: _filter == AlertSeverity.avertissement,
            color: AppColors.orange,
            onTap: () => setState(
              () => _filter = _filter == AlertSeverity.avertissement
                  ? null
                  : AlertSeverity.avertissement,
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Info',
            active: _filter == AlertSeverity.info,
            color: AppColors.cyan,
            onTap: () => setState(() => _filter =
                _filter == AlertSeverity.info ? null : AlertSeverity.info),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppColors.textHint, size: 52),
          const SizedBox(height: 16),
          Text(
            'Aucune alerte pour ce filtre',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.exo2(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DroneAlert alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = alert.severite.color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: alert.lue ? AppColors.card : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.lue
                ? AppColors.cardBorder
                : color.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(alert.severite.icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                alert.severite.label.toUpperCase(),
                                style: GoogleFonts.exo2(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (!alert.lue)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          alert.titre,
                          style: GoogleFonts.exo2(
                            fontSize: 14,
                            fontWeight: alert.lue
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.description,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.textHint, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      alert.zone,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ),
                  const Icon(Icons.schedule_outlined,
                      color: AppColors.textHint, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(alert.timestamp),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return DateFormat('d MMM', 'fr').format(t);
  }
}
