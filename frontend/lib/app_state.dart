import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
//  Theme Presets
// ─────────────────────────────────────────────
class ThemePreset {
  final String id;
  final String label;
  final Color accent;
  final Color bgStart;
  final Color bgEnd;
  ThemePreset(this.id, this.label, this.accent, this.bgStart, this.bgEnd);
}

final List<ThemePreset> kThemePresets = [
  ThemePreset(
    'void_red',
    'VOID RED',
    const Color(0xFFEF4444),
    const Color(0xFF0A0505),
    const Color(0xFF1A0808),
  ),
  ThemePreset(
    'space_blue',
    'SPACE BLUE',
    const Color(0xFF60A5FA),
    const Color(0xFF050510),
    const Color(0xFF080820),
  ),
  ThemePreset(
    'forest_green',
    'FOREST GREEN',
    const Color(0xFF34D399),
    const Color(0xFF050A07),
    const Color(0xFF091A0E),
  ),
  ThemePreset(
    'solar_gold',
    'SOLAR GOLD',
    const Color(0xFFFBBF24),
    const Color(0xFF0A0805),
    const Color(0xFF1A1205),
  ),
  ThemePreset(
    'nebula_purple',
    'NEBULA PURPLE',
    const Color(0xFFA78BFA),
    const Color(0xFF080510),
    const Color(0xFF130A1E),
  ),
];

// ─────────────────────────────────────────────
//  AppState  (ChangeNotifier)
// ─────────────────────────────────────────────
class AppState extends ChangeNotifier {
  // Config
  static const String defaultApiUrl = 'http://172.18.117.105:8000/api/v1';
  String apiUrl = defaultApiUrl;

  // Auth
  String? token;
  Map<String, dynamic>? user;

  // Preferences (synced with backend + local prefs)
  int pomodoroWorkMins = 25;
  int pomodoroBreakMins = 5;
  int pomodoroLongBreakMins = 15;
  int pomodoroSessionsBeforeLong = 4;
  String themeName = 'void_red';
  double glassOpacity = 0.08;
  double uiFontScale = 1.0;
  int sidebarWidthPref = 280;
  int cardBorderRadius = 16;
  bool showAnimations = true;
  bool compactMode = false;

  ThemePreset get currentTheme => kThemePresets.firstWhere(
        (t) => t.id == themeName,
        orElse: () => kThemePresets.first,
      );

  Color get accent => currentTheme.accent;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  // ── Persistence ──────────────────────────────
  Future<void> loadFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token') ?? '';
    user = {}; // will be fetched from /me

    pomodoroWorkMins = p.getInt('pomodoro_work_mins') ?? 25;
    pomodoroBreakMins = p.getInt('pomodoro_break_mins') ?? 5;
    pomodoroLongBreakMins = p.getInt('pomodoro_long_break_mins') ?? 15;
    pomodoroSessionsBeforeLong = p.getInt('pomodoro_sessions_before_long') ?? 4;
    themeName = p.getString('theme_name') ?? 'void_red';
    glassOpacity = p.getDouble('glass_opacity') ?? 0.08;
    uiFontScale = p.getDouble('ui_font_scale') ?? 1.0;
    sidebarWidthPref = p.getInt('sidebar_width') ?? 280;
    cardBorderRadius = p.getInt('card_border_radius') ?? 16;
    showAnimations = p.getBool('show_animations') ?? true;
    compactMode = p.getBool('compact_mode') ?? false;
    notifyListeners();
  }

  Future<void> savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token ?? '');
    await p.setInt('pomodoro_work_mins', pomodoroWorkMins);
    await p.setInt('pomodoro_break_mins', pomodoroBreakMins);
    await p.setInt('pomodoro_long_break_mins', pomodoroLongBreakMins);
    await p.setInt('pomodoro_sessions_before_long', pomodoroSessionsBeforeLong);
    await p.setString('theme_name', themeName);
    await p.setDouble('glass_opacity', glassOpacity);
    await p.setDouble('ui_font_scale', uiFontScale);
    await p.setInt('sidebar_width', sidebarWidthPref);
    await p.setInt('card_border_radius', cardBorderRadius);
    await p.setBool('show_animations', showAnimations);
    await p.setBool('compact_mode', compactMode);
  }

  void applyPrefsFromServer(Map<String, dynamic> data) {
    pomodoroWorkMins = data['pomodoro_work_mins'] ?? pomodoroWorkMins;
    pomodoroBreakMins = data['pomodoro_break_mins'] ?? pomodoroBreakMins;
    pomodoroLongBreakMins =
        data['pomodoro_long_break_mins'] ?? pomodoroLongBreakMins;
    pomodoroSessionsBeforeLong =
        data['pomodoro_sessions_before_long'] ?? pomodoroSessionsBeforeLong;
    themeName = data['theme_name'] ?? themeName;
    glassOpacity = (data['glass_opacity'] as num?)?.toDouble() ?? glassOpacity;
    uiFontScale = (data['ui_font_scale'] as num?)?.toDouble() ?? uiFontScale;
    sidebarWidthPref = data['sidebar_width'] ?? sidebarWidthPref;
    cardBorderRadius = data['card_border_radius'] ?? cardBorderRadius;
    showAnimations = data['show_animations'] ?? showAnimations;
    compactMode = data['compact_mode'] ?? compactMode;
    savePrefs();
    notifyListeners();
  }

  void setToken(String t, Map<String, dynamic> u) {
    token = t;
    user = u;
    savePrefs();
    notifyListeners();
  }

  void setUser(Map<String, dynamic> u) {
    user = u;
    notifyListeners();
  }

  void logout() {
    token = '';
    user = null;
    savePrefs();
    notifyListeners();
  }

  void updateTheme(String id) {
    themeName = id;
    savePrefs();
    notifyListeners();
  }

  void updateFontScale(double v) {
    uiFontScale = v;
    savePrefs();
    notifyListeners();
  }

  void updateGlassOpacity(double v) {
    glassOpacity = v;
    savePrefs();
    notifyListeners();
  }

  void updateSidebarWidth(int v) {
    sidebarWidthPref = v;
    savePrefs();
    notifyListeners();
  }

  void updateCardRadius(int v) {
    cardBorderRadius = v;
    savePrefs();
    notifyListeners();
  }

  void updatePomodoroWork(int v) {
    pomodoroWorkMins = v;
    savePrefs();
    notifyListeners();
  }

  void updatePomodoroBreak(int v) {
    pomodoroBreakMins = v;
    savePrefs();
    notifyListeners();
  }

  void updatePomodoroLongBreak(int v) {
    pomodoroLongBreakMins = v;
    savePrefs();
    notifyListeners();
  }

  void toggleAnimations(bool v) {
    showAnimations = v;
    savePrefs();
    notifyListeners();
  }

  void toggleCompact(bool v) {
    compactMode = v;
    savePrefs();
    notifyListeners();
  }
}
