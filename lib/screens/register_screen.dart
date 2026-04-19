import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/services/api_service.dart';
import 'package:gabeseye/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _localAuth      = LocalAuthentication();
  final _nameCtrl       = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passCtrl       = TextEditingController();
  final _quartierCtrl   = TextEditingController();
  final _parcelleCtrl   = TextEditingController();

  UserRole _selectedRole = UserRole.citoyen;
  bool _obscurePass  = true;
  bool _faceScanned  = false;
  bool _isScanning   = false;
  bool _isSubmitting = false;
  String? _error;

  // Set after successful registration
  String? _walletAddress;
  int?    _nadhafaPoints;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _quartierCtrl.dispose();
    _parcelleCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanFace() async {
    setState(() { _isScanning = true; _error = null; });
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) {
        setState(() {
          _error = 'Biométrie non disponible sur cet appareil.';
          _isScanning = false;
        });
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'Confirmez votre identité pour créer le compte',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      setState(() { _faceScanned = ok; _isScanning = false; });
    } catch (_) {
      setState(() {
        _error = 'Erreur biométrique — vérifiez les capteurs.';
        _isScanning = false;
      });
    }
  }

  Future<void> _submit() async {
    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Nom, email et mot de passe sont obligatoires.');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'Le mot de passe doit faire au moins 8 caractères.');
      return;
    }
    if (!_faceScanned) {
      setState(() => _error = 'Le scan facial est requis pour l\'inscription.');
      return;
    }

    setState(() { _isSubmitting = true; _error = null; });

    final result = await ApiService.register(
      name:     name,
      email:    email,
      password: pass,
      role:     _selectedRole.name,
      quartier: _quartierCtrl.text.trim().isEmpty ? null : _quartierCtrl.text.trim(),
      parcelle: _parcelleCtrl.text.trim().isEmpty ? null : _parcelleCtrl.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result == null) {
      setState(() => _error = 'Serveur indisponible. Vérifiez votre connexion.');
      return;
    }
    if (result.containsKey('error')) {
      setState(() => _error = result['error'] as String);
      return;
    }

    setState(() {
      _walletAddress = result['wallet_address'] as String?;
      _nadhafaPoints     = (result['nadhafa_points'] as num?)?.toInt() ?? 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);

    if (_walletAddress != null) {
      return _SuccessScreen(
        walletAddress: _walletAddress!,
        nadhafaPoints: _nadhafaPoints ?? 0,
        onBack:        () => Navigator.of(context).pop(),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: c.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildBlockchainBadge(),
            const SizedBox(height: 24),
            _buildLabel('Informations personnelles', c),
            const SizedBox(height: 12),
            _buildField(_nameCtrl, 'Nom complet', Icons.person_outline),
            const SizedBox(height: 12),
            _buildField(_emailCtrl, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildPasswordField(c),
            const SizedBox(height: 12),
            _buildField(_quartierCtrl, 'Quartier (optionnel)', Icons.location_city_outlined),
            const SizedBox(height: 24),
            _buildLabel('Profil d\'accès', c),
            const SizedBox(height: 12),
            _buildRoleGrid(c),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: (_selectedRole == UserRole.agriculteur ||
                      _selectedRole == UserRole.pecheur)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildLabel(
                          _selectedRole == UserRole.agriculteur
                              ? 'Parcelle agricole'
                              : 'Zone de pêche',
                          c,
                        ),
                        const SizedBox(height: 12),
                        _buildParcelleField(c),
                        const SizedBox(height: 10),
                        _buildBlockchainFieldBadge(c),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _buildAutoWalletInfo(c),
            const SizedBox(height: 24),
            _buildFaceSection(c),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _buildError(),
            ],
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockchainBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, color: AppColors.cyan, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Une identité blockchain est créée pour certifier vos données environnementales.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.cyan),
              ),
            ),
          ],
        ),
      );

  Widget _buildLabel(String text, AdaptiveColors c) => Text(
        text.toUpperCase(),
        style: GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSecondary, letterSpacing: 1.4),
      );

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    final c = AdaptiveColors.of(context);
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _buildPasswordField(AdaptiveColors c) => TextFormField(
        controller: _passCtrl,
        obscureText: _obscurePass,
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          labelText: 'Mot de passe (8 caractères min.)',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.textHint,
            ),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
      );

  Widget _buildParcelleField(AdaptiveColors c) => TextFormField(
        controller: _parcelleCtrl,
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          labelText: _selectedRole == UserRole.agriculteur
              ? 'Nom / description de votre parcelle'
              : 'Zone de pêche habituelle',
          prefixIcon: Icon(
            _selectedRole == UserRole.agriculteur
                ? Icons.agriculture
                : Icons.anchor_rounded,
          ),
          hintText: _selectedRole == UserRole.agriculteur
              ? 'Ex: Palmeraie Bahria Nord, 3 ha'
              : 'Ex: Secteur Sud-Est du golfe',
        ),
      );

  Widget _buildBlockchainFieldBadge(AdaptiveColors c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.green, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedRole == UserRole.agriculteur
                    ? 'Cette parcelle sera enregistrée et vérifiée sur la blockchain GabèsEye.'
                    : 'Votre zone de pêche sera enregistrée sur la blockchain GabèsEye.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.green),
              ),
            ),
          ],
        ),
      );

  Widget _buildRoleGrid(AdaptiveColors c) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: UserRole.values.map((role) {
          final selected = _selectedRole == role;
          return GestureDetector(
            onTap: () => setState(() => _selectedRole = role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: selected ? role.color.withValues(alpha: 0.12) : c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? role.color : c.cardBorder, width: selected ? 1.5 : 1),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(role.icon, color: selected ? role.color : c.textHint, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(role.label,
                        style: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? role.color : c.textPrimary)),
                  ),
                  if (selected) Icon(Icons.check_circle_rounded, color: role.color, size: 14),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _buildAutoWalletInfo(AdaptiveColors c) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: c.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Identité blockchain automatique',
                      style: GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Votre adresse Ethereum sert de preuve horodatée pour vos données.',
                      style: GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFaceSection(AdaptiveColors c) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _faceScanned ? AppColors.green.withValues(alpha: 0.4) : c.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.face_retouching_natural, color: AppColors.cyan, size: 20),
                const SizedBox(width: 8),
                Text('Scan facial',
                    style: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                const Spacer(),
                if (_faceScanned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 14),
                        const SizedBox(width: 4),
                        Text('Validé',
                            style: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Votre empreinte biométrique confirme votre identité. Ce scan ne quitte jamais votre appareil.',
              style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isScanning ? null : _scanFace,
                icon: _isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
                      )
                    : Icon(
                        _faceScanned ? Icons.refresh_rounded : Icons.face_retouching_natural,
                        color: AppColors.cyan,
                      ),
                label: Text(
                  _faceScanned ? 'Rescanner' : 'Scanner mon visage',
                  style: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.cyan),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _faceScanned ? AppColors.green : AppColors.cyan),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildError() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.red))),
          ],
        ),
      );

  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.how_to_reg_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('Créer mon compte',
                        style: GoogleFonts.exo2(fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      );
}

// ─── Success screen ───────────────────────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  final String walletAddress;
  final int nadhafaPoints;
  final VoidCallback onBack;

  const _SuccessScreen({
    required this.walletAddress,
    required this.nadhafaPoints,
    required this.onBack,
  });

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: walletAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adresse copiée !'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.green, size: 40),
              ),
              const SizedBox(height: 24),
              Text('Compte créé !',
                  style: GoogleFonts.exo2(fontSize: 24, fontWeight: FontWeight.w800, color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Votre identité a été enregistrée sur la blockchain GabèsEye.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: c.textSecondary),
              ),
              const SizedBox(height: 28),
              Container(
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
                        const Icon(Icons.account_balance_wallet_outlined, color: AppColors.cyan, size: 16),
                        const SizedBox(width: 6),
                        Text('Preuve d\'identité blockchain',
                            style: GoogleFonts.exo2(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppColors.cyan, letterSpacing: 0.8)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _copy(context),
                          child: const Icon(Icons.copy_rounded, color: AppColors.cyan, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(walletAddress,
                        style: GoogleFonts.robotoMono(fontSize: 11, color: c.textSecondary),
                        softWrap: true),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.green, size: 16),
                          const SizedBox(width: 8),
                          Text('+$nadhafaPoints pts Nadhafa — Bonus de bienvenue',
                              style: GoogleFonts.exo2(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppColors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cette adresse certifie vos signalements environnementaux sur la blockchain GabèsEye.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: c.textHint),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: onBack,
                  child: Text('Se connecter',
                      style: GoogleFonts.exo2(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
