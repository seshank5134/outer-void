import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const VoidOSApp());
}

class VoidOSApp extends StatelessWidget {
  const VoidOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VOID OS: AI Burnout Monitor',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        cardColor: const Color(0xFF070707),
        primaryColor: Colors.redAccent,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.02),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const MainInterface(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainInterface extends StatefulWidget {
  const MainInterface({super.key});

  @override
  State<MainInterface> createState() => _MainInterfaceState();
}

class _MainInterfaceState extends State<MainInterface> {
  int _activeScreen = 0;
  DateTime _calendarDate = DateTime.now();

  // AI Prediction & System State
  double mentalBattery = 100.0;
  double fatigueScore = 0.0;
  String burnoutTrajectory = "Analyzing...";
  String focusHalfLife = "Calculating...";
  String decisionQuality = "Assessing...";
  String recoveryEstimate = "Calculating...";
  String aiRecommendation = "Monitoring activity feeds...";
  String neuralActivity = "Standby";
  String statusLabel = "NOMINAL";
  int taskCompletion = 0;
  int pulseStreak = 14;
  Map<String, dynamic> adaptivePomodoro = {};

  // External Module Data
  List<dynamic> habitRegistry = [];
  Map<int, bool> habitLogs = {};
  List<dynamic> bucketTasks = [];

  Timer? _aiPredictorTimer;

  // Pomodoro Local Logic
  Timer? _pomodoroTimer;
  int _pSeconds = 1500;
  bool _pRunning = false;
  bool _pBreak = false;

  @override
  void initState() {
    super.initState();
    _startAIPredictor();
    _syncModules();
  }

  @override
  void dispose() {
    _aiPredictorTimer?.cancel();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  void _startAIPredictor() {
    _fetchAIPrediction();
    _aiPredictorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchAIPrediction(),
    );
  }

  Future<void> _fetchAIPrediction() async {
    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/v1/fatigue-score'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          mentalBattery = data['mental_battery'];
          fatigueScore = data['fatigue_score'];
          burnoutTrajectory = data['burnout_trajectory'];
          focusHalfLife = data['focus_half_life'];
          decisionQuality = data['decision_quality'];
          recoveryEstimate = data['recovery_estimate'];
          aiRecommendation = data['ai_recommendation'];
          neuralActivity = data['neural_activity'];
          adaptivePomodoro = data['adaptive_pomodoro'] ?? {};
          taskCompletion = data['task_completion'];
          pulseStreak = data['streak_stability'];
          statusLabel = data['status_label'];

          if (!_pRunning && !_pBreak) {
            _pSeconds = (adaptivePomodoro['work_mins'] ?? 25) * 60;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _syncModules() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_calendarDate);
    try {
      final resH = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/v1/habits'),
      );
      final resL = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/v1/habit-logs/$dateStr'),
      );
      final resT = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/v1/tasks?date=$dateStr'),
      );

      if (resH.statusCode == 200) habitRegistry = json.decode(resH.body);
      if (resL.statusCode == 200) {
        final logs = json.decode(resL.body) as Map;
        habitLogs = logs.map((k, v) => MapEntry(int.parse(k), v as bool));
      }
      if (resT.statusCode == 200) bucketTasks = json.decode(resT.body);
      setState(() {});
    } catch (_) {}
  }

  // --- MODULE ACTIONS ---

  void _toggleHabit(int id, bool val) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_calendarDate);
    await http.post(
      Uri.parse('http://127.0.0.1:8000/api/v1/habit-logs/$dateStr/$id'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"status": val}),
    );
    _syncModules();
  }

  void _toggleTask(int id) async {
    await http.post(Uri.parse('http://127.0.0.1:8000/api/v1/tasks/$id/toggle'));
    _syncModules();
  }

  void _startStopPomodoro() {
    if (_pRunning) {
      _pomodoroTimer?.cancel();
      setState(() => _pRunning = false);
    } else {
      setState(() => _pRunning = true);
      _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_pSeconds > 0) {
            _pSeconds--;
          } else {
            _pomodoroTimer?.cancel();
            _pRunning = false;
            _pBreak = !_pBreak;
            _pSeconds = _pBreak
                ? (adaptivePomodoro['break_mins'] ?? 5) * 60
                : (adaptivePomodoro['work_mins'] ?? 25) * 60;
          }
        });
      });
    }
  }

  // --- UI CONSTRUCTION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
              child: IndexedStack(
                index: _activeScreen,
                children: [
                  _buildAIDashboard(), // 0
                  _buildFocusEngine(), // 1
                  _buildHabitModule(), // 2
                  _buildTaskBucket(), // 3
                  _buildNeuralAnalytics(), // 4
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF030303),
        border: Border(right: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.blur_on, color: Colors.redAccent, size: 36),
              SizedBox(width: 15),
              Text(
                'VOID_OS',
                style: TextStyle(
                  letterSpacing: 6,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 70),
          _sidebarLink(0, Icons.psychology, 'AI_PREDICTOR'),
          _sidebarLink(1, Icons.timer_outlined, 'PULSE_TIMER'),
          _sidebarLink(2, Icons.stream, 'HABIT_SYNC'),
          _sidebarLink(3, Icons.dns_outlined, 'TASK_BUCKET'),
          _sidebarLink(4, Icons.graphic_eq, 'NEURAL_STATS'),
          const Spacer(),
          _systemHealthWidget(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sidebarLink(int index, IconData icon, String label) {
    bool active = _activeScreen == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _activeScreen = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 40),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: active ? Colors.redAccent : Colors.transparent,
                width: 3,
              ),
            ),
            gradient: active
                ? LinearGradient(
                    colors: [
                      Colors.redAccent.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? Colors.white : Colors.white24,
              ),
              const SizedBox(width: 25),
              Text(
                label,
                style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _systemHealthWidget() {
    return Padding(
      padding: const EdgeInsets.all(35.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM_PULSE',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white24,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$mentalBattery%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w100,
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: mentalBattery / 100,
            backgroundColor: Colors.white10,
            color: Colors.redAccent,
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  // --- SCREEN 0: AI DASHBOARD ---
  Widget _buildAIDashboard() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dashboardHeader(),
          const SizedBox(height: 60),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _aiInsightCard(
                      'BURNOUT_TRAJECTORY',
                      burnoutTrajectory,
                      Icons.warning_amber_rounded,
                      Colors.redAccent,
                    ),
                    const SizedBox(height: 30),
                    _aiInsightCard(
                      'AI_RECOMMENDATION_PROTOCOL',
                      aiRecommendation,
                      Icons.terminal_sharp,
                      Colors.redAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              Expanded(flex: 2, child: _neuralMetricsColumn()),
            ],
          ),
          const SizedBox(height: 50),
          _aiEfficiencyGrid(),
        ],
      ),
    );
  }

  Widget _dashboardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat(
                'EEEE, MMMM d, yyyy',
              ).format(DateTime.now()).toUpperCase(),
              style: const TextStyle(
                color: Colors.redAccent,
                letterSpacing: 3,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'AI_BURNOUT_PREDICTOR',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        _headerMetric('STABILITY_STREAK', '$pulseStreak DAYS'),
      ],
    );
  }

  Widget _headerMetric(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w100),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _aiInsightCard(String title, String body, IconData icon, Color acc) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: acc, size: 20),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: acc,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            body.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              height: 1.6,
              color: Colors.white,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _neuralMetricsColumn() {
    return Column(
      children: [
        _metricTile(
          'MENTAL_BATTERY',
          '$mentalBattery%',
          Icons.battery_charging_full,
        ),
        const SizedBox(height: 20),
        _metricTile('DECISION_DQI', decisionQuality, Icons.psychology_alt),
        const SizedBox(height: 20),
        _metricTile('FOCUS_HALF_LIFE', focusHalfLife, Icons.hourglass_bottom),
        const SizedBox(height: 20),
        _metricTile('ACTIVITY_LEVEL', neuralActivity, Icons.graphic_eq),
      ],
    );
  }

  Widget _metricTile(String label, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white24,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                val,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiEfficiencyGrid() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFF060606),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _gridStat('DAILY_YIELD', '$taskCompletion%'),
          _gridStat('FATIGUE_IDX', '$fatigueScore'),
          _gridStat(
            'RECOVERY_EST',
            recoveryEstimate.split(' ').first + ' MINS',
          ),
          _gridStat('PULSE_SYNC', 'ACTIVE'),
        ],
      ),
    );
  }

  Widget _gridStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.redAccent,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          val,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w100),
        ),
      ],
    );
  }

  // --- SCREEN 1: FOCUS ENGINE ---
  Widget _buildFocusEngine() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PULSE_DURATION_TIMER',
              style: TextStyle(
                color: Colors.redAccent,
                letterSpacing: 5,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 60),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 320,
                  width: 320,
                  child: CircularProgressIndicator(
                    value:
                        _pSeconds /
                        (_pBreak
                            ? (adaptivePomodoro['break_mins'] ?? 5) * 60
                            : (adaptivePomodoro['work_mins'] ?? 25) * 60),
                    strokeWidth: 2,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.redAccent,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formatTime(_pSeconds),
                      style: const TextStyle(
                        fontSize: 90,
                        fontWeight: FontWeight.w100,
                        letterSpacing: -5,
                      ),
                    ),
                    Text(
                      _pBreak ? 'RECOVERY_PROTOCOL' : 'EXECUTION_PROTOCOL',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 90,
                  icon: Icon(
                    _pRunning
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.redAccent,
                  ),
                  onPressed: _startStopPomodoro,
                ),
                const SizedBox(width: 40),
                IconButton(
                  iconSize: 90,
                  icon: const Icon(Icons.refresh, color: Colors.white12),
                  onPressed: () => setState(() {
                    _pRunning = false;
                    _pomodoroTimer?.cancel();
                    _pSeconds = (adaptivePomodoro['work_mins'] ?? 25) * 60;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'STATUS: ${adaptivePomodoro['status']?.toUpperCase() ?? "SYNCING..."}',
              style: const TextStyle(
                color: Colors.white24,
                letterSpacing: 2,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 2: HABIT MODULE ---
  Widget _buildHabitModule() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HABIT_SYNCHRONIZATION',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 50),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _moduleCard(
                  'HABIT_REGISTRY',
                  Column(
                    children: habitRegistry
                        .map(
                          (h) => _protocolListTile(
                            h['name'],
                            'RECURS_DAILY @ ${h['reminder']}',
                            _getIcon(h['icon']),
                            Color(int.parse(h['color'])),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: _moduleCard(
                  'DAILY_EXECUTION',
                  Column(
                    children: habitRegistry.map((h) {
                      bool done = habitLogs[h['id']] ?? false;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: Icon(
                          _getIcon(h['icon']),
                          color: done
                              ? Color(int.parse(h['color']))
                              : Colors.white24,
                        ),
                        title: Text(
                          h['name'].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                        trailing: Checkbox(
                          value: done,
                          activeColor: Colors.redAccent,
                          onChanged: (v) => _toggleHabit(h['id'], v!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SCREEN 3: TASK BUCKET ---
  Widget _buildTaskBucket() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TASK_BUCKET_ARRAY',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              _dateSelector(),
            ],
          ),
          const SizedBox(height: 50),
          _moduleCard(
            'OPERATION_CHRONOLOGY',
            Column(
              children: bucketTasks.isEmpty
                  ? [
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: Text(
                            'EMPTY_ARRAY',
                            style: TextStyle(
                              color: Colors.white12,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : bucketTasks.map((t) => _taskItemCard(t)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskItemCard(dynamic t) {
    bool done = t['completed'] ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.white.withOpacity(0.01),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: done ? Colors.redAccent.withOpacity(0.2) : Colors.white10,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: done,
          activeColor: Colors.redAccent,
          onChanged: (_) => _toggleTask(t['id']),
        ),
        title: Text(
          t['name'].toUpperCase(),
          style: TextStyle(
            letterSpacing: 1.5,
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? Colors.white24 : Colors.white,
          ),
        ),
        subtitle: Text(
          'Reminders: ${(t['reminders'] as List).join(", ")}',
          style: const TextStyle(fontSize: 10, color: Colors.white10),
        ),
      ),
    );
  }

  // --- SCREEN 4: NEURAL ANALYTICS ---
  Widget _buildNeuralAnalytics() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEURAL_PERFORMANCE_DIAGNOSTICS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 50),
          _moduleCard(
            'TEMPORAL_ENGAGEMENT_MAP',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COGNITIVE_LOAD_INTENSITY_GRID',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white24,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 140,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 4,
                        ),
                    itemCount: 28,
                    itemBuilder: (ctx, i) {
                      // Logic to simulate varied load intensities
                      double intensity = (i % 7 == 0)
                          ? 0.9
                          : (i % 3 == 0 ? 0.4 : (i % 2 == 0 ? 0.2 : 0.05));
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(intensity),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text(
                      'LOW_LOAD',
                      style: TextStyle(fontSize: 8, color: Colors.white12),
                    ),
                    const SizedBox(width: 10),
                    _intensityLegend(0.05),
                    _intensityLegend(0.2),
                    _intensityLegend(0.4),
                    _intensityLegend(0.9),
                    const SizedBox(width: 10),
                    const Text(
                      'CRITICAL_LOAD',
                      style: TextStyle(fontSize: 8, color: Colors.white12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _moduleCard(
                  'NEURAL_STABILITY_QUOTIENT',
                  Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: 8,
                                    color: Colors.redAccent,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: 5,
                                    color: Colors.redAccent,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 2,
                                barRods: [
                                  BarChartRodData(
                                    toY: 11,
                                    color: Colors.redAccent,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 3,
                                barRods: [
                                  BarChartRodData(
                                    toY: 7,
                                    color: Colors.redAccent,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 4,
                                barRods: [
                                  BarChartRodData(
                                    toY: 14,
                                    color: Colors.redAccent,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                            ],
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '5-DAY_TREND_ANALYSIS',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white24,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: _moduleCard(
                  'LOGIC_CONSISTENCY_ARCHIVE',
                  Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  const FlSpot(0, 32),
                                  const FlSpot(1, 45),
                                  const FlSpot(2, 40),
                                  const FlSpot(3, 50),
                                  const FlSpot(4, 38),
                                  const FlSpot(5, 55),
                                ],
                                isCurved: true,
                                color: Colors.redAccent,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.redAccent.withOpacity(0.05),
                                ),
                              ),
                            ],
                            titlesData: const FlTitlesData(show: false),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'SYSTOLIC_MEMORY_LOG',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white24,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _intensityLegend(double op) => Container(
    width: 12,
    height: 12,
    margin: const EdgeInsets.only(right: 5),
    decoration: BoxDecoration(
      color: Colors.redAccent.withOpacity(op),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  // --- COMMON HELPERS ---

  Widget _moduleCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: const Color(0xFF070707),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white24,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          child,
        ],
      ),
    );
  }

  Widget _protocolListTile(
    String title,
    String subtitle,
    IconData icon,
    Color acc,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(icon, color: acc, size: 20),
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 1,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 9, color: Colors.white24),
      ),
      trailing: const Icon(Icons.arrow_right_alt, color: Colors.white10),
    );
  }

  Widget _dateSelector() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _calendarDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) {
          _calendarDate = d;
          _syncModules();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: Colors.white12)),
        child: Row(
          children: [
            Text(DateFormat('yyyy-MM-dd').format(_calendarDate)),
            const SizedBox(width: 15),
            const Icon(Icons.calendar_month, size: 16),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String n) {
    if (n == 'code') return Icons.code;
    if (n == 'water_drop') return Icons.water_drop;
    if (n == 'self_improvement') return Icons.self_improvement;
    return Icons.circle;
  }

  String _formatTime(int s) {
    int m = s ~/ 60;
    int ss = s % 60;
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }
}
