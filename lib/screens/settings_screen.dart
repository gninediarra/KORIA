import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/providers/theme_provider.dart';
import 'package:gabeseye/providers/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoRefresh = true;
  bool _soundAlerts = true;
  bool _vibration = true;
  bool _locationAccess = true;
  double _refreshInterval = 5;
  String _mapStyle = 'Standard';

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final l = locale.t;

    return Scaffold(
      appBar: AppBar(title: Text(l('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        children: [
          _buildSection(
            context,
            l('settings_appearance'),
            Icons.palette_outlined,
            [
              _buildToggle(
                l('settings_dark_mode'),
                l('settings_dark_mode_sub'),
                theme.isDark,
                (_) => theme.toggle(),
              ),
              _buildDivider(),
              _buildDropdownTile(
                l('settings_language'),
                locale.currentName,
                LocaleProvider.langNames,
                (v) {
                  if (v != null) locale.setByName(v);
                },
              ),
              _buildDivider(),
              _buildDropdownTile(
                l('settings_map_style'),
                _mapStyle,
                ['Standard', 'Satellite', 'Sombre'],
                (v) => setState(() => _mapStyle = v!),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            l('settings_data'),
            Icons.sync_outlined,
            [
              _buildToggle(
                l('settings_auto_refresh'),
                l('settings_auto_refresh_sub'),
                _autoRefresh,
                (v) => setState(() => _autoRefresh = v),
              ),
              _buildDivider(),
              _buildSliderTile(
                l('settings_interval'),
                '${_refreshInterval.toInt()} ${l('settings_interval_unit')}',
                _refreshInterval,
                3,
                30,
                (v) => setState(() => _refreshInterval = v),
              ),
              _buildDivider(),
              _buildToggle(
                l('settings_location'),
                l('settings_location_sub'),
                _locationAccess,
                (v) => setState(() => _locationAccess = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            l('settings_notif'),
            Icons.notifications_outlined,
            [
              _buildToggle(
                l('settings_sound'),
                l('settings_sound_sub'),
                _soundAlerts,
                (v) => setState(() => _soundAlerts = v),
              ),
              _buildDivider(),
              _buildToggle(
                l('settings_vibration'),
                l('settings_vibration_sub'),
                _vibration,
                (v) => setState(() => _vibration = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            l('settings_about'),
            Icons.info_outline_rounded,
            [
              _buildInfoTile('Version', '1.0.0 (Build 42)'),
              _buildDivider(),
              _buildInfoTile('Drone connecté', 'GabèsEye GE-01'),
              _buildDivider(),
              _buildInfoTile('Dernière mise à jour', '17 Avril 2026'),
              _buildDivider(),
              _buildInfoTile('ANPE Gabès', 'Partenaire institutionnel'),
            ],
          ),
          const SizedBox(height: 20),
          _buildDangerZone(context, l),
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
    final c = AdaptiveColors.of(context);
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
                color: c.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
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
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
                Text(sub,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.cyan,
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
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: AppColors.card,
            underline: const SizedBox.shrink(),
            style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.cyan,
                fontWeight: FontWeight.w600),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String label, String valueLabel, double value,
      double min, double max, void Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500)),
              Text(valueLabel,
                  style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan)),
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
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500))),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 0, indent: 16, endIndent: 16);

  Widget _buildDangerZone(BuildContext context, String Function(String) l) {
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
              Text(l('settings_danger_zone'),
                  style: GoogleFonts.exo2(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showResetDialog(context, l),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.red, size: 18),
              label: Text(l('settings_reset'),
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.red,
                      fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.red, width: 1),
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

  void _showResetDialog(BuildContext context, String Function(String) l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text('Réinitialiser ?',
            style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          'Cette action supprimera toutes les données locales.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l('cancel'),
                style:
                    GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l('reset_done'),
                    style:
                        GoogleFonts.inter(color: AppColors.textPrimary)),
                backgroundColor: AppColors.card,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            child: Text(l('confirm_reset'),
                style: GoogleFonts.inter(
                    color: AppColors.red,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
