import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
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

  // 3. Pont: Okos edzésfunkciók mezői
  int carbsConsumed; // gramm szénhidrát
  String stomachFeel; // Gyomorérzet (pl. 5/5 Kiváló, Enyhe puffadás)
  String gearUsed; // Használt felszerelés megjegyzés (pl. Versenycipő, Neoprén)

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
    this.carbsConsumed = 0,
    this.stomachFeel = '',
    this.gearUsed = '',
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
      'carbsConsumed': carbsConsumed,
      'stomachFeel': stomachFeel,
      'gearUsed': gearUsed,
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
    carbsConsumed = (map['carbsConsumed'] as num?)?.toInt() ?? 0;
    stomachFeel = map['stomachFeel'] ?? '';
    gearUsed = map['gearUsed'] ?? '';
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
  final DateTime race1Date = DateTime(2027, 5, 30); // 34. hét vasárnap: 1. Féltáv
  final DateTime race2Date = DateTime(2027, 9, 5);  // 48. hét vasárnap: Balatonfűzfő

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

  void _showChartsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChartsScreen(workouts: workouts, currentWeek: currentWeek, selectedWeek: selectedWeek),
      ),
    );
  }

  void _showGearTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GearTrackerScreen(workouts: workouts),
      ),
    );
  }

  void _showNutritionCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const NutritionCalculatorSheet(),
    );
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
    final carbsCtrl = TextEditingController(text: w.carbsConsumed > 0 ? w.carbsConsumed.toString() : '');
    final stomachCtrl = TextEditingController(text: w.stomachFeel);

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
              const SizedBox(height: 12),
              // 3. Pont: Frissítés naplózása
              Row(
                children: [
                  Expanded(child: TextField(controller: carbsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Elfogyasztott CH (g)', prefixIcon: Icon(Icons.bolt, color: Colors.amber), border: OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: stomachCtrl, decoration: const InputDecoration(labelText: 'Gyomorérzet (pl. 5/5 jó)', prefixIcon: Icon(Icons.sentiment_satisfied_alt), border: OutlineInputBorder()))),
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
                    w.carbsConsumed = int.tryParse(carbsCtrl.text) ?? 0;
                    w.stomachFeel = stomachCtrl.text;

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

  // --------------------------------------------------------------------------
  // 3. PONT: VERSENY VISSZASZÁMLÁLÓ KÁRTYA
  // --------------------------------------------------------------------------
  Widget _buildRaceCountdownCard() {
    final now = DateTime.now();
    final daysToRace1 = race1Date.difference(now).inDays;
    final weeksToRace1 = (daysToRace1 / 7).ceil();

    final daysToRace2 = race2Date.difference(now).inDays;
    final weeksToRace2 = (daysToRace2 / 7).ceil();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF37474F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 6),
              const Text('VERSENYEK VISSZASZÁMLÁLÓJA', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const Spacer(),
              Text('Ma: 2026. okt. 21. ($currentWeek. hét)', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 1. Féltáv
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. FÉLTÁV (Május 30.)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text('$daysToRace1 nap', style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('$weeksToRace1 hét hátralévő felkészülés', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Balatonfűzfő 70.3 Főverseny
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FŰZFŐ 70.3 (Szept 5.)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text('$daysToRace2 nap', style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('$weeksToRace2 hét hátralévő felkészülés', style: const TextStyle(color: Colors.white70, fontSize: 10)),
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
            icon: const Icon(Icons.bolt_rounded, color: Colors.amber),
            tooltip: 'Frissítés Kalkulátor',
            onPressed: _showNutritionCalculator,
          ),
          IconButton(
            icon: const Icon(Icons.construction_rounded, color: Colors.white),
            tooltip: 'Felszerelés & Eszköztár',
            onPressed: _showGearTracker,
          ),
          IconButton(
            icon: const Icon(Icons.show_chart_rounded, color: Colors.white),
            tooltip: 'Grafikonok és Diagramok',
            onPressed: _showChartsScreen,
          ),
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
          // 3. PONT: VERSENY VISSZASZÁMLÁLÓ
          _buildRaceCountdownCard(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        if (w.actTotal > 0 || w.hr > 0 || w.notes.isNotEmpty || w.carbsConsumed > 0) ...[
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
                                if (w.carbsConsumed > 0 || w.stomachFeel.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (w.carbsConsumed > 0)
                                        Text('⚡ Frissítés: ${w.carbsConsumed}g CH ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                      if (w.stomachFeel.isNotEmpty)
                                        Text('(${w.stomachFeel})', style: TextStyle(fontSize: 11, color: Colors.grey[800])),
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

// ============================================================================
// 3. PONT: SZÉNHIDRÁT & FRISSÍTÉS KALKULÁTOR
// ============================================================================
class NutritionCalculatorSheet extends StatefulWidget {
  const NutritionCalculatorSheet({super.key});

  @override
  State<NutritionCalculatorSheet> createState() => _NutritionCalculatorSheetState();
}

class _NutritionCalculatorSheetState extends State<NutritionCalculatorSheet> {
  double hours = 2.5; // alapértelmezett 2.5 óra
  int carbTargetPerHour = 60; // 60g / óra

  @override
  Widget build(BuildContext context) {
    final totalCarbs = (hours * carbTargetPerHour).round();
    final totalFluidMl = (hours * 600).round(); // ~600 ml / óra folyadék
    final gelCount = (totalCarbs / 25).toStringAsFixed(1); // 1 zselé ~25g CH

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                const Text('Szénhidrát & Frissítés Tervező', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Kalkuláld ki a szükséges energiát és folyadékot a hosszú edzésekhez és versenyekhez.', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tervezett időtartam:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${hours.toStringAsFixed(1)} óra (${(hours * 60).round()} perc)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            Slider(
              value: hours,
              min: 0.5,
              max: 6.0,
              divisions: 11,
              label: '${hours.toStringAsFixed(1)} óra',
              onChanged: (v) => setState(() => hours = v),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cél CH bevitel / óra:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$carbTargetPerHour g CH / óra', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 40, label: Text('40g (Z1/Z2)')),
                ButtonSegment(value: 60, label: Text('60g (Bázis)')),
                ButtonSegment(value: 75, label: Text('75g (Féltáv)')),
                ButtonSegment(value: 90, label: Text('90g (Profi)')),
              ],
              selected: {carbTargetPerHour},
              onSelectionChanged: (val) => setState(() => carbTargetPerHour = val.first),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SZÜKSÉGES FRISSÍTÉS ÖSSZESEN:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('⚡ Szénhidrát', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
                            Text('$totalCarbs g', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('💧 Folyadék', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                            Text('$totalFluidMl ml', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('🥤 Zselé (~25g)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                            Text('$gelCount db', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      '💡 Praktikus recept: $totalFluidMl ml izotóniás ital (kulacsokban) + ${(totalCarbs / 30).ceil()} db zselé vagy energiaszelet 20-30 percenként elosztva.',
                      style: TextStyle(fontSize: 12, color: Colors.brown[800]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF455A64), foregroundColor: Colors.white),
                child: const Text('BEZÁRÁS'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. PONT: FELSZERELÉS- ÉS ESZKÖZKÖVETŐ (GEAR TRACKER)
// ============================================================================
class GearTrackerScreen extends StatefulWidget {
  final List<WorkoutItem> workouts;

  const GearTrackerScreen({super.key, required this.workouts});

  @override
  State<GearTrackerScreen> createState() => _GearTrackerScreenState();
}

class _GearTrackerScreenState extends State<GearTrackerScreen> {
  double shoeLimit = 800; // km
  double chainLimit = 3000; // km
  double tireLimit = 4000; // km

  double customShoeOffset = 0;
  double customChainOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadGearOffsets();
  }

  Future<void> _loadGearOffsets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      customShoeOffset = prefs.getDouble('gear_shoe_offset') ?? 0;
      customChainOffset = prefs.getDouble('gear_chain_offset') ?? 0;
    });
  }

  Future<void> _resetShoe() async {
    final prefs = await SharedPreferences.getInstance();
    double totalRun = widget.workouts.fold(0.0, (sum, w) => sum + w.actRun);
    await prefs.setDouble('gear_shoe_offset', totalRun);
    setState(() => customShoeOffset = totalRun);
  }

  Future<void> _resetChain() async {
    final prefs = await SharedPreferences.getInstance();
    double totalBike = widget.workouts.fold(0.0, (sum, w) => sum + w.actBike);
    await prefs.setDouble('gear_chain_offset', totalBike);
    setState(() => customChainOffset = totalBike);
  }

  @override
  Widget build(BuildContext context) {
    double totalRun = widget.workouts.fold(0.0, (sum, w) => sum + w.actRun);
    double totalBike = widget.workouts.fold(0.0, (sum, w) => sum + w.actBike);
    int swimCount = widget.workouts.where((w) => w.actSwim > 0).length;

    double activeShoeKm = (totalRun - customShoeOffset).clamp(0, 99999);
    double activeChainKm = (totalBike - customChainOffset).clamp(0, 99999);

    double shoePct = (activeShoeKm / shoeLimit).clamp(0.0, 1.0);
    double chainPct = (activeChainKm / chainLimit).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Felszerelés & Eszköztár', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Eszközök & Alkatrészek Állapota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Kövesd nyomon futócipőid, kerékpárláncod és felszereléseid amortizációját.', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const SizedBox(height: 16),

            // 1. Futócipő kártya
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_run, color: Colors.green, size: 26),
                        const SizedBox(width: 8),
                        const Text('Elsődleges Futócipő', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _confirmReset(context, 'Új futócipő használatba vétele (kilométerek lenullázása)', _resetShoe),
                          child: const Text('Új cipő / Reset', style: TextStyle(fontSize: 12, color: Colors.blue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${activeShoeKm.toStringAsFixed(1)} km lefutva', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Ajánlott csere: ${shoeLimit.toInt()} km', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: shoePct,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(shoePct >= 0.9 ? Colors.red : (shoePct >= 0.75 ? Colors.orange : Colors.green)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shoePct >= 0.9 ? '⚠️ A cipő amortizációja a végéhez közeledik, érdemes cserélni a térdízületek védelmében!' : 'Állapot: Jó párnázás (${(shoePct * 100).toStringAsFixed(0)}% elhasználódás)',
                      style: TextStyle(fontSize: 12, color: shoePct >= 0.9 ? Colors.red[800] : Colors.grey[800], fontWeight: shoePct >= 0.9 ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. Kerékpárlánc & Gumik
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bike, color: Colors.orange, size: 26),
                        const SizedBox(width: 8),
                        const Text('Kerékpárlánc & Hajtás', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _confirmReset(context, 'Új lánc feltétele (kilométerek lenullázása)', _resetChain),
                          child: const Text('Új lánc / Reset', style: TextStyle(fontSize: 12, color: Colors.blue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${activeChainKm.toStringAsFixed(1)} km letekerve', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Ajánlott ellenőrzés: ${chainLimit.toInt()} km', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: chainPct,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(chainPct >= 0.9 ? Colors.red : (chainPct >= 0.75 ? Colors.orange : Colors.green)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chainPct >= 0.9 ? '⚠️ Érdemes láncnyúlást mérni a fogaskoszorú megóvása érdekében!' : 'Lánc állapot: Megfelelő (${(chainPct * 100).toStringAsFixed(0)}% használat)',
                      style: TextStyle(fontSize: 12, color: chainPct >= 0.9 ? Colors.red[800] : Colors.grey[800], fontWeight: chainPct >= 0.9 ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Neoprén & Úszófelszerelés
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.pool, color: Colors.blue, size: 26),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Úszóedzések & Neoprén', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text('$swimCount rögzített úszóedzés a tervben', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        const SizedBox(height: 3),
                        const Text('Neoprén tesztek ajánlottak a 21. héttől!', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext ctx, String msg, VoidCallback onConfirm) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Megerősítés'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mégse')),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text('Nullázás'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. PONT: VIZUÁLIS GRAFIKONOK ÉS DIAGRAMOK KÉPERNYŐ
// ============================================================================
class ChartsScreen extends StatefulWidget {
  final List<WorkoutItem> workouts;
  final int currentWeek;
  final int selectedWeek;

  const ChartsScreen({
    super.key,
    required this.workouts,
    required this.currentWeek,
    required this.selectedWeek,
  });

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edzéselemzés & Grafikonok', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Volumen'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Sportágak'),
            Tab(icon: Icon(Icons.trending_up), text: 'Pulzus / Tempó'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVolumeChartTab(),
          _buildSportDistributionTab(),
          _buildHeartRateTrendTab(),
        ],
      ),
    );
  }

  bool _showHours = false;

  Widget _buildVolumeChartTab() {
    final List<Map<String, double>> weekData = [];
    double maxVal = 10.0;

    for (int w = 1; w <= 50; w++) {
      double plan = 0;
      double act = 0;
      for (var item in widget.workouts) {
        if (item.week == w) {
          plan += _showHours ? (item.planTime / 60) : item.planDist;
          act += _showHours ? (item.planTime > 0 && item.actTotal > 0 ? (item.planTime / 60) : 0) : item.actTotal;
        }
      }
      weekData.add({'plan': plan, 'act': act});
      if (plan > maxVal) maxVal = plan;
      if (act > maxVal) maxVal = act;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Heti Edzésmennyiség', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Táv (km)')),
                  ButtonSegment(value: true, label: Text('Idő (h)')),
                ],
                selected: {_showHours},
                onSelectionChanged: (val) => setState(() => _showHours = val.first),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kék: Tervezett előírás • Zöld: Ténylegesen teljesített\n(Két ujjal görgethető az 50 hét során)',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: CustomPaint(
                    size: Size(50 * 36.0 + 40, 260),
                    painter: WeeklyBarChartPainter(
                      weekData: weekData,
                      maxVal: maxVal,
                      currentWeek: widget.currentWeek,
                      unit: _showHours ? 'h' : 'km',
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blueGrey[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueGrey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tipp: A 4., 8., 12., 16., 20., 24., 28., 35., 39., 43. hetek a regenerációs hetek a periodizációban, ahol a volumen visszaesik a szuperkompenzációhoz.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey[900]),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  int _distScope = 0;

  Widget _buildSportDistributionTab() {
    double swim = 0, bike = 0, run = 0;

    int currentBlock = ((widget.currentWeek - 1) ~/ 5);
    int startW = currentBlock * 5 + 1;
    int endW = (currentBlock + 1) * 5;

    for (var w in widget.workouts) {
      bool include = false;
      if (_distScope == 0 && w.week == widget.selectedWeek) include = true;
      if (_distScope == 1 && w.week >= startW && w.week <= endW) include = true;
      if (_distScope == 2) include = true;

      if (include) {
        swim += w.actSwim;
        bike += w.actBike;
        run += w.actRun;
      }
    }

    final total = swim + bike + run;
    final swimPct = total > 0 ? (swim / total * 100) : 0;
    final bikePct = total > 0 ? (bike / total * 100) : 0;
    final runPct = total > 0 ? (run / total * 100) : 0;

    String scopeTitle = '${widget.selectedWeek}. Hét sportági aránya';
    if (_distScope == 1) scopeTitle = '${currentBlock + 1}. Blokk ($startW–$endW. hét) megoszlása';
    if (_distScope == 2) scopeTitle = 'Teljes eddigi szezon megoszlása';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sportági Megoszlás & Arányok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text('${widget.selectedWeek}. hét')),
              ButtonSegment(value: 1, label: Text('${currentBlock + 1}. blokk')),
              const ButtonSegment(value: 2, label: Text('Összesen')),
            ],
            selected: {_distScope},
            onSelectionChanged: (val) => setState(() => _distScope = val.first),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(scopeTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: CustomPaint(
                      painter: PieChartPainter(
                        swimPct: swimPct.toDouble(),
                        bikePct: bikePct.toDouble(),
                        runPct: runPct.toDouble(),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Összes mért', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('${total.toStringAsFixed(1)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const Text('km', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildSportRow(Icons.pool, 'Úszás', swim, swimPct.toDouble(), Colors.blue),
                  const Divider(),
                  _buildSportRow(Icons.directions_bike, 'Kerékpár / Görgő', bike, bikePct.toDouble(), Colors.orange),
                  const Divider(),
                  _buildSportRow(Icons.directions_run, 'Futás', run, runPct.toDouble(), Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportRow(IconData icon, String name, double km, double pct, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const Spacer(),
        Text('${km.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 8),
        Container(
          width: 55,
          alignment: Alignment.centerRight,
          child: Text('${pct.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  int _trendSport = 0;

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

  Widget _buildHeartRateTrendTab() {
    final List<Map<String, dynamic>> points = [];

    for (var w in widget.workouts) {
      if (w.hr > 0) {
        if (_trendSport == 0 && w.actRun > 0 && w.runPace.isNotEmpty) {
          final s = _paceToSeconds(w.runPace);
          if (s > 0) {
            points.add({
              'label': '${w.week}.h ${w.day.substring(0, 2)}',
              'hr': w.hr.toDouble(),
              'speed': (1000 / s) * 3.6,
              'detail': '${w.runPace} min/km | ${w.hr} bpm',
            });
          }
        } else if (_trendSport == 1 && w.actBike > 0 && w.bikeSpeed > 0) {
          points.add({
            'label': '${w.week}.h ${w.day.substring(0, 2)}',
            'hr': w.hr.toDouble(),
            'speed': w.bikeSpeed,
            'detail': '${w.bikeSpeed} km/h | ${w.hr} bpm',
          });
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aerob Hatékonyság', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Futás')),
                  ButtonSegment(value: 1, label: Text('Bringa')),
                ],
                selected: {_trendSport},
                onSelectionChanged: (val) => setState(() => _trendSport = val.first),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _trendSport == 0
                ? 'Futótempó és Mért Pulzus alakulása az edzések során'
                : 'Kerékpár Sebesség és Mért Pulzus alakulása az edzések során',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Még nincs elég pulzussal rögzített ${_trendSport == 0 ? "futás" : "kerékpározás"} az adatbázisban.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else ...[
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            Container(width: 12, height: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            const Text('Pulzus (bpm)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(width: 12, height: 12, color: _trendSport == 0 ? Colors.green : Colors.orange),
                            const SizedBox(width: 4),
                            Text(_trendSport == 0 ? 'Tempó / Sebesség' : 'Sebesség (km/h)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: CustomPaint(
                          size: Size(math.max(points.length * 45.0, 300.0), 220),
                          painter: TrendLineChartPainter(points: points, isRun: _trendSport == 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rögzített edzések részletei:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: points.length,
              itemBuilder: (ctx, i) {
                final p = points[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: Colors.grey[50],
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: _trendSport == 0 ? Colors.green[100] : Colors.orange[100],
                      child: Icon(_trendSport == 0 ? Icons.directions_run : Icons.directions_bike, color: _trendSport == 0 ? Colors.green[900] : Colors.orange[900], size: 18),
                    ),
                    title: Text(p['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(p['detail'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class WeeklyBarChartPainter extends CustomPainter {
  final List<Map<String, double>> weekData;
  final double maxVal;
  final int currentWeek;
  final String unit;

  WeeklyBarChartPainter({
    required this.weekData,
    required this.maxVal,
    required this.currentWeek,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    final planPaint = Paint()..color = const Color(0xFF1976D2);
    final actPaint = Paint()..color = const Color(0xFF2E7D32);
    final highlightPaint = Paint()..color = Colors.red.withOpacity(0.12);

    final double chartHeight = size.height - 40;
    const double barWidth = 11.0;
    const double barSpacing = 36.0;

    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), gridPaint);

    for (int i = 0; i < weekData.length; i++) {
      final w = i + 1;
      final x = i * barSpacing + 20;

      if (w == currentWeek) {
        canvas.drawRect(Rect.fromLTWH(x - 6, 0, barSpacing, chartHeight + 25), highlightPaint);
      }

      final plan = weekData[i]['plan'] ?? 0;
      final act = weekData[i]['act'] ?? 0;

      final planH = maxVal > 0 ? (plan / maxVal) * (chartHeight - 20) : 0;
      final actH = maxVal > 0 ? (act / maxVal) * (chartHeight - 20) : 0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, chartHeight - planH, barWidth, planH.toDouble()),
          const Radius.circular(2),
        ),
        planPaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + barWidth + 2, chartHeight - actH, barWidth, actH.toDouble()),
          const Radius.circular(2),
        ),
        actPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$w',
          style: TextStyle(
            fontSize: 10,
            fontWeight: w == currentWeek ? FontWeight.bold : FontWeight.normal,
            color: w == currentWeek ? Colors.red[900] : Colors.grey[700],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final double swimPct;
  final double bikePct;
  final double runPct;

  PieChartPainter({
    required this.swimPct,
    required this.bikePct,
    required this.runPct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 32.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double startAngle = -math.pi / 2;

    if (swimPct + bikePct + runPct == 0) {
      paint.color = Colors.grey[300]!;
      canvas.drawCircle(center, radius - strokeWidth / 2, paint);
      return;
    }

    final swimAngle = (swimPct / 100) * 2 * math.pi;
    paint.color = Colors.blue;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, swimAngle, false, paint);
    startAngle += swimAngle;

    final bikeAngle = (bikePct / 100) * 2 * math.pi;
    paint.color = Colors.orange;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, bikeAngle, false, paint);
    startAngle += bikeAngle;

    final runAngle = (runPct / 100) * 2 * math.pi;
    paint.color = Colors.green;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, runAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) => true;
}

class TrendLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;
  final bool isRun;

  TrendLineChartPainter({required this.points, required this.isRun});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double chartHeight = size.height - 35;
    const double spacing = 45.0;

    double minHr = 100, maxHr = 190;
    double minSpd = isRun ? 8.0 : 20.0;
    double maxSpd = isRun ? 15.0 : 38.0;

    for (var p in points) {
      final double hr = p['hr'];
      final double s = p['speed'];
      if (hr < minHr) minHr = hr - 5;
      if (hr > maxHr) maxHr = hr + 5;
      if (s < minSpd) minSpd = s - 1;
      if (s > maxSpd) maxSpd = s + 1;
    }

    final hrPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final spdPaint = Paint()
      ..color = isRun ? Colors.green : Colors.orange
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaintHr = Paint()..color = Colors.red;
    final dotPaintSpd = Paint()..color = isRun ? Colors.green : Colors.orange;

    final hrPath = Path();
    final spdPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = i * spacing + 20;
      final hr = points[i]['hr'];
      final s = points[i]['speed'];

      final yHr = chartHeight - ((hr - minHr) / (maxHr - minHr)) * (chartHeight - 20) - 10;
      final ySpd = chartHeight - ((s - minSpd) / (maxSpd - minSpd)) * (chartHeight - 20) - 10;

      if (i == 0) {
        hrPath.moveTo(x, yHr);
        spdPath.moveTo(x, ySpd);
      } else {
        hrPath.lineTo(x, yHr);
        spdPath.lineTo(x, ySpd);
      }

      canvas.drawCircle(Offset(x, yHr), 4, dotPaintHr);
      canvas.drawCircle(Offset(x, ySpd), 4, dotPaintSpd);

      final tp = TextPainter(
        text: TextSpan(
          text: points[i]['label'],
          style: const TextStyle(fontSize: 9, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - 12, chartHeight + 6));
    }

    canvas.drawPath(hrPath, hrPaint);
    canvas.drawPath(spdPath, spdPaint);
  }

  @override
  bool shouldRepaint(covariant TrendLineChartPainter oldDelegate) => true;
}
