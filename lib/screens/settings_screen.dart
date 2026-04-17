import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gabeseye/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _autoRefresh = true;
  bool _soundAlerts = true;
  bool _vibration = true;
  bool _locationAccess = true;
  double _refreshInterval = 5;
  String _language = 'Français';
  String _mapStyle = 'Standard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        children: [
          _buildSection(
            context,
            'Apparence',
            Icons.palette_outlined,
            [
              _buildToggle(
                'Mode sombre',
                'Interface optimisée pour la nuit',
                _darkMode,
                (v) => setState(() => _darkMode = v),
              ),
              _buildDivider(),
              _buildDropdownTile(
                'Langue',
                _language,
                ['Français', 'العربية', 'English'],
                (v) => setState(() => _language = v!),
              ),
              _buildDivider(),
              _buildDropdownTile(
                'Style de carte',
                _mapStyle,
                ['Standard', 'Satellite', 'Sombre'],
                (v) => setState(() => _mapStyle = v!),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            'Données & Synchronisation',
            Icons.sync_outlined,
            [
              _buildToggle(
                'Actualisation automatique',
                'Mise à jour des données en temps réel',
                _autoRefresh,
                (v) => setState(() => _autoRefresh = v),
              ),
              _buildDivider(),
              _buildSliderTile(
                'Intervalle d\'actualisation',
                '${_refreshInterval.toInt()} secondes',
                _refreshInterval,
                3,
                30,
                (v) => setState(() => _refreshInterval = v),
              ),
              _buildDivider(),
              _buildToggle(
                'Accès à la localisation',
                'Afficher votre position sur la carte',
                _locationAccess,
                (v) => setState(() => _locationAccess = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            'Notifications & Alertes',
            Icons.notifications_outlined,
            [
              _buildToggle(
                'Sons d\'alerte',
                'Activer les sons pour les alertes critiques',
                _soundAlerts,
                (v) => setState(() => _soundAlerts = v),
              ),
              _buildDivider(),
              _buildToggle(
                'Vibration',
                'Vibrer lors des nouvelles alertes',
                _vibration,
                (v) => setState(() => _vibration = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            'À propos',
            Icons.info_outline_rounded,
            [
              _buildInfoTile('Version', '1.0.0 (Build 42)'),
              _buildDivider(),
              _buildInfoTile('Drone connecté', 'GabèsEye GE-01'),
              _buildDivider(),
              _buildInfoTile('Dernière mise à jour', '17 Avril 2026'),
              _buildDivider(),
              _buildInfoTile('Backend', 'Non connecté — mode démo'),
              _buildDivider(),
              _buildInfoTile('ANPE Gabès', 'Partenaire institutionnel'),
            ],
          ),
          const SizedBox(height: 20),
          _buildDangerZone(context),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.cyan, size: 16),
            const SizedBox(width: 7),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggle(
      String label, String sub, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.cyan,
            inactiveThumbColor: AppColors.textHint,
            inactiveTrackColor: AppColors.cardBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
      String label,
      String value,
      List<String> options,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: AppColors.card,
            underline: const SizedBox.shrink(),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.cyan,
              fontWeight: FontWeight.w600,
            ),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String label,
    String valueLabel,
    double value,
    double min,
    double max,
    void Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                valueLabel,
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 1).toInt(),
            activeColor: AppColors.cyan,
            inactiveColor: AppColors.cardBorder,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 0, indent: 16, endIndent: 16);
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                'ZONE CRITIQUE',
                style: GoogleFonts.exo2(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.red,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showResetDialog(context),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.red, size: 18),
              label: Text(
                'Réinitialiser les données locales',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: AppColors.red, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          'Réinitialiser ?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Text(
          'Cette action supprimera toutes les données locales. Les données du serveur ne seront pas affectées.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Données réinitialisées',
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                  ),
                  backgroundColor: AppColors.card,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text(
              'Réinitialiser',
              style: GoogleFonts.inter(
                color: AppColors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
