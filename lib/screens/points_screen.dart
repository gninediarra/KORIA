import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/locale_provider.dart';

const _nadhafa = Color(0xFFFFAB00);
const _premium = Color(0xFF6C3FC5);
const _gold = Color(0xFFFFD700);

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final locale = context.watch<LocaleProvider>();
    final c = AdaptiveColors.of(context);
    final l = locale.t;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _PointsHeader(user: user, c: c),
            Material(
              color: c.surface,
              child: TabBar(
                controller: _tab,
                indicatorColor: _nadhafa,
                indicatorWeight: 2.5,
                labelColor: _nadhafa,
                unselectedLabelColor: c.textSecondary,
                labelStyle: GoogleFonts.exo2(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    GoogleFonts.exo2(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Points'),
                  Tab(text: 'Premium'),
                  Tab(text: 'Acheter'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _PointsTab(user: user, l: l),
                  _PremiumTab(user: user),
                  _ShopTab(user: user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _PointsHeader extends StatelessWidget {
  final AppUser user;
  final AdaptiveColors c;
  const _PointsHeader({required this.user, required this.c});

  @override
  Widget build(BuildContext context) {
    final pts = user.nadhafaPoints;
    final pct = (pts / 1500).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_nadhafa.withValues(alpha: 0.18), c.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.stars_rounded, color: _nadhafa, size: 16),
                  const SizedBox(width: 6),
                  Text('Points Nadhafa',
                      style: GoogleFonts.exo2(
                          fontSize: 11,
                          color: _nadhafa.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1)),
                ]),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$pts',
                        style: GoogleFonts.exo2(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: _nadhafa,
                            height: 1.1)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5, left: 5),
                      child: Text('pts',
                          style: GoogleFonts.exo2(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _nadhafa.withValues(alpha: 0.7))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: _nadhafa.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_nadhafa),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$pts / 1 500 pts → Passeport Parcelle',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: _nadhafa.withValues(alpha: 0.7))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _nadhafa.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _nadhafa.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: _nadhafa, size: 26),
                const SizedBox(height: 3),
                Text('NADHAFA',
                    style: GoogleFonts.exo2(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: _nadhafa,
                        letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Points Tab ────────────────────────────────────────────────────────────────

class _PointsTab extends StatelessWidget {
  final AppUser user;
  final String Function(String) l;
  const _PointsTab({required this.user, required this.l});

  List<(IconData, Color, String, String, String)> _actionsFor(UserRole role) {
    switch (role) {
      case UserRole.agriculteur:
        return [
          (Icons.camera_alt_outlined, _nadhafa, 'Photo-vérification parcelle', '+50 pts', 'Photo d\'une zone polluée validée par l\'IA GabèsEye.'),
          (Icons.grass_outlined, AppColors.green, 'Signaler une dégradation du sol', '+50 pts', 'Érosion, décharge, salinisation — documentée avec GPS.'),
          (Icons.water_drop_outlined, AppColors.cyan, 'Déclarer une mesure d\'irrigation', '+30 pts', 'Contribuez à la cartographie hydrique de Gabès.'),
          (Icons.share_outlined, AppColors.orange, 'Partager l\'indice de qualité Air', '+10 pts', 'Diffusez l\'AQI autour de votre parcelle.'),
          (Icons.how_to_reg_outlined, AppColors.green, 'Recruter un agriculteur', '+20 pts', 'Invitez un confrère à rejoindre GabèsEye.'),
        ];
      case UserRole.pecheur:
        return [
          (Icons.camera_alt_outlined, _nadhafa, 'Photo zone de pêche dégradée', '+50 pts', 'Documentez la pollution littorale validée par l\'IA.'),
          (Icons.science_outlined, AppColors.cyan, 'Signaler eau anormale (couleur/odeur)', '+50 pts', 'Turbidité, mousses, déversements — géolocalisé.'),
          (Icons.anchor_rounded, AppColors.cyan, 'Déclarer votre zone de pêche', '+30 pts', 'Contribuez à la carte des zones actives du golfe.'),
          (Icons.share_outlined, AppColors.orange, 'Partager l\'indice de qualité Air', '+10 pts', 'Diffusez l\'AQI depuis le port ou la mer.'),
          (Icons.how_to_reg_outlined, AppColors.green, 'Recruter un pêcheur', '+20 pts', 'Invitez un autre pêcheur à rejoindre GabèsEye.'),
        ];
      case UserRole.autorite:
        return [
          (Icons.flight_outlined, AppColors.cyan, 'Valider une mission drone', '+100 pts', 'Autorisation et validation officielle d\'un survol.'),
          (Icons.verified_outlined, AppColors.green, 'Certifier un rapport terrain', '+80 pts', 'Apposez votre signature numérique sur un rapport.'),
          (Icons.campaign_outlined, AppColors.orange, 'Émettre une alerte critique', '+60 pts', 'Alerte SO₂, décharge, ou pollution maritime officielle.'),
          (Icons.people_outlined, _nadhafa, 'Valider un signalement citoyen', '+20 pts', 'Confirmez ou rejetez un signalement de terrain.'),
          (Icons.how_to_reg_outlined, AppColors.green, 'Recruter une institution', '+50 pts', 'Onboardez une mairie, CRDA ou ANPE partenaire.'),
        ];
      case UserRole.citoyen:
        return [
          (Icons.camera_alt_outlined, _nadhafa, 'Photo-vérification drone', '+50 pts', 'Photographiez une zone polluée validée par l\'IA.'),
          (Icons.report_problem_outlined, AppColors.orange, 'Signaler une décharge sauvage', '+50 pts', 'Signalez un dépôt illégal dans votre secteur.'),
          (Icons.route_outlined, AppColors.green, 'Itinéraire moins exposé', '+30 pts', 'Empruntez un itinéraire recommandé par GabèsEye.'),
          (Icons.share_outlined, AppColors.cyan, 'Partager l\'indice qualité Air', '+10 pts', 'Diffusez l\'AQI de votre quartier sur les réseaux.'),
          (Icons.how_to_reg_outlined, AppColors.green, 'Recruter un citoyen', '+20 pts', 'Invitez un ami à rejoindre GabèsEye.'),
        ];
    }
  }

  List<(IconData, Color, String, String, String)> _usagesFor(UserRole role) {
    switch (role) {
      case UserRole.agriculteur:
        return [
          (Icons.folder_open_rounded, AppColors.soil, 'Passeport Parcelle (rapport spectral)', '1 500 pts', 'Chlorophylle, humidité 30j, engrais, parasites.'),
          (Icons.workspace_premium_rounded, _premium, 'Premium agriculteur 14 jours', '5 000 pts', 'Historique 90j, PDF certifié, alertes phytosanitaires.'),
          (Icons.flight_rounded, AppColors.cyan, 'Scan drone prioritaire de votre parcelle', 'Classement', 'Votre parcelle scannée en premier à la prochaine mission.'),
        ];
      case UserRole.pecheur:
        return [
          (Icons.anchor_rounded, AppColors.water, 'Passeport Zone de Pêche', '1 500 pts', 'Phosphates 30j, biomasse estimée, zones interdites.'),
          (Icons.workspace_premium_rounded, _premium, 'Premium pêcheur 14 jours', '5 000 pts', 'Alertes zones interdites SMS, historique eau 90j.'),
          (Icons.flight_rounded, AppColors.cyan, 'Scan drone zone littorale', 'Classement', 'Votre zone scannée en priorité lors du prochain vol.'),
        ];
      case UserRole.autorite:
        return [
          (Icons.picture_as_pdf_rounded, AppColors.red, 'Générer un rapport PDF certifié', '0 pts', 'Inclus dans votre profil autorité — accès direct.'),
          (Icons.workspace_premium_rounded, _premium, 'Premium autorité 14 jours', '5 000 pts', 'API multi-zones, Dead Man\'s Switch, dashboard ANPE.'),
          (Icons.flight_rounded, AppColors.cyan, 'Priorité mission drone officielle', 'Classement', 'Vos zones classées en tête pour le prochain scan.'),
        ];
      case UserRole.citoyen:
        return [
          (Icons.folder_open_rounded, AppColors.soil, 'Passeport Parcelle / Zone', '1 500 pts', 'Rapport spectral détaillé de votre quartier.'),
          (Icons.workspace_premium_rounded, _premium, 'Abonnement Premium 14 jours', '5 000 pts', 'Accès complet aux données, alertes SMS, historique.'),
          (Icons.flight_rounded, AppColors.cyan, 'Survol drone prioritaire', 'Classement', 'Votre quartier scanné en premier — Part de Respiration.'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final actions = _actionsFor(user.role);
    final usages = _usagesFor(user.role);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        if (user.walletAddress != null && user.walletAddress!.length >= 10) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded,
                    color: AppColors.cyan, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Identité blockchain GabèsEye',
                          style: GoogleFonts.exo2(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan)),
                      Text(
                        '${user.walletAddress!.substring(0, 8)}…${user.walletAddress!.substring(user.walletAddress!.length - 6)}',
                        style: GoogleFonts.robotoMono(
                            fontSize: 11, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_rounded,
                    color: AppColors.green, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text('COMMENT GAGNER DES POINTS',
            style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...actions.map((a) => _ActionCard(
              icon: a.$1,
              color: a.$2,
              label: a.$3,
              pts: a.$4,
              desc: a.$5,
            )),
        const SizedBox(height: 20),
        Text('À QUOI SERVENT VOS POINTS',
            style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...usages.map((u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UsageCard(
                icon: u.$1,
                color: u.$2,
                title: u.$3,
                cost: u.$4,
                desc: u.$5,
              ),
            )),
      ],
    );
  }
}

// ── Premium Tab ───────────────────────────────────────────────────────────────

class _PremiumTab extends StatelessWidget {
  final AppUser user;
  const _PremiumTab({required this.user});

  List<(IconData, String, String)> _advantagesFor(UserRole role) {
    switch (role) {
      case UserRole.agriculteur:
        return [
          (Icons.folder_open_rounded, 'Passeport Parcelle déverrouillé', 'Rapport spectral complet : chlorophylle, humidité 30j, engrais, parasites.'),
          (Icons.picture_as_pdf_rounded, 'Export PDF certifié blockchain', 'Rapport agricole horodaté, opposable auprès du CRDA ou en justice.'),
          (Icons.history_rounded, 'Historique données 90 jours', 'Archives complètes sol & air de votre parcelle sur 3 mois.'),
          (Icons.bug_report_outlined, 'Alertes phytosanitaires par parcelle', 'Notification immédiate si indice parasites ou stress hydrique critique.'),
          (Icons.account_tree_outlined, 'Cadastre Vert — preuve juridique 12 mois', 'Historique certifié blockchain de l\'état de votre sol.'),
          (Icons.flight_rounded, 'Scan drone prioritaire de parcelle', 'Votre parcelle scannée en premier lors de chaque mission.'),
          (Icons.api_rounded, 'Accès API données parcelle', 'Intégrez les données GabèsEye dans votre propre système agricole.'),
        ];
      case UserRole.pecheur:
        return [
          (Icons.anchor_rounded, 'Passeport Zone de Pêche déverrouillé', 'Phosphates 30j, turbidité, biomasse estimée et zones de restriction.'),
          (Icons.picture_as_pdf_rounded, 'Export PDF certifié zone de pêche', 'Rapport horodaté blockchain — valable auprès de la DPA / APAL.'),
          (Icons.history_rounded, 'Historique qualité eau 90 jours', 'Archives complètes turbidité, température et phosphates sur 3 mois.'),
          (Icons.warning_amber_rounded, 'Alertes zones interdites SMS', 'Notification immédiate si votre zone entre en restriction sanitaire.'),
          (Icons.water_drop_outlined, 'Indice biomasse estimé hebdomadaire', 'Estimation du peuplement halieutique par secteur du golfe.'),
          (Icons.flight_rounded, 'Scan drone littoral prioritaire', 'Votre zone scannée en priorité — pollution détectée plus tôt.'),
          (Icons.api_rounded, 'Accès API données zone maritime', 'Intégrez les données eau GabèsEye dans vos outils coopérative.'),
        ];
      case UserRole.autorite:
        return [
          (Icons.picture_as_pdf_rounded, 'Génération PDF certifié blockchain', 'Rapports officiels ANPE horodatés, opposables en procédure réglementaire.'),
          (Icons.dashboard_rounded, 'Dashboard multi-zones avec API', 'Vue consolidée de toutes les zones + accès API pour systèmes SI.'),
          (Icons.notifications_active_rounded, 'Dead Man\'s Switch automatique', 'Alerte ANPE auto si SO₂ > 500 µg/m³ — preuve blockchain incluse.'),
          (Icons.flight_rounded, 'Traçabilité mission drone complète', 'Log de vol certifié : hash d\'image, coordonnées, heure, opérateur.'),
          (Icons.history_rounded, 'Historique toutes zones 12 mois', 'Archives longue durée pour rapports annuels et enquêtes.'),
          (Icons.verified_outlined, 'Signature numérique officielle', 'Vos validations portent une empreinte cryptographique opposable.'),
          (Icons.people_alt_outlined, 'Accès multi-agents terrain', 'Jusqu\'à 10 comptes agents sous votre supervision dans votre zone.'),
        ];
      case UserRole.citoyen:
        return [
          (Icons.air_rounded, 'Alertes AQI SMS en temps réel', 'Notification immédiate si la qualité de l\'air de votre quartier dépasse AQI 100.'),
          (Icons.history_rounded, 'Historique air & sol 90 jours', 'Consultez l\'évolution de votre quartier sur 3 mois complets.'),
          (Icons.route_outlined, 'Itinéraires santé personnalisés', 'Calcul des routes les moins exposées selon l\'AQI en temps réel.'),
          (Icons.flight_rounded, 'Notification scan drone imminente', 'Soyez alerté 24h avant le passage d\'un drone dans votre quartier.'),
          (Icons.leaderboard_rounded, 'Part de Respiration — classement top 3', 'Accès au classement complet des quartiers + avantages priorité scan.'),
          (Icons.qr_code_rounded, 'QR code rapport air personnalisé', 'Partagez un lien certifié vers la qualité de l\'air de votre rue.'),
          (Icons.family_restroom_rounded, 'Profil famille (jusqu\'à 4 membres)', 'Suivez plusieurs quartiers simultanément — idéal pour les parents.'),
        ];
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.agriculteur:
        return 'Premium Agriculteur';
      case UserRole.pecheur:
        return 'Premium Pêcheur';
      case UserRole.autorite:
        return 'Premium Autorité';
      case UserRole.citoyen:
        return 'Premium Citoyen';
    }
  }

  String _roleSub(UserRole role) {
    switch (role) {
      case UserRole.agriculteur:
        return 'Sol certifié · Passeport · Preuve juridique';
      case UserRole.pecheur:
        return 'Mer surveillée · Zone certifiée · Alertes SMS';
      case UserRole.autorite:
        return 'PDF officiel · API multi-zones · Dead Man\'s Switch';
      case UserRole.citoyen:
        return 'Air en temps réel · Itinéraires · Famille';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final advantages = _advantagesFor(user.role);
    final roleColor = user.role.color;

    final plans = [
      _Plan('Découverte', '5 000 pts', '14 jours', false, false, true, _premium),
      _Plan('Mensuel', '15 TND', '1 mois', true, false, false, _premium),
      _Plan('Trimestriel', '40 TND', '3 mois', false, false, false, _premium),
      _Plan('Annuel', '140 TND', '12 mois', false, true, false, _gold),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _premium.withValues(alpha: 0.18),
                _premium.withValues(alpha: 0.05)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _premium.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(user.role.icon, color: roleColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.workspace_premium_rounded,
                      color: _gold, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_roleLabel(user.role),
                            style: GoogleFonts.exo2(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary)),
                        Text(_roleSub(user.role),
                            style: GoogleFonts.inter(
                                fontSize: 11, color: c.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              ...advantages.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _premium.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(a.$1, color: _premium, size: 17),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.$2,
                                  style: GoogleFonts.exo2(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: c.textPrimary)),
                              Text(a.$3,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: c.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.green, size: 18),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('CHOISIR UN ABONNEMENT',
            style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...plans.map((plan) => _PlanCard(plan: plan)),
      ],
    );
  }
}

// ── Shop Tab ──────────────────────────────────────────────────────────────────

class _ShopTab extends StatelessWidget {
  final AppUser user;
  const _ShopTab({required this.user});

  List<(IconData, Color, String, int, String)> _unlocksFor(UserRole role) {
    switch (role) {
      case UserRole.agriculteur:
        return [
          (Icons.folder_open_rounded, AppColors.soil, 'Passeport Parcelle (rapport spectral)', 1500, 'ou 10 TND'),
          (Icons.workspace_premium_rounded, _premium, 'Premium Agriculteur 14 jours', 5000, 'ou 15 TND/mois'),
          (Icons.flight_rounded, AppColors.cyan, 'Scan drone prioritaire parcelle', 0, 'Classement parcelles'),
        ];
      case UserRole.pecheur:
        return [
          (Icons.anchor_rounded, AppColors.water, 'Passeport Zone de Pêche', 1500, 'ou 10 TND'),
          (Icons.workspace_premium_rounded, _premium, 'Premium Pêcheur 14 jours', 5000, 'ou 15 TND/mois'),
          (Icons.flight_rounded, AppColors.cyan, 'Scan drone littoral prioritaire', 0, 'Classement zones'),
        ];
      case UserRole.autorite:
        return [
          (Icons.picture_as_pdf_rounded, AppColors.red, 'Export PDF certifié blockchain', 0, 'Inclus — accès direct'),
          (Icons.workspace_premium_rounded, _premium, 'Premium Autorité 14 jours', 5000, 'ou 15 TND/mois'),
          (Icons.api_rounded, AppColors.cyan, 'Accès API multi-zones', 0, 'Inclus Premium Autorité'),
        ];
      case UserRole.citoyen:
        return [
          (Icons.folder_open_rounded, AppColors.soil, 'Passeport Quartier / Zone', 1500, 'ou 10 TND'),
          (Icons.workspace_premium_rounded, _premium, 'Premium Citoyen 14 jours', 5000, 'ou 15 TND/mois'),
          (Icons.flight_rounded, AppColors.cyan, 'Survol drone prioritaire', 0, 'Part de Respiration'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final unlocks = _unlocksFor(user.role);

    final packs = [
      _Pack(500, 55, false, ''),
      _Pack(1000, 100, false, 'Économisez 5 TND'),
      _Pack(2000, 180, true, 'Économisez 20 TND'),
      _Pack(5000, 400, false, 'Économisez 100 TND'),
      _Pack(10000, 700, false, 'Économisez 300 TND'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _nadhafa.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _nadhafa.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: _nadhafa, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Les points Nadhafa ne sont pas une monnaie. '
                  'Ils donnent accès à des rapports environnementaux '
                  'et à la priorité de scan drone.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('PACKS DE POINTS',
            style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...packs
            .map((pack) => _PackCard(pack: pack, currentPts: user.nadhafaPoints)),
        const SizedBox(height: 24),
        Text('CE QUE VOUS POUVEZ DÉBLOQUER',
            style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...unlocks.map((u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UnlockCard(
                icon: u.$1,
                color: u.$2,
                title: u.$3,
                cost: u.$4,
                current: user.nadhafaPoints,
                orText: u.$5,
              ),
            )),
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String pts;
  final String desc;
  const _ActionCard(
      {required this.icon,
      required this.color,
      required this.label,
      required this.pts,
      required this.desc});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
              Text(desc,
                  style:
                      GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
            ]),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _nadhafa.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _nadhafa.withValues(alpha: 0.3)),
            ),
            child: Text(pts,
                style: GoogleFonts.exo2(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _nadhafa)),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String cost;
  final String desc;
  const _UsageCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.cost,
      required this.desc});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
              Text(desc,
                  style:
                      GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
            ]),
          ),
          const SizedBox(width: 10),
          Text(cost,
              style: GoogleFonts.exo2(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _Plan {
  final String name, price, period;
  final bool popular, bestValue, withPoints;
  final Color color;
  const _Plan(this.name, this.price, this.period, this.popular, this.bestValue,
      this.withPoints, this.color);
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final highlight = plan.popular || plan.bestValue;

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Abonnement ${plan.name} — ${plan.price} (simulation)',
            style: GoogleFonts.exo2(fontSize: 13)),
        backgroundColor: plan.color,
        duration: const Duration(seconds: 2),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? plan.color.withValues(alpha: 0.08) : c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? plan.color.withValues(alpha: 0.5)
                : c.cardBorder,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: plan.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                plan.withPoints
                    ? Icons.stars_rounded
                    : Icons.workspace_premium_rounded,
                color: plan.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.name,
                          style: GoogleFonts.exo2(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: highlight ? plan.color : c.textPrimary)),
                      if (plan.popular) ...[
                        const SizedBox(width: 6),
                        _Badge('POPULAIRE', plan.color),
                      ],
                      if (plan.bestValue) ...[
                        const SizedBox(width: 6),
                        _Badge('MEILLEURE OFFRE', plan.color),
                      ],
                      if (plan.withPoints) ...[
                        const SizedBox(width: 6),
                        _Badge('POINTS', plan.color),
                      ],
                    ],
                  ),
                  Text(plan.period,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: c.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.price,
                    style: GoogleFonts.exo2(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: highlight ? plan.color : c.textPrimary)),
                if (!plan.withPoints)
                  Text('TND',
                      style:
                          GoogleFonts.inter(fontSize: 11, color: c.textSecondary)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: c.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: GoogleFonts.exo2(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.5)),
      );
}

class _Pack {
  final int pts, prix;
  final bool popular;
  final String saving;
  const _Pack(this.pts, this.prix, this.popular, this.saving);
}

class _PackCard extends StatelessWidget {
  final _Pack pack;
  final int currentPts;
  const _PackCard({required this.pack, required this.currentPts});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Achat de ${pack.pts} pts — ${pack.prix} TND (simulation)',
            style: GoogleFonts.exo2(fontSize: 13)),
        backgroundColor: _nadhafa,
        duration: const Duration(seconds: 2),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: pack.popular ? _nadhafa.withValues(alpha: 0.08) : c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: pack.popular
                ? _nadhafa.withValues(alpha: 0.5)
                : c.cardBorder,
            width: pack.popular ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: _nadhafa, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Row(children: [
                Text('${pack.pts} pts',
                    style: GoogleFonts.exo2(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _nadhafa)),
                if (pack.saving.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(pack.saving,
                        style: GoogleFonts.exo2(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green)),
                  ),
                ],
                if (pack.popular) ...[
                  const SizedBox(width: 6),
                  const _Badge('POPULAIRE', _nadhafa),
                ],
              ]),
            ),
            Text('${pack.prix} TND',
                style: GoogleFonts.exo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: pack.popular ? _nadhafa : c.textPrimary)),
            const SizedBox(width: 8),
            const Icon(Icons.add_circle_outline_rounded,
                color: _nadhafa, size: 20),
          ],
        ),
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int cost;
  final int current;
  final String orText;
  const _UnlockCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.cost,
      required this.current,
      required this.orText});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final unlocked = cost == 0 || current >= cost;
    final pct = cost == 0 ? 1.0 : (current / cost).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? AppColors.green.withValues(alpha: 0.4)
              : c.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.exo2(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary)),
              const SizedBox(height: 4),
              if (cost > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: c.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        unlocked ? AppColors.green : color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 3),
                Text('$current / $cost pts — $orText',
                    style:
                        GoogleFonts.inter(fontSize: 10, color: c.textSecondary)),
              ] else
                Text(orText,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: c.textSecondary)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(
            unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: unlocked ? AppColors.green : c.textHint,
            size: 20,
          ),
        ],
      ),
    );
  }
}
