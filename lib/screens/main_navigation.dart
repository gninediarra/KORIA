import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gabeseye/theme/app_theme.dart';
import 'package:gabeseye/models/models.dart';
import 'package:gabeseye/providers/auth_provider.dart';
import 'package:gabeseye/providers/app_provider.dart';
import 'package:gabeseye/providers/locale_provider.dart';
import 'package:gabeseye/screens/home_screen.dart';
import 'package:gabeseye/screens/farmer_home_screen.dart';
import 'package:gabeseye/screens/fisherman_home_screen.dart';
import 'package:gabeseye/screens/authority_home_screen.dart';
import 'package:gabeseye/screens/map_screen.dart';
import 'package:gabeseye/screens/alerts_screen.dart';
import 'package:gabeseye/screens/reports_screen.dart';
import 'package:gabeseye/screens/ai_screen.dart';
import 'package:gabeseye/screens/points_screen.dart';
import 'package:gabeseye/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _RoleHome(),   // 0 — Dashboard
          MapScreen(),   // 1 — Carte
          AlertsScreen(), // 2 — Alertes
          AiScreen(),    // 3 — IA
          ReportsScreen(), // 4 — Rapports
          PointsScreen(), // 5 — Points
          ProfileScreen(), // 6 — Profil
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final c = AdaptiveColors.of(context);
    return Consumer2<AppProvider, LocaleProvider>(
      builder: (_, app, locale, child) {
        final l = locale.t;
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.divider, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            iconSize: 22,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard_rounded),
                label: l('nav_dashboard'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.map_outlined),
                activeIcon: const Icon(Icons.map_rounded),
                label: l('nav_map'),
              ),
              BottomNavigationBarItem(
                icon: _AlertIcon(count: app.unreadCount, active: false),
                activeIcon: _AlertIcon(count: app.unreadCount, active: true),
                label: l('nav_alerts'),
              ),
              // ── IA — tab central mis en avant ────────────────────────────
              BottomNavigationBarItem(
                icon: const Icon(Icons.psychology_outlined),
                activeIcon: const Icon(Icons.psychology_rounded),
                label: 'IA',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.bar_chart_outlined),
                activeIcon: const Icon(Icons.bar_chart_rounded),
                label: l('nav_reports'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.stars_outlined),
                activeIcon: const Icon(Icons.stars_rounded),
                label: 'Points',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                activeIcon: const Icon(Icons.person_rounded),
                label: l('nav_profile'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlertIcon extends StatelessWidget {
  final int count;
  final bool active;
  const _AlertIcon({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(active
            ? Icons.notifications_rounded
            : Icons.notifications_outlined),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: AppColors.red, shape: BoxShape.circle),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

class _RoleHome extends StatelessWidget {
  const _RoleHome();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role ?? UserRole.citoyen;
    switch (role) {
      case UserRole.agriculteur:
        return const FarmerHomeScreen();
      case UserRole.pecheur:
        return const FishermanHomeScreen();
      case UserRole.autorite:
        return const AuthorityHomeScreen();
      case UserRole.citoyen:
        return const HomeScreen();
    }
  }
}
