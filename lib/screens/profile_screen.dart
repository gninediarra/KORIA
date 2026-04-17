import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/screens/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.user!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        children: [
          _buildProfileCard(context, user),
          const SizedBox(height: 20),
          _buildStatsRow(context, app, user),
          const SizedBox(height: 20),
          _buildNotifSection(context),
          const SizedBox(height: 20),
          _buildMenuSection(context),
          const SizedBox(height: 20),
          _buildLogoutButton(context, auth),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (user.role.color as Color).withValues(alpha: 0.12),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (user.role.color as Color).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: (user.role.color as Color).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: (user.role.color as Color).withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (user.role.color as Color).withValues(alpha: 0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Icon(user.role.icon,
                color: user.role.color as Color, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name as String,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (user.role.color as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.label as String,
                    style: GoogleFonts.exo2(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: user.role.color as Color,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email as String,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (user.quartier != null || user.parcelle != null)
                  Text(
                    (user.quartier ?? user.parcelle) as String,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AppProvider app, user) {
    final roleAlerts = app.alertsForRole(user.role);
    final unread = roleAlerts.where((a) => !a.lue).length;
    final critical =
        roleAlerts.where((a) => a.severite.name == 'critique').length;

    return Row(
      children: [
        _StatCard2(
            label: 'Alertes reçues',
            value: '${roleAlerts.length}',
            icon: Icons.notifications_outlined,
            color: AppColors.cyan),
        const SizedBox(width: 12),
        _StatCard2(
            label: 'Non lues',
            value: '$unread',
            icon: Icons.mark_email_unread_outlined,
            color: AppColors.orange),
        const SizedBox(width: 12),
        _StatCard2(
            label: 'Critiques',
            value: '$critical',
            icon: Icons.warning_amber_rounded,
            color: AppColors.red),
      ],
    );
  }

  Widget _buildNotifSection(BuildContext context) {
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
              const Icon(Icons.notifications_active_outlined,
                  color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              Text('Notifications',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 14),
          _NotifToggle(
              label: 'Alertes critiques', sub: 'Immédiat', value: true),
          const Divider(height: 20),
          _NotifToggle(
              label: 'Rapports quotidiens',
              sub: 'Chaque matin à 7h00',
              value: true),
          const Divider(height: 20),
          _NotifToggle(
              label: 'Nouvelles missions drone',
              sub: 'Début de scan',
              value: false),
          const Divider(height: 20),
          _NotifToggle(
              label: 'Qualité de l\'air',
              sub: 'Quand AQI > 100',
              value: true),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.settings_outlined,
            label: 'Paramètres',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const Divider(height: 0),
          _MenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Aide & Support',
            onTap: () {},
          ),
          const Divider(height: 0),
          _MenuItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Politique de confidentialité',
            onTap: () {},
          ),
          const Divider(height: 0),
          _MenuItem(
            icon: Icons.info_outline_rounded,
            label: 'À propos de GabèsEye v1.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          auth.logout();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.red),
        label: Text(
          'Se déconnecter',
          style: GoogleFonts.exo2(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.red, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _StatCard2 extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard2({
    required this.label,
    required this.value,
    required this.icon,
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
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.exo2(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifToggle extends StatefulWidget {
  final String label;
  final String sub;
  final bool value;

  const _NotifToggle({
    required this.label,
    required this.sub,
    required this.value,
  });

  @override
  State<_NotifToggle> createState() => _NotifToggleState();
}

class _NotifToggleState extends State<_NotifToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.sub,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
          activeColor: AppColors.cyan,
          inactiveThumbColor: AppColors.textHint,
          inactiveTrackColor: AppColors.cardBorder,
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
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
