import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IronmanApp());
}

class IronmanApp extends StatelessWidget {
  const IronmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ironman 70.3 Napló',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
        useMaterial3: true,
      ),
      home: const WorkoutHomeScreen(),
    );
  }
}

class WorkoutItem {
  final int index;
  final int week;
  final String day;
  final String sport;
  final double planTime;
  final double planDist;
  final String zone;
  final String desc;

  double actSwim;
  String swimPace;
  double actBike;
  double bikeSpeed;
  double actRun;
  String runPace;
  double actTotal;
  int hr;
  String notes;

  WorkoutItem({
    required this.index,
    required this.week,
    required this.day,
    required this.sport,
    required this.planTime,
    required this.planDist,
    required this.zone,
    required this.desc,
    this.actSwim = 0.0,
    this.swimPace = '',
    this.actBike = 0.0,
    this.bikeSpeed = 0.0,
    this.actRun = 0.0,
    this.runPace = '',
    this.actTotal = 0.0,
    this.hr = 0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'actSwim': actSwim,
      'swimPace': swimPace,
      'actBike': actBike,
      'bikeSpeed': bikeSpeed,
      'actRun': actRun,
      'runPace': runPace,
      'actTotal': actTotal,
      'hr': hr,
      'notes': notes,
    };
  }

  void updateFromMap(Map<String, dynamic> map) {
    actSwim = (map['actSwim'] as num?)?.toDouble() ?? 0.0;
    swimPace = map['swimPace'] ?? '';
    actBike = (map['actBike'] as num?)?.toDouble() ?? 0.0;
    bikeSpeed = (map['bikeSpeed'] as num?)?.toDouble() ?? 0.0;
    actRun = (map['actRun'] as num?)?.toDouble() ?? 0.0;
    runPace = map['runPace'] ?? '';
    actTotal = (map['actTotal'] as num?)?.toDouble() ?? (actSwim + actBike + actRun);
    hr = (map['hr'] as num?)?.toInt() ?? 0;
    notes = map['notes'] ?? '';
  }
}

class WorkoutHomeScreen extends StatefulWidget {
  const WorkoutHomeScreen({super.key});

  @override
  State<WorkoutHomeScreen> createState() => _WorkoutHomeScreenState();
}

class _WorkoutHomeScreenState extends State<WorkoutHomeScreen> {
  List<WorkoutItem> workouts = [];
  bool isLoading = true;
  int currentWeek = 3;
  int selectedWeek = 3;
  int todayIndex = 16;

  final DateTime startDate = DateTime(2026, 10, 5);

  final List<String> blockFocus = [
    "Aerob bázis, úszástechnika & görgő hozzászokás (Térdkímélő sík futások)",
    "Állóképesség növelése, SweetSpot blokkok & törzserő",
    "Téli volumenépítés, növekvő görgő- és futótávok",
    "Téli csúcs + Thaiföldi 2 hetes edzőtábor jellegű blokk (úszás & futás)",
    "Tavaszi nyitás: kinti 70-75km bringák & első téglaedzések",
    "1. Féltáv specifikus építés: 80-90km bringák & hosszú téglák",
    "Tapering + 1. FÉLTÁV VERSENY (Május vége/Júni eleje - Barátkozós!) + Regeneráció",
    "Fűzfőre hangolás 1.: Emelt intenzitás (Z3/SweetSpot versenytempó blokkok)",
    "Fűzfőre hangolás 2.: Csúcsterhelés & versenyszimulációs erős téglák (95km / 72km)",
    "Tapering + 2. FÉLTÁV VERSENY: BALATONFŰZFŐ (Szept. eleje - MEGNYOMÓS!) + Levezetés"
  ];

  @override
  void initState() {
    super.initState();
    _calculateToday();
    _loadInitialData();
  }

  void _calculateToday() {
    final now = DateTime.now();
    final diff = now.difference(startDate).inDays;
    todayIndex = diff.clamp(0, 349);
    currentWeek = (todayIndex ~/ 7) + 1;
    selectedWeek = currentWeek;
  }

  Future<void> _loadInitialData() async {
    try {
      final csvString = await rootBundle.loadString('assets/edzesterv_adatbazis.csv');
      final lines = csvString.split('\n');
      final List<WorkoutItem> items = [];

      int idx = 0;
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(';');
        if (parts.length >= 7) {
          items.add(WorkoutItem(
            index: idx++,
            week: int.tryParse(parts[0]) ?? 0,
            day: parts[1],
            sport: parts[2],
            planTime: double.tryParse(parts[3]) ?? 0,
            planDist: double.tryParse(parts[4]) ?? 0,
            zone: parts[5],
            desc: parts[6],
            actSwim: parts.length > 7 ? (double.tryParse(parts[7]) ?? 0.0) : 0.0,
            actBike: parts.length > 8 ? (double.tryParse(parts[8]) ?? 0.0) : 0.0,
            actRun: parts.length > 9 ? (double.tryParse(parts[9]) ?? 0.0) : 0.0,
            actTotal: parts.length > 10 ? (double.tryParse(parts[10]) ?? 0.0) : 0.0,
            hr: parts.length > 11 ? (int.tryParse(parts[11]) ?? 0) : 0,
            swimPace: parts.length > 12 ? parts[12] : '',
            bikeSpeed: parts.length > 13 ? (double.tryParse(parts[13]) ?? 0.0) : 0.0,
            runPace: parts.length > 14 ? parts[14] : '',
            notes: parts.length > 15 ? parts[15] : '',
          ));
        }
      }

      final prefs = await SharedPreferences.getInstance();
      for (var w in items) {
        final saved = prefs.getString('w_${w.index}');
        if (saved != null) {
          w.updateFromMap(jsonDecode(saved));
        }
      }

      setState(() {
        workouts = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveWorkout(WorkoutItem w) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('w_${w.index}', jsonEncode(w.toMap()));
    setState(() {});
  }

  int _paceToSeconds(String pace) {
    if (pace.isEmpty || pace == '-') return 0;
    final parts = pace.split(':');
    try {
      if (parts.length == 3) {
        return int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
      } else if (parts.length == 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (_) {}
    return 0;
  }

  String _secondsToPace(double avgSec) {
    if (avgSec <= 0) return '-';
    final total = avgSec.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showBlockStats() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              const Text('5 Hetes Periodizációs Blokkok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: 10,
                  itemBuilder: (ctx, b) {
                    final startW = b * 5 + 1;
                    final endW = (b + 1) * 5;

                    double planMin = 0;
                    double planKm = 0;
                    double swimKm = 0;
                    double bikeKm = 0;
                    double runKm = 0;

                    int swimSecSum = 0;
                    int swimCnt = 0;
                    int swimHrSum = 0;
                    int swimHrCnt = 0;

                    double bikeSpdSum = 0;
                    int bikeCnt = 0;
                    int bikeHrSum = 0;
                    int bikeHrCnt = 0;

                    int runSecSum = 0;
                    int runCnt = 0;
                    int runHrSum = 0;
                    int runHrCnt = 0;

                    int totalHrSum = 0;
                    int totalHrCnt = 0;

                    for (var w in workouts) {
                      if (w.week >= startW && w.week <= endW) {
                        planMin += w.planTime;
                        planKm += w.planDist;
                        swimKm += w.actSwim;
                        bikeKm += w.actBike;
                        runKm += w.actRun;

                        if (w.hr > 0) {
                          totalHrSum += w.hr;
                          totalHrCnt++;
                        }

                        final sSec = _paceToSeconds(w.swimPace);
                        if (w.actSwim > 0) {
                          if (sSec > 0) {
                            swimSecSum += sSec;
                            swimCnt++;
                          }
                          if (w.hr > 0) {
                            swimHrSum += w.hr;
                            swimHrCnt++;
                          }
                        }

                        if (w.actBike > 0) {
                          if (w.bikeSpeed > 0) {
                            bikeSpdSum += w.bikeSpeed;
                            bikeCnt++;
                          }
                          if (w.hr > 0) {
                            bikeHrSum += w.hr;
                            bikeHrCnt++;
                          }
                        }

                        if (w.actRun > 0) {
                          final rSec = _paceToSeconds(w.runPace);
                          if (rSec > 0) {
                            runSecSum += rSec;
                            runCnt++;
                          }
                          if (w.hr > 0) {
                            runHrSum += w.hr;
                            runHrCnt++;
                          }
                        }
                      }
                    }

                    final actKm = swimKm + bikeKm + runKm;
                    final pct = planKm > 0 ? (actKm / planKm * 100) : 0;
                    final avgBlockHr = totalHrCnt > 0 ? (totalHrSum / totalHrCnt).toStringAsFixed(1) : '-';

                    final swimPaceStr = swimCnt > 0 ? _secondsToPace(swimSecSum / swimCnt) : '-';
                    final swimHrStr = swimHrCnt > 0 ? '${(swimHrSum / swimHrCnt).round()} bpm' : '-';

                    final bikeSpdStr = bikeCnt > 0 ? '${(bikeSpdSum / bikeCnt).toStringAsFixed(1)} km/h' : '-';
                    final bikeHrStr = bikeHrCnt > 0 ? '${(bikeHrSum / bikeHrCnt).round()} bpm' : '-';

                    final runPaceStr = runCnt > 0 ? _secondsToPace(runSecSum / runCnt) : '-';
                    final runHrStr = runHrCnt > 0 ? '${(runHrSum / runHrCnt).round()} bpm' : '-';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${b + 1}. Blokk ($startW–$endW. hét)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: pct >= 80 ? Colors.green[100] : (pct > 0 ? Colors.orange[100] : Colors.grey[200]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${pct.toStringAsFixed(1)}%',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: pct >= 80 ? Colors.green[800] : (pct > 0 ? Colors.orange[900] : Colors.grey[700])),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(blockFocus[b], style: TextStyle(fontSize: 12, color: Colors.blueGrey[800], fontStyle: FontStyle.italic)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Terv: ${planKm.toStringAsFixed(1)} km (${(planMin / 60).toStringAsFixed(1)} óra)', style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                                Text('Mért: ${actKm.toStringAsFixed(2)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('❤️ Blokk átlagpulzus: $avgBlockHr bpm', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC62828))),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('🏊 ÚSZÁS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    const SizedBox(height: 2),
                                    Text('${swimKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('⏱ $swimPaceStr', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                    Text('❤️ $swimHrStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('🚴 BRINGA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                                    const SizedBox(height: 2),
                                    Text('${bikeKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('⚡ $bikeSpdStr', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                    Text('❤️ $bikeHrStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('🏃 FUTÁS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                    const SizedBox(height: 2),
                                    Text('${runKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('⏱ $runPaceStr', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                    Text('❤️ $runHrStr', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStats() {
    double planMin = 0;
    double planKm = 0;
    double actKm = 0;
    double swimKm = 0;
    double bikeKm = 0;
    double runKm = 0;
    int hrSum = 0;
    int hrCnt = 0;

    for (var w in workouts) {
      planMin += w.planTime;
      planKm += w.planDist;
      actKm += w.actTotal;
      swimKm += w.actSwim;
      bikeKm += w.actBike;
      runKm += w.actRun;
      if (w.hr > 0) {
        hrSum += w.hr;
        hrCnt++;
      }
    }

    final pct = planKm > 0 ? (actKm / planKm * 100) : 0;
    final avgHr = hrCnt > 0 ? (hrSum / hrCnt).toStringAsFixed(1) : '-';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Globális Összesítő', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Összes tervezett idő: ${planMin.toInt()} perc (${(planMin / 60).toStringAsFixed(1)} óra)'),
            Text('• Átlagos heti edzésidő: ${(planMin / 60 / 50).toStringAsFixed(1)} óra / hét'),
            Text('• Összes tervezett táv: ${planKm.toStringAsFixed(1)} km'),
            const Divider(height: 20),
            Text('• Összes teljesített táv: ${actKm.toStringAsFixed(2)} km (${pct.toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            const SizedBox(height: 4),
            Text('  - 🏊 Úszás: ${swimKm.toStringAsFixed(2)} km'),
            Text('  - 🚴 Bringa / Görgő: ${bikeKm.toStringAsFixed(2)} km'),
            Text('  - 🏃 Futás: ${runKm.toStringAsFixed(2)} km'),
            const Divider(height: 20),
            Text('❤️ Átlagos mért pulzus: $avgHr bpm ($hrCnt edzés alapján)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Rendben'))],
      ),
    );
  }

  void _showEditSheet(WorkoutItem w) {
    final sport = w.sport.toLowerCase();
    final isSwim = sport.contains('úszás') || sport.contains('tégla');
    final isBike = sport.contains('bringa') || sport.contains('görgő') || sport.contains('kerékpár') || sport.contains('tégla');
    final isRun = sport.contains('futás') || sport.contains('tégla');

    final swimDistCtrl = TextEditingController(text: w.actSwim > 0 ? w.actSwim.toString() : '');
    final swimPaceCtrl = TextEditingController(text: w.swimPace);
    final bikeDistCtrl = TextEditingController(text: w.actBike > 0 ? w.actBike.toString() : '');
    final bikeSpeedCtrl = TextEditingController(text: w.bikeSpeed > 0 ? w.bikeSpeed.toString() : '');
    final runDistCtrl = TextEditingController(text: w.actRun > 0 ? w.actRun.toString() : '');
    final runPaceCtrl = TextEditingController(text: w.runPace);
    final hrCtrl = TextEditingController(text: w.hr > 0 ? w.hr.toString() : '');
    final notesCtrl = TextEditingController(text: w.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${w.week}. hét, ${w.day} - ${w.sport}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(w.desc, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic)),
              const Divider(height: 25),
              if (isSwim) ...[
                Row(
                  children: [
                    Expanded(child: TextField(controller: swimDistCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Úszás (km)', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: swimPaceCtrl, decoration: const InputDecoration(labelText: 'Tempó (mm:ss)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (isBike) ...[
                Row(
                  children: [
                    Expanded(child: TextField(controller: bikeDistCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Kerékpár (km)', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: bikeSpeedCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Sebesség (km/h)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (isRun) ...[
                Row(
                  children: [
                    Expanded(child: TextField(controller: runDistCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Futás (km)', border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: runPaceCtrl, decoration: const InputDecoration(labelText: 'Tempó (mm:ss)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(child: TextField(controller: hrCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Átlagpulzus (bpm)', border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'RPE / Megjegyzés', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                  icon: const Icon(Icons.check),
                  label: const Text('MENTÉS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () {
                    w.actSwim = double.tryParse(swimDistCtrl.text.replaceAll(',', '.')) ?? 0.0;
                    w.swimPace = swimPaceCtrl.text;
                    w.actBike = double.tryParse(bikeDistCtrl.text.replaceAll(',', '.')) ?? 0.0;
                    w.bikeSpeed = double.tryParse(bikeSpeedCtrl.text.replaceAll(',', '.')) ?? 0.0;
                    w.actRun = double.tryParse(runDistCtrl.text.replaceAll(',', '.')) ?? 0.0;
                    w.runPace = runPaceCtrl.text;
                    w.actTotal = double.parse((w.actSwim + w.actBike + w.actRun).toStringAsFixed(2));
                    w.hr = int.tryParse(hrCtrl.text) ?? 0;
                    w.notes = notesCtrl.text;

                    _saveWorkout(w);
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final weekWorkouts = workouts.where((w) => w.week == selectedWeek).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ironman 70.3 Fűzfő', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
            tooltip: '5 hetes blokkok',
            onPressed: _showBlockStats,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            tooltip: 'Globális statisztika',
            onPressed: _showStats,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: selectedWeek > 1 ? () => setState(() => selectedWeek--) : null,
                ),
                Text('$selectedWeek. Hét', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: selectedWeek < 50 ? () => setState(() => selectedWeek++) : null,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF455A64), foregroundColor: Colors.white),
                  icon: const Icon(Icons.today, size: 16),
                  label: const Text('MAI HÉT'),
                  onPressed: () => setState(() => selectedWeek = currentWeek),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: weekWorkouts.length,
              itemBuilder: (ctx, i) {
                final w = weekWorkouts[i];
                final isCompleted = w.actTotal > 0 || w.sport == 'Pihenő';
                final isToday = w.index == todayIndex;
                final isMissed = !isCompleted && w.index < todayIndex;

                Color cardColor = Colors.white;
                if (isCompleted) {
                  cardColor = const Color(0xFFD4EDDA);
                } else if (isToday) {
                  cardColor = const Color(0xFFFFCDD2);
                } else if (isMissed) {
                  cardColor = const Color(0xFFFFF3CD);
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: cardColor,
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${w.day} • ${w.sport}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red[800], borderRadius: BorderRadius.circular(10)),
                            child: const Text('MAI NAP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else if (isCompleted)
                          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(w.desc, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        Text('Terv: ${w.planDist} km (${w.planTime.toInt()}p) [${w.zone}]', style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w600)),
                        if (w.actTotal > 0 || w.hr > 0 || w.notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(6)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Mért össztáv: ${w.actTotal} km', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 13)),
                                    const Spacer(),
                                    if (w.hr > 0)
                                      Text('❤️ ${w.hr} bpm', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC62828), fontSize: 13)),
                                  ],
                                ),
                                if (w.actSwim > 0 || w.actBike > 0 || w.actRun > 0) ...[
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (w.actSwim > 0) Text('🏊 ${w.actSwim}km (${w.swimPace})', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                                      if (w.actBike > 0) Text('🚴 ${w.actBike}km (${w.bikeSpeed}km/h)', style: const TextStyle(fontSize: 11, color: Colors.orange)),
                                      if (w.actRun > 0) Text('🏃 ${w.actRun}km (${w.runPace})', style: const TextStyle(fontSize: 11, color: Colors.green)),
                                    ],
                                  ),
                                ],
                                if (w.notes.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text('💬 ${w.notes}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[800])),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => _showEditSheet(w),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegend(const Color(0xFF2E7D32), 'Kész'),
                _buildLegend(const Color(0xFFD32F2F), 'Ma'),
                _buildLegend(const Color(0xFFF57F17), 'Kihagyott'),
                _buildLegend(Colors.grey, 'Jövőbeli'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
