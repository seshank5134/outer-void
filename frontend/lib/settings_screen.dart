import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.state,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('CONTROL PANEL', state: s, fontSize: 11),
          const SizedBox(height: 24),

          // ── Themes ──────────────────────────────
          _sectionCard(s, 'BACKGROUND THEME', Icons.palette, [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kThemePresets.map((t) {
                final active = s.themeName == t.id;
                return GestureDetector(
                  onTap: () => s.updateTheme(t.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        s.cardBorderRadius.toDouble(),
                      ),
                      gradient: LinearGradient(
                        colors: [t.bgEnd, t.bgStart],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: active ? t.accent : Colors.white12,
                        width: active ? 2 : 1,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: t.accent.withOpacity(0.4),
                                blurRadius: 12,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.accent,
                            boxShadow: [
                              BoxShadow(
                                color: t.accent.withOpacity(0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.label,
                          style: GoogleFonts.inter(
                            fontSize: 10 * s.uiFontScale,
                            color: active ? Colors.white : Colors.white54,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Glass opacity ────────────────────────
          _sectionCard(s, 'GLASS EFFECT', Icons.blur_on, [
            _sliderRow(
              s,
              'OPACITY',
              s.glassOpacity,
              0.02,
              0.2,
              '${(s.glassOpacity * 100).toStringAsFixed(0)}%',
              (v) => s.updateGlassOpacity(v),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Font & Layout ────────────────────────
          _sectionCard(s, 'UI LAYOUT', Icons.tune, [
            _sliderRow(
              s,
              'FONT SCALE',
              s.uiFontScale,
              0.8,
              1.4,
              '${s.uiFontScale.toStringAsFixed(1)}x',
              (v) => s.updateFontScale(double.parse(v.toStringAsFixed(1))),
            ),
            const SizedBox(height: 8),
            _sliderRow(
              s,
              'SIDEBAR WIDTH',
              s.sidebarWidthPref.toDouble(),
              200,
              340,
              '${s.sidebarWidthPref}px',
              (v) => s.updateSidebarWidth(v.round()),
            ),
            const SizedBox(height: 8),
            _sliderRow(
              s,
              'CARD RADIUS',
              s.cardBorderRadius.toDouble(),
              0,
              32,
              '${s.cardBorderRadius}px',
              (v) => s.updateCardRadius(v.round()),
            ),
            const SizedBox(height: 16),
            _switchRow(s, 'ANIMATIONS', s.showAnimations, s.toggleAnimations),
            _switchRow(s, 'COMPACT MODE', s.compactMode, s.toggleCompact),
          ]),
          const SizedBox(height: 16),

          // ── Pomodoro ─────────────────────────────
          _sectionCard(s, 'POMODORO DEFAULTS', Icons.timer_outlined, [
            _sliderRow(
              s,
              'FOCUS DURATION',
              s.pomodoroWorkMins.toDouble(),
              5,
              90,
              '${s.pomodoroWorkMins}m',
              (v) => s.updatePomodoroWork(v.round()),
            ),
            const SizedBox(height: 8),
            _sliderRow(
              s,
              'SHORT BREAK',
              s.pomodoroBreakMins.toDouble(),
              1,
              30,
              '${s.pomodoroBreakMins}m',
              (v) => s.updatePomodoroBreak(v.round()),
            ),
            const SizedBox(height: 8),
            _sliderRow(
              s,
              'LONG BREAK',
              s.pomodoroLongBreakMins.toDouble(),
              5,
              60,
              '${s.pomodoroLongBreakMins}m',
              (v) => s.updatePomodoroLongBreak(v.round()),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Account ──────────────────────────────
          _sectionCard(s, 'ACCOUNT', Icons.person_outline, [
            if (state.user != null) ...[
              _infoRow(s, 'USERNAME', state.user!['username'] ?? '—'),
              const SizedBox(height: 8),
              _infoRow(s, 'EMAIL', state.user!['email'] ?? '—'),
              const SizedBox(height: 20),
            ],
            GlowButton(
              label: 'SIGN OUT',
              state: s,
              outline: true,
              icon: Icons.logout,
              onPressed: onLogout,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionCard(
    AppState s,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return GlassCard(
      state: s,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: s.accent, size: 16),
              const SizedBox(width: 10),
              SectionLabel(title, state: s),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _sliderRow(
    AppState s,
    String label,
    double val,
    double min,
    double max,
    String display,
    ValueChanged<double> onChange,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10 * s.uiFontScale,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: s.accent,
              thumbColor: s.accent,
              inactiveTrackColor: Colors.white10,
              overlayColor: s.accent.withOpacity(0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(value: val, min: min, max: max, onChanged: onChange),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            display,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11 * s.uiFontScale,
              color: s.accent,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _switchRow(
    AppState s,
    String label,
    bool val,
    ValueChanged<bool> onChange,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12 * s.uiFontScale,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        Switch(
          value: val,
          onChanged: onChange,
          activeColor: s.accent,
          inactiveThumbColor: Colors.white24,
          inactiveTrackColor: Colors.white10,
        ),
      ],
    );
  }

  Widget _infoRow(AppState s, String label, String val) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10 * s.uiFontScale,
            color: Colors.white24,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 13 * s.uiFontScale,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
