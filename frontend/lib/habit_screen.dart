import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'app_state.dart';
import 'widgets.dart';

// Dynamic API URL from s.apiUrl

// Available icon options for habits
const _kIcons = {
  'code': Icons.code,
  'water_drop': Icons.water_drop,
  'self_improvement': Icons.self_improvement,
  'fitness_center': Icons.fitness_center,
  'book': Icons.menu_book,
  'brush': Icons.brush,
  'music_note': Icons.music_note,
  'language': Icons.language,
  'bedtime': Icons.bedtime,
  'directions_run': Icons.directions_run,
  'favorite': Icons.favorite,
  'star': Icons.star,
};

const _kCategories = [
  'general',
  'health',
  'productivity',
  'wellness',
  'learning',
  'creativity',
];

const _kColors = [
  ('0xFFEF4444', Color(0xFFEF4444)),
  ('0xFF3B82F6', Color(0xFF3B82F6)),
  ('0xFF10B981', Color(0xFF10B981)),
  ('0xFFF59E0B', Color(0xFFF59E0B)),
  ('0xFF8B5CF6', Color(0xFF8B5CF6)),
  ('0xFFEC4899', Color(0xFFEC4899)),
  ('0xFF06B6D4', Color(0xFF06B6D4)),
  ('0xFFFF6B35', Color(0xFFFF6B35)),
];

class HabitScreen extends StatefulWidget {
  final AppState state;
  const HabitScreen({super.key, required this.state});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _habits = [];
  Map<int, bool> _logs = {};
  DateTime _date = DateTime.now();
  bool _loading = true;
  late TabController _tab;

  AppState get s => widget.state;
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${s.token}',
      };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    try {
      final rH =
          await http.get(Uri.parse('${s.apiUrl}/habits'), headers: _headers);
      final rL = await http.get(
        Uri.parse('${s.apiUrl}/habit-logs/$dateStr'),
        headers: _headers,
      );
      if (!mounted) return;
      setState(() {
        if (rH.statusCode == 200) _habits = json.decode(rH.body);
        if (rL.statusCode == 200) {
          final m = json.decode(rL.body) as Map;
          _logs = m.map((k, v) => MapEntry(int.parse(k), v as bool));
        }
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(int id, bool val) async {
    setState(() => _logs[id] = val);
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    await http.post(
      Uri.parse('${s.apiUrl}/habit-logs/$dateStr/$id'),
      headers: _headers,
      body: json.encode({'status': val}),
    );
  }

  Future<void> _delete(int id) async {
    await http.delete(Uri.parse('${s.apiUrl}/habits/$id'), headers: _headers);
    _load();
  }

  int get _completedToday =>
      _habits.where((h) => _logs[h['id']] == true).length;
  double get _todayProgress =>
      _habits.isEmpty ? 0 : _completedToday / _habits.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 24),
        _progressBar(),
        const SizedBox(height: 24),
        TabBar(
          controller: _tab,
          indicatorColor: s.accent,
          labelColor: s.accent,
          unselectedLabelColor: Colors.white30,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.inter(
            fontSize: 11 * s.uiFontScale,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
          tabs: const [
            Tab(text: 'TODAY'),
            Tab(text: 'HABIT LIBRARY'),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: s.accent))
              : TabBarView(
                  controller: _tab,
                  children: [_todayView(), _libraryView()],
                ),
        ),
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('HABIT SYNCHRONIZATION', state: s, fontSize: 11),
              const SizedBox(height: 8),
              Text(
                '${_completedToday}/${_habits.length} completed today',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13 * s.uiFontScale,
                ),
              ),
            ],
          ),
        ),
        // Date picker
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(primary: s.accent),
                ),
                child: child!,
              ),
            );
            if (d != null) {
              _date = d;
              _load();
            }
          },
          child: GlassCard(
            state: s,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: s.accent),
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
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _showAddHabitSheet,
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
    );
  }

  Widget _progressBar() {
    return GlassCard(
      state: s,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY COMPLETION',
                style: GoogleFonts.inter(
                  fontSize: 10 * s.uiFontScale,
                  color: Colors.white30,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${(_todayProgress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14 * s.uiFontScale,
                  color: s.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _todayProgress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(s.accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayView() {
    if (_habits.isEmpty)
      return _emptyState('No habits yet', 'Tap + to add your first habit');
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _habits.length,
      itemBuilder: (ctx, i) {
        final h = _habits[i];
        final done = _logs[h['id']] ?? false;
        final color = Color(int.parse(h['color']));
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            state: s,
            borderColor: done ? color.withOpacity(0.4) : null,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(done ? 0.25 : 0.1),
                    border: Border.all(
                      color: color.withOpacity(done ? 0.6 : 0.2),
                    ),
                  ),
                  child: Icon(
                    _kIcons[h['icon']] ?? Icons.circle,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['name'],
                        style: GoogleFonts.inter(
                          fontSize: 14 * s.uiFontScale,
                          fontWeight: FontWeight.w600,
                          color: done ? Colors.white38 : Colors.white,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${h['category']} • ${h['reminder']}',
                        style: GoogleFonts.inter(
                          fontSize: 10 * s.uiFontScale,
                          color: Colors.white30,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggle(h['id'], !done),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          done ? color.withOpacity(0.25) : Colors.transparent,
                      border: Border.all(
                        color: done ? color : Colors.white24,
                        width: 2,
                      ),
                      boxShadow: done
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: done
                        ? Icon(Icons.check, color: color, size: 16)
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _libraryView() {
    if (_habits.isEmpty)
      return _emptyState('No habits yet', 'Start building your routine');
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _habits.length,
      itemBuilder: (ctx, i) {
        final h = _habits[i];
        final color = Color(int.parse(h['color']));
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            state: s,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color.withOpacity(0.12),
                  ),
                  child: Icon(
                    _kIcons[h['icon']] ?? Icons.circle,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['name'],
                        style: GoogleFonts.inter(
                          fontSize: 14 * s.uiFontScale,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        h['description']?.isNotEmpty == true
                            ? h['description']
                            : h['category'],
                        style: GoogleFonts.inter(
                          fontSize: 10 * s.uiFontScale,
                          color: Colors.white30,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  h['reminder'],
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11 * s.uiFontScale,
                    color: color.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.white24,
                  onPressed: () => _delete(h['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stream, size: 48, color: s.accent.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 16 * s.uiFontScale,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: GoogleFonts.inter(
              color: Colors.white24,
              fontSize: 12 * s.uiFontScale,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddHabitSheet() {
    String name = '',
        selIcon = 'code',
        selColor = '0xFFEF4444',
        selCategory = 'general',
        desc = '';
    TimeOfDay selTime = const TimeOfDay(hour: 9, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollCtrl) => Container(
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
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(28),
              children: [
                // Drag handle
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
                const SizedBox(height: 24),
                Text(
                  'NEW HABIT',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 20 * s.uiFontScale,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Build your daily protocol',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13 * s.uiFontScale,
                  ),
                ),
                const SizedBox(height: 32),

                // Name field
                _sheetField('HABIT NAME', (v) => name = v, icon: Icons.stream),
                const SizedBox(height: 16),
                _sheetField(
                  'DESCRIPTION (optional)',
                  (v) => desc = v,
                  icon: Icons.notes,
                ),
                const SizedBox(height: 24),

                // Icon picker
                SectionLabel('ICON', state: s),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _kIcons.entries.map((e) {
                    final active = selIcon == e.key;
                    return GestureDetector(
                      onTap: () => setSheet(() => selIcon = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: active
                              ? s.accent.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: active ? s.accent : Colors.white12,
                          ),
                        ),
                        child: Icon(
                          e.value,
                          color: active ? s.accent : Colors.white38,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Color picker
                SectionLabel('COLOR', state: s),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _kColors.map((pair) {
                    final active = selColor == pair.$1;
                    return GestureDetector(
                      onTap: () => setSheet(() => selColor = pair.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pair.$2,
                          border: Border.all(
                            color: active ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: pair.$2.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: active
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Category picker
                SectionLabel('CATEGORY', state: s),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kCategories.map((cat) {
                    final active = selCategory == cat;
                    return GestureDetector(
                      onTap: () => setSheet(() => selCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: active
                              ? s.accent.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: active ? s.accent : Colors.white12,
                          ),
                        ),
                        child: Text(
                          cat.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10 * s.uiFontScale,
                            color: active ? s.accent : Colors.white38,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Reminder time
                SectionLabel('REMINDER TIME', state: s),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: selTime,
                      builder: (c, ch) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(primary: s.accent),
                        ),
                        child: ch!,
                      ),
                    );
                    if (t != null) setSheet(() => selTime = t);
                  },
                  child: GlassCard(
                    state: s,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.alarm, color: s.accent, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          selTime.format(ctx),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16 * s.uiFontScale,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'TAP TO CHANGE',
                          style: GoogleFonts.inter(
                            fontSize: 9 * s.uiFontScale,
                            color: Colors.white24,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                GlowButton(
                  label: 'CREATE HABIT',
                  state: s,
                  icon: Icons.add,
                  onPressed: () async {
                    if (name.isEmpty) return;
                    await http.post(
                      Uri.parse('${s.apiUrl}/habits'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ${s.token}',
                      },
                      body: json.encode({
                        'name': name,
                        'icon': selIcon,
                        'color': selColor,
                        'reminder':
                            '${selTime.hour}:${selTime.minute.toString().padLeft(2, '0')}',
                        'category': selCategory,
                        'description': desc,
                      }),
                    );
                    Navigator.pop(ctx);
                    _load();
                  },
                ),
                const SizedBox(height: 16),
                GlowButton(
                  label: 'CANCEL',
                  state: s,
                  outline: true,
                  onPressed: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    String hint,
    ValueChanged<String> onChange, {
    IconData? icon,
  }) {
    final s = widget.state;
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
          letterSpacing: 2,
          fontSize: 11 * s.uiFontScale,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: s.accent.withOpacity(0.5), size: 18)
            : null,
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
