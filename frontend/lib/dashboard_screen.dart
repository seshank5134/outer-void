import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'app_state.dart';
import 'widgets.dart';

// Using widget.state.apiUrl in screens

// ════════════════════════════════════════════
//  AI Dashboard Screen
// ════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  final AppState state;
  const DashboardScreen({super.key, required this.state});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  double mentalBattery = 100.0, fatigueScore = 0.0;
  String burnoutTraj = '—', aiRec = 'Monitoring...', focusHalf = '—';
  String decisionQ = '—',
      recovery = '—',
      neuralAct = 'Standby',
      status = 'NOMINAL';
  int taskDone = 0, streak = 14;
  AppState get s => widget.state;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${s.token}',
        'Content-Type': 'application/json',
      };

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final r = await http.get(
        Uri.parse('${s.apiUrl}/fatigue-score'),
        headers: _headers,
      );
      if (r.statusCode == 200 && mounted) {
        final d = json.decode(r.body);
        setState(() {
          mentalBattery = (d['mental_battery'] as num).toDouble();
          fatigueScore = (d['fatigue_score'] as num).toDouble();
          burnoutTraj = d['burnout_trajectory'] ?? '—';
          aiRec = d['ai_recommendation'] ?? '—';
          focusHalf = d['focus_half_life'] ?? '—';
          decisionQ = d['decision_quality'] ?? '—';
          recovery = d['recovery_estimate'] ?? '—';
          neuralAct = d['neural_activity'] ?? 'Standby';
          taskDone = d['task_completion'] ?? 0;
          streak = d['streak_stability'] ?? 0;
          status = d['status_label'] ?? 'NOMINAL';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'EEEE, MMMM d',
    ).format(DateTime.now()).toUpperCase();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      color: s.accent.withOpacity(0.8),
                      fontSize: 11 * s.uiFontScale,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI BURNOUT PREDICTOR',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 26 * s.uiFontScale,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$streak DAYS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 22 * s.uiFontScale,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'STABILITY STREAK',
                    style: GoogleFonts.inter(
                      fontSize: 9 * s.uiFontScale,
                      color: Colors.white30,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Battery ring + metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Battery ring
              GlassCard(
                state: s,
                width: 200,
                height: 200,
                padding: EdgeInsets.zero,
                child: Center(
                  child: _BatteryRing(
                    battery: mentalBattery,
                    accent: s.accent,
                    scale: s.uiFontScale,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    MetricTile(
                      label: 'NEURAL ACTIVITY',
                      value: neuralAct.toUpperCase(),
                      icon: Icons.graphic_eq,
                      state: s,
                    ),
                    const SizedBox(height: 10),
                    MetricTile(
                      label: 'DECISION QUALITY',
                      value: decisionQ,
                      icon: Icons.psychology_alt,
                      state: s,
                    ),
                    const SizedBox(height: 10),
                    MetricTile(
                      label: 'FOCUS HALF-LIFE',
                      value: focusHalf,
                      icon: Icons.hourglass_bottom,
                      state: s,
                    ),
                    const SizedBox(height: 10),
                    MetricTile(
                      label: 'RECOVERY EST.',
                      value: recovery,
                      icon: Icons.battery_charging_full,
                      state: s,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Burnout & Rec cards
          GlassCard(
            state: s,
            borderColor: s.accent.withOpacity(0.3),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: s.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    SectionLabel('BURNOUT TRAJECTORY', state: s),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  burnoutTraj,
                  style: GoogleFonts.inter(
                    fontSize: 15 * s.uiFontScale,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            state: s,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal, color: s.accent, size: 16),
                    const SizedBox(width: 10),
                    SectionLabel('AI RECOMMENDATION', state: s),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  aiRec,
                  style: GoogleFonts.inter(
                    fontSize: 13 * s.uiFontScale,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'DAILY YIELD',
                  val: '$taskDone%',
                  state: s,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'FATIGUE IDX',
                  val: '$fatigueScore',
                  state: s,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'SYSTEM STATUS',
                  val: status,
                  state: s,
                  accentText: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatteryRing extends StatelessWidget {
  final double battery;
  final Color accent;
  final double scale;
  const _BatteryRing({
    required this.battery,
    required this.accent,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: battery / 100,
              strokeWidth: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(
                battery > 60
                    ? accent
                    : (battery > 30 ? Colors.orange : Colors.redAccent),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${battery.toStringAsFixed(0)}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 28 * scale,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              Text(
                'MENTAL\nBATTERY',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 8 * scale,
                  color: Colors.white30,
                  letterSpacing: 2,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, val;
  final AppState state;
  final bool accentText;
  const _StatBox({
    required this.label,
    required this.val,
    required this.state,
    this.accentText = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    return GlassCard(
      state: s,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9 * s.uiFontScale,
              color: Colors.white24,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18 * s.uiFontScale,
              fontWeight: FontWeight.w500,
              color: accentText ? s.accent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
//  Task Bucket Screen
// ════════════════════════════════════════════
class TaskScreen extends StatefulWidget {
  final AppState state;
  const TaskScreen({super.key, required this.state});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<dynamic> _tasks = [];
  DateTime _date = DateTime.now();
  bool _loading = true;

  AppState get s => widget.state;
  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${s.token}',
        'Content-Type': 'application/json',
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    try {
      final r = await http.get(
        Uri.parse('${s.apiUrl}/tasks?date=$dateStr'),
        headers: _headers,
      );
      if (!mounted) return;
      setState(() {
        if (r.statusCode == 200) _tasks = json.decode(r.body);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(int id) async {
    await http.post(Uri.parse('${s.apiUrl}/tasks/$id/toggle'),
        headers: _headers);
    _load();
  }

  Future<void> _delete(int id) async {
    await http.delete(Uri.parse('${s.apiUrl}/tasks/$id'), headers: _headers);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final done = _tasks.where((t) => t['completed'] == true).length;
    final total = _tasks.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel('TASK BUCKET ARRAY', state: s, fontSize: 11),
                  const SizedBox(height: 6),
                  Text(
                    '$done / $total completed',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12 * s.uiFontScale,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (c, ch) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ColorScheme.dark(primary: s.accent),
                    ),
                    child: ch!,
                  ),
                );
                if (d != null) {
                  _date = d;
                  _load();
                }
              },
              child: GlassCard(
                state: s,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: s.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d').format(_date),
                      style: GoogleFonts.inter(
                        fontSize: 12 * s.uiFontScale,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _showAddTask,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.accent.withOpacity(0.15),
                  border: Border.all(color: s.accent.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: s.accent.withOpacity(0.3), blurRadius: 12),
                  ],
                ),
                child: Icon(Icons.add, color: s.accent, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(s.accent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: s.accent))
              : _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dns_outlined,
                            size: 48,
                            color: s.accent.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'EMPTY ARRAY',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white24,
                              letterSpacing: 4,
                              fontSize: 14 * s.uiFontScale,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No tasks for this date',
                            style: GoogleFonts.inter(
                              color: Colors.white12,
                              fontSize: 12 * s.uiFontScale,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (ctx, i) => _taskCard(_tasks[i]),
                    ),
        ),
      ],
    );
  }

  Widget _taskCard(dynamic t) {
    final done = t['completed'] == true;
    final pri = t['priority'] ?? 'medium';
    final priColor = pri == 'high'
        ? Colors.redAccent
        : pri == 'medium'
            ? Colors.amber
            : Colors.white30;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        state: s,
        borderColor: done ? s.accent.withOpacity(0.2) : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggle(t['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? s.accent.withOpacity(0.2) : Colors.transparent,
                  border: Border.all(
                    color: done ? s.accent : Colors.white24,
                    width: 2,
                  ),
                  boxShadow: done
                      ? [
                          BoxShadow(
                            color: s.accent.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: done
                    ? Icon(Icons.check, color: s.accent, size: 14)
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['name'],
                    style: GoogleFonts.inter(
                      fontSize: 14 * s.uiFontScale,
                      fontWeight: FontWeight.w600,
                      color: done ? Colors.white30 : Colors.white,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white30,
                    ),
                  ),
                  if ((t['notes'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      t['notes'],
                      style: GoogleFonts.inter(
                        fontSize: 10 * s.uiFontScale,
                        color: Colors.white24,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: priColor.withOpacity(0.12),
                border: Border.all(color: priColor.withOpacity(0.3)),
              ),
              child: Text(
                pri.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 8 * s.uiFontScale,
                  color: priColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              color: Colors.white12,
              onPressed: () => _delete(t['id']),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTask() {
    String name = '', notes = '';
    String priority = 'medium';
    TimeOfDay? reminder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              border: Border.all(color: s.accent.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'NEW TASK',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18 * s.uiFontScale,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 24),
                _sheetField('TASK NAME', (v) => name = v, ctx),
                const SizedBox(height: 12),
                _sheetField('NOTES (optional)', (v) => notes = v, ctx),
                const SizedBox(height: 20),
                SectionLabel('PRIORITY', state: s),
                const SizedBox(height: 10),
                Row(
                  children: ['low', 'medium', 'high'].map((p) {
                    final active = priority == p;
                    final c = p == 'high'
                        ? Colors.redAccent
                        : p == 'medium'
                            ? Colors.amber
                            : Colors.white38;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: active
                                ? c.withOpacity(0.2)
                                : Colors.white.withOpacity(0.04),
                            border: Border.all(
                              color: active ? c : Colors.white12,
                            ),
                          ),
                          child: Text(
                            p.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10 * s.uiFontScale,
                              color: active ? c : Colors.white24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                GlowButton(
                  label: 'ADD TASK',
                  state: s,
                  icon: Icons.add,
                  onPressed: () async {
                    if (name.isEmpty) return;
                    await http.post(
                      Uri.parse('${s.apiUrl}/tasks'),
                      headers: _headers,
                      body: json.encode({
                        'name': name,
                        'notes': notes,
                        'priority': priority,
                        'date': DateFormat('yyyy-MM-dd').format(_date),
                        'reminders': (() {
                          final r = reminder;
                          return r != null
                              ? ['${r.hour}:${r.minute}']
                              : <String>[];
                        })(),
                      }),
                    );
                    Navigator.pop(ctx);
                    _load();
                  },
                ),
                const SizedBox(height: 12),
                GlowButton(
                  label: 'CANCEL',
                  state: s,
                  outline: true,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    String hint,
    ValueChanged<String> onChange,
    BuildContext ctx,
  ) {
    return TextField(
      onChanged: onChange,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14 * s.uiFontScale,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: Colors.white24,
          letterSpacing: 1,
          fontSize: 11 * s.uiFontScale,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s.cardBorderRadius.toDouble()),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s.cardBorderRadius.toDouble()),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(s.cardBorderRadius.toDouble()),
          borderSide: BorderSide(color: s.accent.withOpacity(0.6)),
        ),
      ),
    );
  }
}
