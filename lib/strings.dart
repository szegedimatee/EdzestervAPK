// Central UI text. Every user-facing string lives here so a language switch
// only touches this file.
// shortcut: Hungarian only, as compile-time constants; to add language selection,
// migrate these keys to Flutter gen_l10n (ARB files) and replace `S.x` with
// `AppLocalizations.of(context).x`.
abstract final class S {
  // App
  static const appTitle = 'Ironman 70.3 Napló';
  static const homeTitle = 'Ironman 70.3 Fűzfő';
  static const race1DefaultName = '1. FÉLTÁV';
  static const race2DefaultName = 'FŰZFŐ 70.3';
  static String loadFailed(Object e) => 'Az edzésterv betöltése sikertelen: $e';

  // Common
  static const ok = 'Rendben';
  static const cancel = 'Mégse';
  static const save = 'Mentés';
  static const saveUpper = 'MENTÉS';
  static const doneUpper = 'KÉSZ';
  static const closeUpper = 'BEZÁRÁS';
  static const confirm = 'Megerősítés';
  static const reset = 'Nullázás';
  static const test = 'Teszt';
  static const today = 'Ma';
  static const workout = 'Edzés';
  static const total = 'Összesen';
  static const swim = 'Úszás';
  static const bike = 'Bringa';
  static const bikeTrainer = 'Kerékpár / Görgő';
  static const run = 'Futás';
  static String weekTitle(int week) => '$week. Hét';
  static String weekLower(int week) => '$week. hét';
  static String blockLower(int block) => '$block. blokk';
  static String weekDayShort(int week, String dayAbbr) => '$week.h $dayAbbr';
  static String hours(String h) => '$h óra';
  static String hoursAndMinutes(String h, int min) => '$h óra ($min perc)';
  static String dateLong(DateTime d) =>
      '${d.year}. ${d.month.toString().padLeft(2, '0')}. ${d.day.toString().padLeft(2, '0')}.';
  static String dateShort(DateTime d) => '${d.month}.${d.day}.';

  // Plan blocks (one focus line per 5-week block)
  static const blockFocus = <String>[
    "Aerob bázis, úszástechnika & görgő hozzászokás (Térdkímélő sík futások)",
    "Állóképesség növelése, SweetSpot blokkok & törzserő",
    "Téli volumenépítés, növekvő görgő- és futótávok",
    "Téli csúcs + Thaiföldi 2 hetes edzőtábor jellegű blokk (úszás & futás)",
    "Tavaszi nyitás: kinti 70-75km bringák & első téglaedzések",
    "1. Féltáv specifikus építés: 80-90km bringák & hosszú téglák",
    "Tapering + 1. FÉLTÁV VERSENY (Május vége/Júni eleje - Barátkozós!) + Regeneráció",
    "Fűzfőre hangolás 1.: Emelt intenzitás (Z3/SweetSpot versenytempó blokkok)",
    "Fűzfőre hangolás 2.: Csúcsterhelés & versenyszimulációs erős téglák (95km / 72km)",
    "Tapering + 2. FÉLTÁV VERSENY: BALATONFŰZFŐ (Szept. eleje - MEGNYOMÓS!) + Levezetés",
  ];

  // Notifications
  static String notifTodayTitle(String day) => 'Ironman 70.3 Mai Edzésed ($day)';
  static const notifTodayFallback = 'Ne felejtsd el megtekinteni a mai edzéstervedet!';
  static const dailyChannelName = 'Napi Edzés Emlékeztető';
  static const dailyChannelDesc = 'Értesítés az aznapi kitűzött edzésmunkáról';
  static const testChannelName = 'Teszt Értesítés';
  static const testChannelDesc = 'Azonnali teszt értesítés';
  static String testNotifTitle(String day) => '🏆 Teszt: Ironman 70.3 ($day)';
  static String testNotifBody(String sport, String desc) => 'Előírás: $sport - $desc';
  static const checkTodayTask = 'Tekintsd meg a mai feladatodat!';
  static const notifSheetTitle = 'Napi Edzés Emlékeztető';
  static const notifSheetDesc =
      'Kapj minden reggel automatikus értesítést a telefonodra az aznapi előírt edzésről és zónákról.';
  static const enableDailyNotif = 'Napi értesítés bekapcsolása';
  static const notifActive = 'Aktív: Minden nap az adott időpontban';
  static const notifOff = 'Kikapcsolva';
  static const reminderTime = 'Emlékeztető időpontja';
  static const testNotifNow = 'Teszteld az értesítést most';
  static const testNotifHint = 'Kattints az alábbi gombra az azonnali mintáért.';
  static const notifSent = '🔔 Értesítés elküldve a telefonod értesítési sávjára!';

  // Block overview
  static const periodBlocksTitle = '5 Hetes Periodizációs Blokkok';
  static String blockRange(int block, int startW, int endW) => '$block. Blokk ($startW–$endW. hét)';
  static String planKmHours(String km, String h) => 'Terv: $km km ($h óra)';
  static String measuredKm(String km) => 'Mért: $km km';
  static String blockAvgHr(String hr) => '❤️ Blokk átlagpulzus: $hr bpm';
  static const swimUpper = '🏊 ÚSZÁS';
  static const bikeUpper = '🚴 BRINGA';
  static const runUpper = '🏃 FUTÁS';

  // Global summary
  static const globalSummary = 'Globális Összesítő';
  static String totalPlannedTime(int min, String h) => '• Összes tervezett idő: $min perc ($h óra)';
  static String avgWeeklyTime(String h) => '• Átlagos heti edzésidő: $h óra / hét';
  static String totalPlannedDist(String km) => '• Összes tervezett táv: $km km';
  static String totalDoneDist(String km, String pct) => '• Összes teljesített táv: $km km ($pct%)';
  static String swimLine(String km) => '  - 🏊 Úszás: $km km';
  static String bikeLine(String km) => '  - 🚴 Bringa / Görgő: $km km';
  static String runLine(String km) => '  - 🏃 Futás: $km km';
  static String avgHrLine(String hr, int count) => '❤️ Átlagos mért pulzus: $hr bpm ($count edzés alapján)';

  // Workout log sheet
  static String workoutHeader(int week, String day, String sport) => '$week. hét, $day - $sport';
  static const swimKmLabel = 'Úszás (km)';
  static const paceLabel = 'Tempó (mm:ss)';
  static const bikeKmLabel = 'Kerékpár (km)';
  static const speedLabel = 'Sebesség (km/h)';
  static const runKmLabel = 'Futás (km)';
  static const doneDistLabel = 'Teljesített táv (km)';
  static const avgHrLabel = 'Átlagpulzus (bpm)';
  static const rpeNotesLabel = 'RPE / Megjegyzés';
  static const carbsLabel = 'Elfogyasztott CH (g)';
  static const stomachLabel = 'Gyomorérzet (pl. 5/5 jó)';
  static const invalidInput = 'Hibás adat: számok pozitívak, tempó mm:ss, pulzus 0–250.';

  // Race countdown
  static String raceSettings(int raceNum) => '$raceNum. Verseny Beállítása';
  static const raceName = 'Verseny megnevezése';
  static const chosenRaceDay = 'Választott versenynap:';
  static const raceCountdown = 'VERSENYEK VISSZASZÁMLÁLÓJA';
  static const tapToEdit = 'Koppints a módosításhoz ✎';
  static String daysLeft(int days) => '$days nap';
  static String weeksLeft(int weeks) => '$weeks hét hátralévő idő';

  // Home menu and week view
  static const dailyNotifications = 'Napi Értesítések';
  static const fuelCalculator = 'Frissítés Kalkulátor';
  static const gearTitle = 'Felszerelés & Eszköztár';
  static const chartsMenu = 'Grafikonok és Diagramok';
  static const fiveWeekBlocks = '5 hetes blokkok';
  static const globalStats = 'Globális statisztika';
  static const thisWeekUpper = 'MAI HÉT';
  static const todayUpper = 'MAI NAP';
  static String planLine(num km, int min, String zone) => 'Terv: $km km (${min}p) [$zone]';
  static String measuredTotal(num km) => 'Mért össztáv: $km km';
  static String fuelLine(int carbs) => '⚡ Frissítés: ${carbs}g CH ';
  static const statusDone = 'Kész';
  static const statusSkipped = 'Kihagyott';
  static const statusFuture = 'Jövőbeli';

  // Fueling calculator
  static const fuelTitle = 'Szénhidrát & Frissítés Tervező';
  static const fuelDesc = 'Kalkuláld ki a szükséges energiát és folyadékot a hosszú edzésekhez és versenyekhez.';
  static const plannedDuration = 'Tervezett időtartam:';
  static const carbTargetLabel = 'Cél CH bevitel / óra:';
  static String carbsPerHour(int g) => '$g g CH / óra';
  static const carb40 = '40g (Z1/Z2)';
  static const carb60 = '60g (Bázis)';
  static const carb75 = '75g (Féltáv)';
  static const carb90 = '90g (Profi)';
  static const totalFuelUpper = 'SZÜKSÉGES FRISSÍTÉS ÖSSZESEN:';
  static const carbs = '⚡ Szénhidrát';
  static const fluid = '💧 Folyadék';
  static const gel = '🥤 Zselé (~25g)';
  static String pieces(String count) => '$count db';
  static String fuelRecipe(int fluidMl, int gels) =>
      '💡 Praktikus recept: $fluidMl ml izotóniás ital (kulacsokban) + $gels db zselé vagy energiaszelet 20-30 percenként elosztva.';

  // Gear tracker
  static const gearStatusTitle = 'Eszközök & Alkatrészek Állapota';
  static const gearDesc = 'Kövesd nyomon futócipőid, kerékpárláncod és felszereléseid amortizációját.';
  static const primaryShoe = 'Elsődleges Futócipő';
  static const newShoeHint = 'Új futócipő használatba vétele (kilométerek lenullázása)';
  static const newShoeReset = 'Új cipő / Reset';
  static String kmRun(String km) => '$km km lefutva';
  static String recommendedReplace(int km) => 'Ajánlott csere: $km km';
  static const shoeWorn = '⚠️ A cipő amortizációja a végéhez közeledik, érdemes cserélni a térdízületek védelmében!';
  static String shoeOk(String pct) => 'Állapot: Jó párnázás ($pct% elhasználódás)';
  static const chainTitle = 'Kerékpárlánc & Hajtás';
  static const newChainHint = 'Új lánc feltétele (kilométerek lenullázása)';
  static const newChainReset = 'Új lánc / Reset';
  static String kmRidden(String km) => '$km km letekerve';
  static String recommendedCheck(int km) => 'Ajánlott ellenőrzés: $km km';
  static const chainWorn = '⚠️ Érdemes láncnyúlást mérni a fogaskoszorú megóvása érdekében!';
  static String chainOk(String pct) => 'Lánc állapot: Megfelelő ($pct% használat)';
  static const swimGearTitle = 'Úszóedzések & Neoprén';
  static String swimWorkoutsInPlan(int count) => '$count rögzített úszóedzés a tervben';
  static const wetsuitHint = 'Neoprén tesztek ajánlottak a 21. héttől!';

  // Charts
  static const analysisTitle = 'Edzéselemzés & Grafikonok';
  static const volumeTab = 'Volumen';
  static const sportsTab = 'Sportágak';
  static const hrPaceTab = 'Pulzus / Tempó';
  static const weeklyVolume = 'Heti Edzésmennyiség';
  static const distanceKm = 'Táv (km)';
  static const timeH = 'Idő (h)';
  static const volumeLegend = 'Kék: Tervezett előírás • Zöld: Ténylegesen teljesített\n(Két ujjal görgethető az 50 hét során)';
  static String weekSportShare(int week) => '$week. Hét sportági aránya';
  static String blockDistribution(int block, int startW, int endW) => '$block. Blokk ($startW–$endW. hét) megoszlása';
  static const seasonShare = 'Teljes eddigi szezon megoszlása';
  static const sportShareTitle = 'Sportági Megoszlás & Arányok';
  static const totalMeasured = 'Összes mért';
  static const aerobicEfficiency = 'Aerob Hatékonyság';
  static const runTrendTitle = 'Futótempó és Mért Pulzus alakulása az edzések során';
  static const bikeTrendTitle = 'Kerékpár Sebesség és Mért Pulzus alakulása az edzések során';
  static String notEnoughHrData(bool run) =>
      'Még nincs elég pulzussal rögzített ${run ? "futás" : "kerékpározás"} az adatbázisban.';
  static const hrBpm = 'Pulzus (bpm)';
  static const paceSpeed = 'Tempó / Sebesség';
}

// Values that appear in edzesterv_adatbazis.csv. They must match the data file,
// so they stay Hungarian whatever UI language is chosen.
abstract final class PlanTerms {
  static const rest = 'Pihenő';
  // Lowercase fragments matched against the lowercased sport column
  static const swim = 'úszás';
  static const brick = 'tégla';
  static const bike = 'bringa';
  static const trainer = 'görgő';
  static const cycling = 'kerékpár';
  static const run = 'futás';
  static const restLower = 'pihenő';
}
