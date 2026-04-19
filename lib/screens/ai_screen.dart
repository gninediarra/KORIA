import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/services/ai_service.dart';
import 'package:gabeseye/services/voice_service.dart';

// ── Agent config par rôle ─────────────────────────────────────────────────────

class _AgentConfig {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_QuickAction> quickActions;
  final String welcomeText;
  const _AgentConfig({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.quickActions,
    required this.welcomeText,
  });
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String prompt;
  const _QuickAction(this.label, this.icon, this.prompt);
}

_AgentConfig _configFor(UserRole role) {
  switch (role) {
    case UserRole.agriculteur:
      return _AgentConfig(
        name: 'AgriBot',
        subtitle: 'Assistant sol & cultures · GabèsEye IA',
        icon: Icons.grass_rounded,
        color: AppColors.soil,
        welcomeText:
            'Bonjour ! Je suis AgriBot, votre assistant IA connecté aux données satellites de Gabès. '
            'Posez-moi une question sur l\'état des sols, l\'irrigation ou vos cultures, '
            'ou envoyez une photo pour analyse environnementale.',
        quickActions: const [
          _QuickAction('État du sol', Icons.terrain_rounded,
              'Donne-moi l\'état actuel du sol et les risques pour mes cultures.'),
          _QuickAction('Irrigation', Icons.water_drop_outlined,
              'Est-ce que je peux irriguer aujourd\'hui ? Qualité de l\'eau ?'),
          _QuickAction('Semis', Icons.eco_outlined,
              'Quelles cultures recommandes-tu pour cette saison compte tenu de la contamination ?'),
          _QuickAction('Rapport CRDA', Icons.description_outlined,
              'Génère un résumé de l\'état de ma parcelle pour le CRDA.'),
        ],
      );
    case UserRole.pecheur:
      return _AgentConfig(
        name: 'MarinBot',
        subtitle: 'Assistant mer & zones de pêche · GabèsEye IA',
        icon: Icons.anchor_rounded,
        color: AppColors.water,
        welcomeText:
            'Bonjour ! Je suis MarinBot, votre assistant IA spécialisé dans la surveillance du golfe de Gabès. '
            'Je vous donne les conditions marines en temps réel, les zones sûres et les risques de contamination. '
            'Posez votre question ou envoyez une photo de l\'eau pour analyse.',
        quickActions: const [
          _QuickAction('Conditions mer', Icons.waves_rounded,
              'Quelles sont les conditions marines aujourd\'hui ? Puis-je sortir en mer ?'),
          _QuickAction('Zones sûres', Icons.map_outlined,
              'Quelles zones de pêche sont sûres et quelles zones dois-je éviter ?'),
          _QuickAction('Qualité eau', Icons.science_outlined,
              'Analyse la qualité de l\'eau et l\'impact sur mes captures.'),
          _QuickAction('Alerte DPA', Icons.warning_amber_rounded,
              'Y a-t-il des alertes officielles pour les pêcheurs du golfe de Gabès ?'),
        ],
      );
    case UserRole.autorite:
      return _AgentConfig(
        name: 'AuthoBot',
        subtitle: 'Rapport officiel multi-axes · GabèsEye IA',
        icon: Icons.shield_outlined,
        color: AppColors.orange,
        welcomeText:
            'Bonjour ! Je suis AuthoBot, votre assistant IA pour la surveillance environnementale officielle de Gabès. '
            'Je génère des rapports multi-axes conformes ANPE, identifie les zones critiques et propose des recommandations politiques. '
            'Que puis-je faire pour vous ?',
        quickActions: const [
          _QuickAction('Rapport exécutif', Icons.summarize_rounded,
              'Génère un rapport exécutif multi-axes (sol, eau, air) pour les autorités.'),
          _QuickAction('Zones critiques', Icons.crisis_alert_rounded,
              'Identifie toutes les zones en situation critique et les actions urgentes.'),
          _QuickAction('Rapport ANPE', Icons.picture_as_pdf_rounded,
              'Rédige un rapport structuré conforme aux exigences ANPE.'),
          _QuickAction('Recommandations', Icons.policy_rounded,
              'Quelles mesures politiques recommandes-tu pour réduire la pollution industrielle ?'),
        ],
      );
    case UserRole.citoyen:
      return _AgentConfig(
        name: 'CitiBot',
        subtitle: 'Qualité de l\'air & santé · GabèsEye IA',
        icon: Icons.air_rounded,
        color: AppColors.cyan,
        welcomeText:
            'Bonjour ! Je suis CitiBot, votre assistant IA pour votre santé et qualité de vie à Gabès. '
            'Je surveille l\'air, l\'eau et les risques sanitaires en temps réel. '
            'Posez votre question ou envoyez une photo pour identifier un problème environnemental.',
        quickActions: const [
          _QuickAction('Qualité air', Icons.air_rounded,
              'Quelle est la qualité de l\'air aujourd\'hui dans mon quartier ?'),
          _QuickAction('Risque santé', Icons.health_and_safety_outlined,
              'Y a-t-il des risques pour ma santé aujourd\'hui ? Que dois-je faire ?'),
          _QuickAction('Itinéraire', Icons.route_outlined,
              'Quel itinéraire me recommandes-tu pour éviter les zones polluées ?'),
          _QuickAction('Signaler', Icons.report_problem_outlined,
              'Comment puis-je signaler une anomalie environnementale dans mon quartier ?'),
        ],
      );
  }
}

// ── Message model ─────────────────────────────────────────────────────────────

class _Msg {
  final String text;
  final bool isUser;
  final File? imageFile;
  final bool isVoice;
  final DateTime ts;
  _Msg({
    required this.text,
    required this.isUser,
    this.imageFile,
    this.isVoice = false,
  }) : ts = DateTime.now();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> with TickerProviderStateMixin {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  final List<Map<String, String>> _history = [];

  String _langue = 'fr';
  bool _loading  = false;
  bool _isRecording = false;
  bool _ttsEnabled = true;

  late AnimationController _micPulseCtrl;
  late Animation<double> _micPulseAnim;

  @override
  void initState() {
    super.initState();
    _micPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _micPulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _micPulseCtrl, curve: Curves.easeInOut),
    );
    _micPulseCtrl.stop();
    _sendWelcome();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _micPulseCtrl.dispose();
    VoiceService.stop();
    super.dispose();
  }

  UserRole get _role =>
      context.read<AuthProvider>().user?.role ?? UserRole.citoyen;

  _AgentConfig get _agent => _configFor(_role);

  Future<void> _sendWelcome() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final config = _configFor(_role);
    _addBot(config.welcomeText, speak: true);
  }

  void _addBot(String text, {bool speak = false}) {
    if (!mounted) return;
    setState(() => _msgs.add(_Msg(text: text, isUser: false)));
    _scrollDown();
    if (speak && _ttsEnabled) {
      VoiceService.speak(text, lang: _langue);
    }
  }

  void _addUser(String text, {File? imageFile, bool isVoice = false}) {
    setState(() => _msgs.add(_Msg(
      text: text,
      isUser: true,
      imageFile: imageFile,
      isVoice: isVoice,
    )));
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _ctrl.clear();
    _addUser(text);
    setState(() => _loading = true);
    _history.add({'role': 'user', 'content': text});

    final role = _role.name;
    final res = await AiService.chat(
      message: text,
      history: List.from(_history),
      role: role,
      langue: _langue,
    );

    if (mounted) {
      setState(() => _loading = false);
      _addBot(res.text, speak: _ttsEnabled);
      if (!res.isError) {
        _history.add({'role': 'assistant', 'content': res.text});
        if (_history.length > 12) _history.removeRange(0, 2);
      }
    }
  }

  Future<void> _sendImage(File imageFile) async {
    if (_loading) return;
    _addUser('📷 Image envoyée pour analyse', imageFile: imageFile);
    setState(() => _loading = true);

    final res = await AiService.analyzeImage(
      imageFile: imageFile,
      question: 'Analyse cette image pour détecter contamination, déchets industriels, état de l\'eau ou du sol.',
      langue: _langue,
      zoneId: 'gct',
    );

    if (mounted) {
      setState(() => _loading = false);
      _addBot(res.text, speak: _ttsEnabled);
      if (!res.isError) {
        _history.add({'role': 'assistant', 'content': res.text});
      }
    }
  }

  Future<void> _pickImage() async {
    if (_loading) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked != null) {
      await _sendImage(File(picked.path));
    }
  }

  Future<void> _takePicture() async {
    if (_loading) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (picked != null) {
      await _sendImage(File(picked.path));
    }
  }

  Future<void> _toggleMic() async {
    if (_isRecording) {
      // Stop and transcribe
      setState(() => _isRecording = false);
      _micPulseCtrl.stop();

      setState(() => _loading = true);
      final transcribed = await VoiceService.stopAndTranscribe(langue: _langue);
      setState(() => _loading = false);

      if (transcribed != null && transcribed.isNotEmpty && mounted) {
        _ctrl.text = transcribed;
        _addUser(transcribed, isVoice: true);
        setState(() => _loading = true);
        _history.add({'role': 'user', 'content': transcribed});

        final res = await AiService.chat(
          message: transcribed,
          history: List.from(_history),
          role: _role.name,
          langue: _langue,
        );

        if (mounted) {
          setState(() => _loading = false);
          _ctrl.clear();
          _addBot(res.text, speak: true);
          if (!res.isError) {
            _history.add({'role': 'assistant', 'content': res.text});
            if (_history.length > 12) _history.removeRange(0, 2);
          }
        }
      } else if (mounted) {
        setState(() => _loading = false);
        _addBot('❌ Transcription échouée. Réessayez ou saisissez votre message.');
      }
    } else {
      // Start recording
      final path = await VoiceService.startRecording();
      if (path != null) {
        setState(() => _isRecording = true);
        _micPulseCtrl.repeat(reverse: true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone non disponible. Vérifiez les permissions.')),
          );
        }
      }
    }
  }

  void _clearChat() {
    VoiceService.stop();
    setState(() {
      _msgs.clear();
      _history.clear();
    });
    _sendWelcome();
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Prendre une photo'),
              onTap: () { Navigator.pop(context); _takePicture(); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galerie'),
              onTap: () { Navigator.pop(context); _pickImage(); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final cfg = _agent;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(cfg.icon, color: cfg.color, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cfg.name,
                    style: GoogleFonts.exo2(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text('GabèsEye IA · Groq Llama-3.3-70b',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: c.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          // TTS toggle
          IconButton(
            icon: Icon(
              _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 20,
              color: _ttsEnabled ? cfg.color : c.textHint,
            ),
            onPressed: () {
              setState(() => _ttsEnabled = !_ttsEnabled);
              if (!_ttsEnabled) VoiceService.stop();
            },
            tooltip: 'Lecture vocale',
          ),
          _LangButton(current: _langue, onSelected: (l) => setState(() => _langue = l)),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _clearChat,
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: cfg.color.withValues(alpha: 0.07),
            child: Row(children: [
              Icon(Icons.psychology_rounded, size: 14, color: cfg.color),
              const SizedBox(width: 6),
              Text(cfg.subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: cfg.color,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              if (_isRecording)
                _RecordingBadge(color: cfg.color)
              else
                _StatusBadge(color: cfg.color, label: 'EN LIGNE'),
            ]),
          ),

          // Messages
          Expanded(
            child: _msgs.isEmpty
                ? _EmptyState(cfg: cfg)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _msgs.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _msgs.length) {
                        return _TypingBubble(color: cfg.color);
                      }
                      return _MsgBubble(
                        msg: _msgs[i],
                        agentColor: cfg.color,
                        agentIcon: cfg.icon,
                        onSpeak: (text) => VoiceService.speak(text, lang: _langue),
                      );
                    },
                  ),
          ),

          // Quick actions
          if (!_loading && _msgs.length <= 2)
            _QuickActions(
              actions: cfg.quickActions,
              color: cfg.color,
              onTap: _send,
            ),

          // Input bar
          _InputBar(
            ctrl: _ctrl,
            loading: _loading,
            isRecording: _isRecording,
            color: cfg.color,
            pulseAnim: _micPulseAnim,
            onSend: _send,
            onMic: _toggleMic,
            onImage: _showImageOptions,
          ),
        ],
      ),
    );
  }
}

// ── Recording badge ───────────────────────────────────────────────────────────

class _RecordingBadge extends StatefulWidget {
  final Color color;
  const _RecordingBadge({required this.color});

  @override
  State<_RecordingBadge> createState() => _RecordingBadgeState();
}

class _RecordingBadgeState extends State<_RecordingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, child) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: _ac.value * 0.7 + 0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text('ENREGISTREMENT',
              style: GoogleFonts.exo2(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.exo2(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5)),
    );
  }
}

// ── Language button ───────────────────────────────────────────────────────────

class _LangButton extends StatelessWidget {
  final String current;
  final void Function(String) onSelected;
  const _LangButton({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final langs = {'fr': '🇫🇷', 'ar': '🇹🇳', 'en': '🇬🇧'};
    return PopupMenuButton<String>(
      initialValue: current,
      onSelected: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(langs[current] ?? '🇫🇷',
            style: const TextStyle(fontSize: 20)),
      ),
      itemBuilder: (_) => langs.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Row(children: [
                  Text(e.value, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(e.key.toUpperCase(),
                      style: GoogleFonts.exo2(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ))
          .toList(),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _AgentConfig cfg;
  const _EmptyState({required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cfg.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(cfg.icon, color: cfg.color, size: 42),
          ),
          const SizedBox(height: 16),
          Text(cfg.name,
              style: GoogleFonts.exo2(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Connecté aux données GabèsEye en temps réel',
              style: GoogleFonts.inter(fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MsgBubble extends StatelessWidget {
  final _Msg msg;
  final Color agentColor;
  final IconData agentIcon;
  final void Function(String) onSpeak;
  const _MsgBubble({
    required this.msg,
    required this.agentColor,
    required this.agentIcon,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: agentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(agentIcon, color: agentColor, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isUser ? null : () => onSpeak(msg.text),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? agentColor.withValues(alpha: 0.15)
                      : c.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser
                      ? Border.all(color: agentColor.withValues(alpha: 0.3))
                      : Border.all(color: c.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.imageFile != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          msg.imageFile!,
                          width: 200,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (msg.isVoice) ...[
                          Icon(Icons.mic_rounded, size: 12,
                              color: isUser ? agentColor : c.textHint),
                          const SizedBox(width: 4),
                        ],
                        Flexible(child: _FormattedText(text: msg.text, isUser: isUser)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 4),
            // Speak button for user messages
          ],
          if (!isUser) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => onSpeak(msg.text),
              child: Icon(Icons.volume_up_rounded, size: 16, color: c.textHint),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormattedText extends StatelessWidget {
  final String text;
  final bool isUser;
  const _FormattedText({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;

    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, m.start),
          style: GoogleFonts.inter(fontSize: 14, color: c.textPrimary),
        ));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: GoogleFonts.exo2(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: c.textPrimary),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: GoogleFonts.inter(fontSize: 14, color: c.textPrimary),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  final Color color;
  const _TypingBubble({required this.color});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ac);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology_rounded,
                color: widget.color, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: c.cardBorder),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, child) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity:
                          (((_anim.value + i * 0.3) % 1.0) * 0.7 + 0.3)
                              .clamp(0.3, 1.0),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final List<_QuickAction> actions;
  final Color color;
  final void Function(String) onTap;
  const _QuickActions(
      {required this.actions, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIONS RAPIDES',
              style: GoogleFonts.exo2(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: c.textHint,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: actions
                .map((a) => GestureDetector(
                      onTap: () => onTap(a.prompt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(a.icon, size: 14, color: color),
                            const SizedBox(width: 5),
                            Text(a.label,
                                style: GoogleFonts.exo2(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: color)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final bool isRecording;
  final Color color;
  final Animation<double> pulseAnim;
  final void Function(String) onSend;
  final VoidCallback onMic;
  final VoidCallback onImage;

  const _InputBar({
    required this.ctrl,
    required this.loading,
    required this.isRecording,
    required this.color,
    required this.pulseAnim,
    required this.onSend,
    required this.onMic,
    required this.onImage,
  });

  @override
  Widget build(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            // Image button
            _IconBtn(
              icon: Icons.add_photo_alternate_rounded,
              color: color,
              onTap: loading ? null : onImage,
              tooltip: 'Envoyer une image',
            ),
            const SizedBox(width: 6),

            // Mic button with pulse
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: isRecording ? pulseAnim.value : 1.0,
                child: _IconBtn(
                  icon: isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: isRecording ? Colors.red : color,
                  onTap: loading && !isRecording ? null : onMic,
                  tooltip: isRecording ? 'Arrêter l\'enregistrement' : 'Message vocal',
                  filled: isRecording,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isRecording
                        ? Colors.red.withValues(alpha: 0.5)
                        : c.cardBorder,
                  ),
                ),
                child: TextField(
                  controller: ctrl,
                  enabled: !loading && !isRecording,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: onSend,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: isRecording
                        ? '🎙 Parlez maintenant...'
                        : loading
                            ? "L'IA réfléchit..."
                            : "Message ou question...",
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isRecording ? Colors.red : c.textHint),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: loading || isRecording ? null : () => onSend(ctrl.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (loading || isRecording)
                      ? color.withValues(alpha: 0.3)
                      : color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  loading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;
  final bool filled;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: filled ? color : color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: filled ? Colors.white : color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
