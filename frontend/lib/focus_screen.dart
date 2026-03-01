import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';
import 'widgets.dart';

class FocusScreen extends StatefulWidget {
  final AppState state;
  const FocusScreen({super.key, required this.state});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  late int _seconds;
  bool _running = false;
  bool _isBreak = false;
  int _sessionsDone = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  AppState get s => widget.state;

  @override
  void initState() {
    super.initState();
    _seconds = s.pomodoroWorkMins * 60;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  int get _totalSecs => _isBreak
      ? (_sessionsDone > 0 && _sessionsDone % s.pomodoroSessionsBeforeLong == 0
          ? s.pomodoroLongBreakMins * 60
          : s.pomodoroBreakMins * 60)
      : s.pomodoroWorkMins * 60;

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            t.cancel();
            _running = false;
            if (!_isBreak) _sessionsDone++;
            _isBreak = !_isBreak;
            _seconds = _totalSecs;
          }
        });
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _isBreak = false;
      _seconds = s.pomodoroWorkMins * 60;
    });
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final ss = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  double get _progress => _seconds / _totalSecs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SectionLabel(
              _isBreak ? 'RECOVERY PROTOCOL' : 'EXECUTION PROTOCOL',
              state: s,
              fontSize: 12,
            ),
            const SizedBox(height: 12),
            Text(
              _isBreak
                  ? 'Recharge your neural engine'
                  : 'Deep focus — eliminate distractions',
              style: GoogleFonts.inter(
                color: Colors.white30,
                fontSize: 13 * s.uiFontScale,
              ),
            ),
            const SizedBox(height: 48),

            // ── Circular Timer ──
            ScaleTransition(
              scale: _running ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow ring
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: s.accent.withOpacity(_running ? 0.25 : 0.08),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Progress arc
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CustomPaint(
                        painter: _ArcPainter(
                          _progress,
                          s.accent,
                          _isBreak ? Colors.tealAccent : s.accent,
                        ),
                      ),
                    ),
                    // Time text
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _fmt(_seconds),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 56 * s.uiFontScale,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '#${_sessionsDone + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 12 * s.uiFontScale,
                            color: s.accent.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // ── Controls ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlBtn(
                  icon: Icons.refresh_rounded,
                  onTap: _reset,
                  state: s,
                  outline: true,
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: _toggleTimer,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.accent.withOpacity(0.15),
                      border: Border.all(color: s.accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: s.accent.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      _running ? Icons.pause : Icons.play_arrow,
                      color: s.accent,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                _ControlBtn(
                  icon: Icons.skip_next_rounded,
                  onTap: () => setState(() {
                    _timer?.cancel();
                    _running = false;
                    if (!_isBreak) _sessionsDone++;
                    _isBreak = !_isBreak;
                    _seconds = _totalSecs;
                  }),
                  state: s,
                  outline: true,
                ),
              ],
            ),
            const SizedBox(height: 48),
            _sessionsBar(),
            const SizedBox(height: 48),
            _settingsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _sessionsBar() {
    return GlassCard(
      state: s,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(s.pomodoroSessionsBeforeLong, (i) {
          final done = i < _sessionsDone % s.pomodoroSessionsBeforeLong ||
              (_sessionsDone % s.pomodoroSessionsBeforeLong == 0 &&
                  _sessionsDone > 0);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: done ? s.accent : Colors.white12,
              boxShadow: done
                  ? [BoxShadow(color: s.accent.withOpacity(0.5), blurRadius: 8)]
                  : [],
            ),
          );
        }),
      ),
    );
  }

  Widget _settingsPanel() {
    return GlassCard(
      state: s,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('TIMER CONFIGURATION', state: s),
          const SizedBox(height: 20),
          _sliderRow('FOCUS', s.pomodoroWorkMins, 5, 90, (v) {
            s.updatePomodoroWork(v.round());
            if (!_running && !_isBreak)
              setState(() => _seconds = v.round() * 60);
          }),
          _sliderRow(
            'SHORT BREAK',
            s.pomodoroBreakMins,
            1,
            30,
            (v) => s.updatePomodoroBreak(v.round()),
          ),
          _sliderRow(
            'LONG BREAK',
            s.pomodoroLongBreakMins,
            5,
            60,
            (v) => s.updatePomodoroLongBreak(v.round()),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(
    String label,
    int val,
    int min,
    int max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10 * s.uiFontScale,
                color: Colors.white38,
                letterSpacing: 1.5,
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
              child: Slider(
                value: val.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${val}m',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12 * s.uiFontScale,
                color: s.accent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppState state;
  final bool outline;

  const _ControlBtn({
    required this.icon,
    required this.onTap,
    required this.state,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white54, size: 24),
      ),
    );
  }
}

// Custom arc painter for circular progress
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color tip;

  _ArcPainter(this.progress, this.accent, this.tip);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) - 4;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Background track
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.white10,
    );

    // Progress arc with gradient
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi * progress,
        colors: [accent.withOpacity(0.5), accent],
        tileMode: TileMode.clamp,
      ).createShader(rect);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
