import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _droneCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _droneX;
  late Animation<double> _droneY;
  late Animation<double> _pulse;
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );

    _droneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _droneX = Tween<double>(begin: -0.8, end: 1.2).animate(
      CurvedAnimation(parent: _droneCtrl, curve: Curves.easeInOut),
    );
    _droneY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.06), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.04), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: -0.03), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.0), weight: 25),
    ]).animate(_droneCtrl);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _logoCtrl.forward().then((_) {
      _droneCtrl.forward();
      _animateProgress();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _logoCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 3200), _navigateToLogin);
  }

  void _animateProgress() {
    const steps = 40;
    int i = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 55));
      if (!mounted) return false;
      setState(() => _progress = (i + 1) / steps);
      i++;
      return i < steps;
    });
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _droneCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Mosque background photo
          Positioned.fill(
            child: Image.asset(
              'assets/images/mosque.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

          // Dark overlay to keep the tech atmosphere
          Positioned.fill(
            child: Container(color: AppColors.bg.withValues(alpha: 0.82)),
          ),

          // Subtle cyan gradient accent on top
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  AppColors.cyan.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Grid lines decoration
          CustomPaint(
            painter: _GridPainter(),
            size: size,
          ),

          // Drone animation
          AnimatedBuilder(
            animation: _droneCtrl,
            builder: (_, _) => Positioned(
              left: size.width * (_droneX.value + 0.5) - 20,
              top: size.height * 0.28 + size.height * _droneY.value,
              child: Opacity(
                opacity: _droneCtrl.value < 0.05
                    ? _droneCtrl.value / 0.05
                    : _droneCtrl.value > 0.92
                        ? (1 - _droneCtrl.value) / 0.08
                        : 1,
                child: _DroneIcon(size: 42),
              ),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing eye icon
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, _) => Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card,
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan
                                  .withValues(alpha: 0.12 * _pulse.value),
                              blurRadius: 30 * _pulse.value,
                              spreadRadius: 4 * _pulse.value,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.remove_red_eye_rounded,
                          color: AppColors.cyan,
                          size: 44,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App name
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Gabès',
                            style: GoogleFonts.exo2(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                          TextSpan(
                            text: 'Eye',
                            style: GoogleFonts.exo2(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cyan,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'DRONE DE SURVEILLANCE ENVIRONNEMENTALE',
                      style: GoogleFonts.exo2(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        letterSpacing: 2.5,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Progress bar
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: AppColors.cardBorder,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.cyan),
                              minHeight: 3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _progress < 0.4
                                ? 'Initialisation des capteurs...'
                                : _progress < 0.7
                                    ? 'Connexion au drone GE-01...'
                                    : _progress < 0.95
                                        ? 'Chargement des données Gabès...'
                                        : 'Prêt',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textHint,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom tagline
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _logoFade,
              child: Text(
                'Powered by AI & Drone Technology',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textHint,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DroneIcon extends StatelessWidget {
  final double size;
  const _DroneIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(Icons.flight, color: AppColors.cyan, size: size - 20),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
