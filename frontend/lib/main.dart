import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'app_state.dart';
import 'widgets.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'focus_screen.dart';
import 'habit_screen.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.loadFromPrefs();
  runApp(VoidOSApp(state: state));
}

class VoidOSApp extends StatelessWidget {
  final AppState state;
  const VoidOSApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) => MaterialApp(
        title: 'VOID OS: AI Burnout Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.transparent,
          primaryColor: state.accent,
          fontFamily: GoogleFonts.inter().fontFamily,
          colorScheme: ColorScheme.dark(primary: state.accent),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                state.cardBorderRadius.toDouble(),
              ),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                state.cardBorderRadius.toDouble(),
              ),
              borderSide: BorderSide(color: state.accent.withOpacity(0.7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                state.cardBorderRadius.toDouble(),
              ),
              borderSide: const BorderSide(color: Colors.white12),
            ),
          ),
        ),
        home: state.isLoggedIn
            ? MainShell(state: state)
            : AuthScreen(
                state: state,
                onAuthSuccess:
                    () {}, // Rebuilt by AnimatedBuilder automatically
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Main Shell  — sidebar + content
// ═══════════════════════════════════════════════
class MainShell extends StatefulWidget {
  final AppState state;
  const MainShell({super.key, required this.state});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _screen = 0;
  bool _settingsOpen = false;

  AppState get s => widget.state;

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _fetchPrefs();
  }

  Future<void> _fetchUser() async {
    try {
      final r = await http.get(
        Uri.parse('${s.apiUrl}/auth/me'),
        headers: {'Authorization': 'Bearer ${s.token}'},
      );
      if (r.statusCode == 200 && mounted) {
        s.setUser(Map<String, dynamic>.from(json.decode(r.body)));
      } else if (r.statusCode == 401) {
        s.logout();
      }
    } catch (_) {}
  }

  Future<void> _fetchPrefs() async {
    try {
      final r = await http.get(
        Uri.parse('${s.apiUrl}/preferences'),
        headers: {'Authorization': 'Bearer ${s.token}'},
      );
      if (r.statusCode == 200 && mounted) {
        s.applyPrefsFromServer(json.decode(r.body));
      }
    } catch (_) {}
  }

  void _logout() {
    s.logout();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      body: GradientBackground(
        state: s,
        child: isWide ? _wideLayout() : _narrowLayout(),
      ),
    );
  }

  Widget _wideLayout() {
    return AnimatedBuilder(
      animation: s,
      builder: (_, __) => Row(
        children: [
          _Sidebar(
            state: s,
            activeIndex: _settingsOpen ? -1 : _screen,
            settingsOpen: _settingsOpen,
            onSelect: (i) => setState(() {
              _screen = i;
              _settingsOpen = false;
            }),
            onSettings: () => setState(() => _settingsOpen = !_settingsOpen),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(s.compactMode ? 20 : 32),
              child: _settingsOpen
                  ? SettingsScreen(state: s, onLogout: _logout)
                  : IndexedStack(index: _screen, children: _screens()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrowLayout() {
    return AnimatedBuilder(
      animation: s,
      builder: (_, __) => Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _settingsOpen
                  ? SettingsScreen(state: s, onLogout: _logout)
                  : IndexedStack(index: _screen, children: _screens()),
            ),
          ),
          _BottomNav(
            state: s,
            activeIndex: _settingsOpen ? -1 : _screen,
            settingsOpen: _settingsOpen,
            onSelect: (i) => setState(() {
              _screen = i;
              _settingsOpen = false;
            }),
            onSettings: () => setState(() => _settingsOpen = !_settingsOpen),
          ),
        ],
      ),
    );
  }

  List<Widget> _screens() => [
        DashboardScreen(state: s),
        FocusScreen(state: s),
        HabitScreen(state: s),
        TaskScreen(state: s),
      ];
}

// ═══════════════════════════════════════════════
//  Sidebar  (desktop/tablet)
// ═══════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  final AppState state;
  final int activeIndex;
  final bool settingsOpen;
  final ValueChanged<int> onSelect;
  final VoidCallback onSettings;

  const _Sidebar({
    required this.state,
    required this.activeIndex,
    required this.settingsOpen,
    required this.onSelect,
    required this.onSettings,
  });

  static const _navItems = [
    (icon: Icons.psychology, label: 'AI PREDICTOR'),
    (icon: Icons.timer_outlined, label: 'FOCUS ENGINE'),
    (icon: Icons.stream, label: 'HABIT SYNC'),
    (icon: Icons.dns_outlined, label: 'TASK BUCKET'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = state;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: s.sidebarWidthPref.toDouble(),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: s.accent.withOpacity(0.1), width: 1),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.01),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 52),

          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.accent.withOpacity(0.15),
                    boxShadow: [
                      BoxShadow(
                        color: s.accent.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(Icons.blur_on, color: s.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'VOID_OS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16 * s.uiFontScale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Username
          if (s.user?['username'] != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  const SizedBox(width: 36 + 12), // align with text
                  Text(
                    '@${s.user!['username']}',
                    style: GoogleFonts.inter(
                      fontSize: 10 * s.uiFontScale,
                      color: s.accent.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 48),

          // Nav items
          ...List.generate(_navItems.length, (i) => _navItem(i, s)),

          const Spacer(),

          // System pulse
          _systemPulse(s),

          // Settings
          _navSettingsItem(s),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _navItem(int i, AppState s) {
    final active = activeIndex == i;
    final item = _navItems[i];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: active ? s.accent.withOpacity(0.12) : Colors.transparent,
        border: Border.all(
          color: active ? s.accent.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: active ? s.accent : Colors.white24,
                ),
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 11 * s.uiFontScale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: active ? Colors.white : Colors.white30,
                  ),
                ),
                if (active) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.accent,
                      boxShadow: [BoxShadow(color: s.accent, blurRadius: 4)],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navSettingsItem(AppState s) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(12, 3, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: settingsOpen ? s.accent.withOpacity(0.12) : Colors.transparent,
        border: Border.all(
          color: settingsOpen ? s.accent.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onSettings,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 18,
                  color: settingsOpen ? s.accent : Colors.white24,
                ),
                const SizedBox(width: 16),
                Text(
                  'CONTROL PANEL',
                  style: GoogleFonts.inter(
                    fontSize: 11 * s.uiFontScale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: settingsOpen ? Colors.white : Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _systemPulse(AppState s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GlassCard(
        state: s,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SYSTEM PULSE',
              style: GoogleFonts.inter(
                fontSize: 8 * s.uiFontScale,
                color: Colors.white24,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(s.accent),
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Bottom Nav  (mobile)
// ═══════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final AppState state;
  final int activeIndex;
  final bool settingsOpen;
  final ValueChanged<int> onSelect;
  final VoidCallback onSettings;

  const _BottomNav({
    required this.state,
    required this.activeIndex,
    required this.settingsOpen,
    required this.onSelect,
    required this.onSettings,
  });

  static const _items = [
    (icon: Icons.psychology, label: 'AI'),
    (icon: Icons.timer_outlined, label: 'FOCUS'),
    (icon: Icons.stream, label: 'HABITS'),
    (icon: Icons.dns_outlined, label: 'TASKS'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = state;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: s.accent.withOpacity(0.1))),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.04), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ..._items.asMap().entries.map((e) {
            final active = activeIndex == e.key;
            return GestureDetector(
              onTap: () => onSelect(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color:
                      active ? s.accent.withOpacity(0.15) : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      e.value.icon,
                      color: active ? s.accent : Colors.white24,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.value.label,
                      style: GoogleFonts.inter(
                        fontSize: 8 * s.uiFontScale,
                        color: active ? s.accent : Colors.white24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: onSettings,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    color: settingsOpen ? s.accent : Colors.white24,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.inter(
                      fontSize: 8 * s.uiFontScale,
                      color: settingsOpen ? s.accent : Colors.white24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
