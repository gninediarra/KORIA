import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/screens/main_navigation.dart';
import 'package:gabeseye/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  UserRole _selectedRole = UserRole.citoyen;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (ok && mounted) {
      // Charge les données réelles depuis le backend (async, sans bloquer la nav)
      context.read<AppProvider>().loadFromApi();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MainNavigation(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, _, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      );
    }
  }

  void _quickLogin(UserRole role) {
    setState(() => _selectedRole = role);
    final demos = {
      UserRole.agriculteur: ('ahmed@gabeseye.tn', 'demo1234'),
      UserRole.pecheur: ('fatma@gabeseye.tn', 'demo1234'),
      UserRole.autorite: ('samir@gabeseye.tn', 'demo1234'),
      UserRole.citoyen: ('manel@gabeseye.tn', 'demo1234'),
    };
    _emailCtrl.text = demos[role]!.$1;
    _passCtrl.text = demos[role]!.$2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildRoleSelector(),
                const SizedBox(height: 28),
                _buildFormFields(),
                const SizedBox(height: 20),
                _buildLoginButton(),
                const SizedBox(height: 16),
                _buildRegisterLink(),
                const SizedBox(height: 28),
                _buildQuickAccess(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final c = AdaptiveColors.of(context);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.15),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(Icons.remove_red_eye_rounded,
              color: AppColors.cyan, size: 26),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Gabès',
                    style: GoogleFonts.exo2(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: 'Eye',
                    style: GoogleFonts.exo2(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Surveillance Environnementale',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez votre profil',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Les alertes seront personnalisées selon votre rôle',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: UserRole.values
              .map((role) => _RoleCard(
                    role: role,
                    selected: _selectedRole == role,
                    onTap: () => setState(() => _selectedRole = role),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            hintText: 'votre@email.com',
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textHint,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        Consumer<AuthProvider>(
          builder: (_, auth, _) {
            if (auth.error == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(auth.error!,
                          style: const TextStyle(
                              color: AppColors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (_, auth, _) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyan,
            foregroundColor: AppColors.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: auth.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.bg,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Se connecter — ${_selectedRole.label}',
                      style: GoogleFonts.exo2(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          child: Text(
            'S\'inscrire',
            style: GoogleFonts.exo2(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.cyan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ACCÈS DÉMO RAPIDE',
                style: GoogleFonts.exo2(
                  fontSize: 10,
                  color: AppColors.textHint,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: UserRole.values
              .map((role) => InkWell(
                    onTap: () => _quickLogin(role),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: role.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: role.color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(role.icon, color: role.color, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            role.label,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: role.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? role.color.withValues(alpha: 0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? role.color : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: role.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(role.icon,
                    color: selected ? role.color : AppColors.textHint,
                    size: 20),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      color: role.color, size: 16),
              ],
            ),
            const Spacer(),
            Text(
              role.label,
              style: GoogleFonts.exo2(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? role.color : AppColors.textPrimary,
              ),
            ),
            Text(
              role.description,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
