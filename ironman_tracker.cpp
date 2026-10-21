#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <iomanip>
#include <cmath>
#include <algorithm>

#ifdef _WIN32
#include <windows.h>
#endif

using namespace std;

// Egyetlen napi edzés (sor) adatszerkezete az Excel alapján
struct Workout {
    int week = 0;
    string day;
    string sport;
    int plan_time_min = 0;
    double plan_dist_km = 0.0;
    string zone;
    string description;

    // Ténylegesen mért adatok (0.0 vagy üres, ha még nincs kitöltve)
    double act_swim_km = 0.0;
    double act_bike_km = 0.0;
    double act_run_km = 0.0;
    double act_total_km = 0.0;
    int act_hr_bpm = 0;
    string swim_pace;   // mm:ss vagy hh:mm:ss
    double bike_speed = 0.0;
    string run_pace;    // mm:ss vagy hh:mm:ss
    string notes_rpe;
};

// Segédfüggvény: szöveg -> double konverzió biztonságosan
double parseDouble(const string& s) {
    if (s.empty()) return 0.0;
    string clean = s;
    replace(clean.begin(), clean.end(), ',', '.');
    try {
        return stod(clean);
    } catch (...) {
        return 0.0;
    }
}

// Segédfüggvény: szöveg -> int konverzió biztonságosan
int parseInt(const string& s) {
    if (s.empty()) return 0;
    try {
        return static_cast<int>(round(parseDouble(s)));
    } catch (...) {
        return 0;
    }
}

// Tempó (pl. "00:05:48" vagy "05:48") átváltása másodpercre az átlagszámításhoz
int paceToSeconds(const string& pace) {
    if (pace.empty() || pace == "-") return 0;
    vector<int> parts;
    stringstream ss(pace);
    string item;
    while (getline(ss, item, ':')) {
        parts.push_back(parseInt(item));
    }
    if (parts.size() == 3) {
        // hh:mm:ss formátum (ahogy az Excel tárolja: pl. 00:05:48)
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.size() == 2) {
        // mm:ss formátum (pl. 05:48)
        return parts[0] * 60 + parts[1];
    }
    return 0;
}

// Másodperc visszaalakítása "mm:ss" formátumra
string secondsToPace(double avg_sec) {
    if (avg_sec <= 0.0) return "-";
    int total = static_cast<int>(round(avg_sec));
    int m = total / 60;
    int s = total % 60;
    ostringstream oss;
    oss << setfill('0') << setw(2) << m << ":" << setfill('0') << setw(2) << s;
    return oss.str();
}

// CSV sor felbontása pontosvessző (;) mentén
vector<string> splitCSV(const string& line, char delimiter = ';') {
    vector<string> tokens;
    string token;
    stringstream ss(line);
    while (getline(ss, token, delimiter)) {
        // Sorvégi \r eltávolítása
        if (!token.empty() && token.back() == '\r') {
            token.pop_back();
        }
        tokens.push_back(token);
    }
    // Ha a sor pontosvesszővel végződik, az utolsó üres mezőt is adjuk hozzá
    if (!line.empty() && line.back() == delimiter) {
        tokens.push_back("");
    }
    return tokens;
}

// Adatbázis betöltése CSV fájlból
bool loadDatabase(const string& filename, vector<Workout>& db, string& header) {
    ifstream file(filename);
    if (!file.is_open()) return false;

    db.clear();
    if (!getline(file, header)) return false;
    if (!header.empty() && header.back() == '\r') header.pop_back();

    string line;
    while (getline(file, line)) {
        if (line.empty()) continue;
        vector<string> cols = splitCSV(line, ';');
        if (cols.size() < 7) continue;

        Workout w;
        w.week          = parseInt(cols[0]);
        w.day           = cols[1];
        w.sport         = cols[2];
        w.plan_time_min = parseInt(cols[3]);
        w.plan_dist_km  = parseDouble(cols[4]);
        w.zone          = cols[5];
        w.description   = cols[6];

        if (cols.size() > 7)  w.act_swim_km  = parseDouble(cols[7]);
        if (cols.size() > 8)  w.act_bike_km  = parseDouble(cols[8]);
        if (cols.size() > 9)  w.act_run_km   = parseDouble(cols[9]);
        w.act_total_km = w.act_swim_km + w.act_bike_km + w.act_run_km;
        if (cols.size() > 11) w.act_hr_bpm   = parseInt(cols[11]);
        if (cols.size() > 12) w.swim_pace    = cols[12];
        if (cols.size() > 13) w.bike_speed   = parseDouble(cols[13]);
        if (cols.size() > 14) w.run_pace     = cols[14];
        if (cols.size() > 15) w.notes_rpe    = cols[15];

        db.push_back(w);
    }
    file.close();
    return true;
}

// Adatbázis mentése CSV fájlba
bool saveDatabase(const string& filename, const vector<Workout>& db, const string& header) {
    ofstream file(filename);
    if (!file.is_open()) return false;

    file << header << "\n";
    for (const auto& w : db) {
        file << w.week << ";"
             << w.day << ";"
             << w.sport << ";"
             << w.plan_time_min << ";"
             << w.plan_dist_km << ";"
             << w.zone << ";"
             << w.description << ";";

        if (w.act_swim_km > 0) file << w.act_swim_km;
        file << ";";
        if (w.act_bike_km > 0) file << w.act_bike_km;
        file << ";";
        if (w.act_run_km > 0) file << w.act_run_km;
        file << ";";
        file << (w.act_swim_km + w.act_bike_km + w.act_run_km) << ";";
        if (w.act_hr_bpm > 0) file << w.act_hr_bpm;
        file << ";";
        file << w.swim_pace << ";";
        if (w.bike_speed > 0) file << w.bike_speed;
        file << ";";
        file << w.run_pace << ";";
        file << w.notes_rpe << "\n";
    }
    file.close();
    return true;
}

// 1. Globális összesítő (Excel 3. munkalap logikája alapján)
void showGlobalSummary(const vector<Workout>& db) {
    int total_plan_min = 0;
    double total_plan_km = 0.0;
    double total_swim_km = 0.0, total_bike_km = 0.0, total_run_km = 0.0;
    int hr_sum = 0, hr_count = 0;

    for (const auto& w : db) {
        total_plan_min += w.plan_time_min;
        total_plan_km  += w.plan_dist_km;
        total_swim_km  += w.act_swim_km;
        total_bike_km  += w.act_bike_km;
        total_run_km   += w.act_run_km;
        if (w.act_hr_bpm > 0) {
            hr_sum += w.act_hr_bpm;
            hr_count++;
        }
    }

    double total_act_km = total_swim_km + total_bike_km + total_run_km;
    double completion_pct = (total_plan_km > 0) ? (total_act_km / total_plan_km) * 100.0 : 0.0;
    double avg_hr = (hr_count > 0) ? static_cast<double>(hr_sum) / hr_count : 0.0;

    cout << "\n====================================================================\n";
    cout << "          IRONMAN 70.3 GLOBÁLIS ÖSSZESÍTŐ STATISZTIKA\n";
    cout << "====================================================================\n";
    cout << fixed << setprecision(2);
    cout << " Összes tervezett edzésidő : " << total_plan_min << " perc (" << (total_plan_min / 60.0) << " óra)\n";
    cout << " Átlagos heti edzésidő     : " << (total_plan_min / 60.0 / 50.0) << " óra / hét\n";
    cout << " Összes tervezett távolság : " << total_plan_km << " km\n";
    cout << "--------------------------------------------------------------------\n";
    cout << " Összes teljesített táv    : " << total_act_km << " km\n";
    cout << "   - Ebből Úszás           : " << total_swim_km << " km\n";
    cout << "   - Ebből Kerékpár/Görgő  : " << total_bike_km << " km\n";
    cout << "   - Ebből Futás           : " << total_run_km << " km\n";
    cout << " Tervezett táv teljesülése : " << completion_pct << " %\n";
    cout << " Átlagosan mért pulzus     : " << setprecision(1) << avg_hr << " bpm (" << hr_count << " edzés alapján)\n";
    cout << "====================================================================\n";
}

// 2. 5 Hetes Periodizációs Statisztika (Excel 2. munkalap logikája alapján)
void showBlockStatistics(const vector<Workout>& db) {
    cout << "\n========================================================================================================================\n";
    cout << "                               5 HETES PERIODIZÁCIÓS STATISZTIKA ÉS FEJLŐDÉSKÖVETÉS\n";
    cout << "========================================================================================================================\n";
    cout << left << setw(10) << "Blokk"
         << setw(12) << "Hetek"
         << right << setw(10) << "Terv(h)"
         << setw(11) << "Terv(km)"
         << setw(11) << "Mért(km)"
         << setw(9)  << "Telj.%"
         << setw(11) << "Úszás(km)"
         << setw(10) << "Ú.Tempó"
         << setw(12) << "Bringa(km)"
         << setw(10) << "Br.Seb."
         << setw(11) << "Futás(km)"
         << setw(10) << "F.Tempó" << "\n";
    cout << "------------------------------------------------------------------------------------------------------------------------\n";

    for (int b = 0; b < 10; ++b) {
        int start_week = b * 5 + 1;
        int end_week = (b + 1) * 5;

        int plan_min = 0;
        double plan_km = 0.0, swim_km = 0.0, bike_km = 0.0, run_km = 0.0;
        int swim_pace_sum = 0, swim_pace_cnt = 0;
        double bike_spd_sum = 0.0; int bike_spd_cnt = 0;
        int run_pace_sum = 0, run_pace_cnt = 0;

        for (const auto& w : db) {
            if (w.week >= start_week && w.week <= end_week) {
                plan_min += w.plan_time_min;
                plan_km  += w.plan_dist_km;
                swim_km  += w.act_swim_km;
                bike_km  += w.act_bike_km;
                run_km   += w.act_run_km;

                int sp = paceToSeconds(w.swim_pace);
                if (sp > 0) { swim_pace_sum += sp; swim_pace_cnt++; }

                if (w.bike_speed > 0) { bike_spd_sum += w.bike_speed; bike_spd_cnt++; }

                int rp = paceToSeconds(w.run_pace);
                if (rp > 0) { run_pace_sum += rp; run_pace_cnt++; }
            }
        }

        double act_km = swim_km + bike_km + run_km;
        double pct = (plan_km > 0) ? (act_km / plan_km) * 100.0 : 0.0;
        string avg_swim_p = (swim_pace_cnt > 0) ? secondsToPace(static_cast<double>(swim_pace_sum) / swim_pace_cnt) : "-";
        string avg_run_p  = (run_pace_cnt > 0)  ? secondsToPace(static_cast<double>(run_pace_sum) / run_pace_cnt)   : "-";

        ostringstream blk_name, wk_range, bike_spd_str;
        blk_name << (b + 1) << ". Blokk";
        wk_range << start_week << "-" << end_week << ". hét";
        if (bike_spd_cnt > 0) {
            bike_spd_str << fixed << setprecision(1) << (bike_spd_sum / bike_spd_cnt);
        } else {
            bike_spd_str << "-";
        }

        cout << left << setw(10) << blk_name.str()
             << setw(12) << wk_range.str()
             << right << fixed << setprecision(1)
             << setw(10) << (plan_min / 60.0)
             << setw(11) << plan_km
             << setprecision(2) << setw(11) << act_km
             << setprecision(1) << setw(8) << pct << "%"
             << setprecision(2) << setw(11) << swim_km
             << setw(10) << avg_swim_p
             << setw(12) << bike_km
             << setw(10) << bike_spd_str.str()
             << setw(11) << run_km
             << setw(10) << avg_run_p << "\n";
    }
    cout << "========================================================================================================================\n";
}

// 3. Kiválasztott hét részletes megjelenítése
void showWeekDetails(const vector<Workout>& db, int target_week) {
    cout << "\n====================================================================================\n";
    cout << "                           " << target_week << ". HÉT EDZÉSTERVE ÉS NAPLÓJA\n";
    cout << "====================================================================================\n";

    double plan_km_sum = 0.0, act_km_sum = 0.0;
    for (const auto& w : db) {
        if (w.week == target_week) {
            plan_km_sum += w.plan_dist_km;
            act_km_sum  += w.act_total_km;
            string status = (w.act_total_km > 0.0 || w.sport == "Pihenő") ? "[ TELJESÍTVE ]" : "[   NYITOTT  ]";

            cout << " " << left << setw(10) << w.day
                 << " | " << setw(15) << w.sport
                 << " | Zóna: " << setw(6) << w.zone
                 << " | Terv: " << right << setw(3) << w.plan_time_min << "p / "
                 << fixed << setprecision(1) << setw(5) << w.plan_dist_km << " km  " << status << "\n";
            cout << "   Leírás : " << w.description << "\n";

            if (w.act_total_km > 0.0) {
                cout << "   -> MÉRT ADATOK: Összesen " << setprecision(2) << w.act_total_km << " km (";
                if (w.act_swim_km > 0) cout << "Úszás: " << w.act_swim_km << "km, Tempó: " << w.swim_pace << " ";
                if (w.act_bike_km > 0) cout << "Bringa: " << w.act_bike_km << "km, Seb: " << setprecision(1) << w.bike_speed << "km/h ";
                if (w.act_run_km > 0)  cout << "Futás: " << setprecision(2) << w.act_run_km << "km, Tempó: " << w.run_pace << " ";
                cout << ") | Pulzus: " << w.act_hr_bpm << " bpm | RPE/Megj: " << w.notes_rpe << "\n";
            }
            cout << "------------------------------------------------------------------------------------\n";
        }
    }
    cout << " Heti összesítés -> Tervezett: " << fixed << setprecision(1) << plan_km_sum
         << " km | Teljesített: " << setprecision(2) << act_km_sum << " km\n";
    cout << "====================================================================================\n";
}

// 4. Új edzésadat rögzítése vagy módosítása (Tégla edzés támogatással!)
void recordWorkout(vector<Workout>& db) {
    int week_num;
    cout << "\nAdd meg a hetet (1 - 50): ";
    if (!(cin >> week_num) || week_num < 1 || week_num > 50) {
        cin.clear(); cin.ignore(10000, '\n');
        cout << "Érvénytelen hétszám!\n";
        return;
    }

    vector<int> indices;
    cout << "\n--- A(z) " << week_num << ". hét napjai ---\n";
    for (size_t i = 0; i < db.size(); ++i) {
        if (db[i].week == week_num) {
            indices.push_back(static_cast<int>(i));
            cout << " [" << indices.size() << "] " << left << setw(10) << db[i].day
                 << " - " << setw(15) << db[i].sport
                 << " (Terv: " << db[i].plan_dist_km << " km, Mért: " << db[i].act_total_km << " km)\n";
        }
    }

    int day_choice;
    cout << "Válaszd ki a nap sorszámát (1 - " << indices.size() << "): ";
    if (!(cin >> day_choice) || day_choice < 1 || day_choice > static_cast<int>(indices.size())) {
        cin.clear(); cin.ignore(10000, '\n');
        cout << "Érvénytelen választás!\n";
        return;
    }

    Workout& w = db[indices[day_choice - 1]];
    cout << "\nKiválasztott edzés: " << w.week << ". hét, " << w.day << " - " << w.sport << "\n";
    cout << "Előírás: " << w.description << "\n";
    cout << "(Ha egy mező nem releváns az adott napon, írj 0-t vagy '-' jelet!)\n\n";

    cout << "Mért Úszás táv (km) [jelenlegi: " << w.act_swim_km << "]: ";
    cin >> w.act_swim_km;
    if (w.act_swim_km > 0) {
        cout << "Úszás tempó (mm:ss / 100m, pl. 02:03) [jelenlegi: " << (w.swim_pace.empty() ? "-" : w.swim_pace) << "]: ";
        cin >> w.swim_pace;
    } else {
        w.swim_pace = "";
    }

    cout << "Mért Kerékpár/Görgő táv (km) [jelenlegi: " << w.act_bike_km << "]: ";
    cin >> w.act_bike_km;
    if (w.act_bike_km > 0) {
        cout << "Kerékpár átlagsebesség (km/h, pl. 28.5) [jelenlegi: " << w.bike_speed << "]: ";
        cin >> w.bike_speed;
    } else {
        w.bike_speed = 0.0;
    }

    cout << "Mért Futás táv (km) [jelenlegi: " << w.act_run_km << "]: ";
    cin >> w.act_run_km;
    if (w.act_run_km > 0) {
        cout << "Futás tempó (mm:ss / km, pl. 05:45) [jelenlegi: " << (w.run_pace.empty() ? "-" : w.run_pace) << "]: ";
        cin >> w.run_pace;
    } else {
        w.run_pace = "";
    }

    w.act_total_km = w.act_swim_km + w.act_bike_km + w.act_run_km;

    cout << "Mért Átlagpulzus (bpm, pl. 148) [jelenlegi: " << w.act_hr_bpm << "]: ";
    cin >> w.act_hr_bpm;

    cin.ignore(10000, '\n');
    cout << "Megjegyzés / Érzet (RPE 1-10, pl. 7 vagy 'Jó lábak, RPE 6'): ";
    getline(cin, w.notes_rpe);

    cout << "\n>> Edzés sikeresen frissítve! Napi össztáv: " << fixed << setprecision(2) << w.act_total_km << " km.\n";
}

int main() {
#ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
#endif

    const string filename = "edzesterv_adatbazis.csv";
    vector<Workout> db;
    string header;

    if (!loadDatabase(filename, db, header)) {
        cerr << "HIBA: Nem sikerült megnyitni a(z) '" << filename << "' fájlt!\n";
        cerr << "Győződj meg róla, hogy a CSV fájl a programmal egy mappában van.\n";
        return 1;
    }

    cout << "Adatbázis sikeresen betöltve (" << db.size() << " edzésnap).\n";

    int choice = -1;
    while (choice != 0) {
        // Képernyő törlése a menü kirajzolása előtt
        #ifdef _WIN32
            system("cls");
        #else
            system("clear");
        #endif

        cout << "\n================ IRONMAN 70.3 EDZÉSNAPLÓ KEZELŐ ================\n";
        cout << " 1. Globális összesítő megtekintése (Teljes szezon)\n";
        cout << " 2. 5 Hetes Periodizációs Statisztika (1-10. Blokk)\n";
        cout << " 3. Kiválasztott hét részletes tervének és naplójának lekérdezése\n";
        cout << " 4. Edzésadatok felvitele / módosítása (Tégla edzés támogatással)\n";
        cout << " 5. Mentés a CSV adatbázisba\n";
        cout << " 0. Kilépés (automatikus mentéssel)\n";
        cout << "================================================================\n";
        cout << "Választás: ";

        if (!(cin >> choice)) {
            cin.clear();
            cin.ignore(10000, '\n');
            continue;
        }

        // Képernyő törlése a választás után, hogy az eredmény tiszta lapra kerüljön
        #ifdef _WIN32
            system("cls");
        #else
            system("clear");
        #endif

        switch (choice) {
            case 1:
                showGlobalSummary(db);
                break;
            case 2:
                showBlockStatistics(db);
                break;
            case 3: {
                int w;
                cout << "Melyik hetet szeretnéd látni (1 - 50)? ";
                if (cin >> w && w >= 1 && w <= 50) {
                    showWeekDetails(db, w);
                } else {
                    cin.clear(); cin.ignore(10000, '\n');
                    cout << "Érvénytelen hétszám!\n";
                }
                break;
            }
            case 4:
                recordWorkout(db);
                saveDatabase(filename, db, header);
                cout << "(A változtatások automatikusan mentésre kerültek a CSV fájlba.)\n";
                break;
            case 5:
                if (saveDatabase(filename, db, header)) {
                    cout << ">> Adatbázis sikeresen elmentve (" << filename << ").\n";
                }
                break;
            case 0:
                saveDatabase(filename, db, header);
                cout << ">> Adatok elmentve. Jó edzést és sikeres felkészülést Balatonfűzfőre!\n";
                break;
            default:
                cout << "Ismeretlen menüpont!\n";
        }

        // Ha nem lép ki, megvárunk egy billentyűleütést, hogy elolvashasd az eredményt, mielőtt újra tiszta lesz a képernyő
        if (choice != 0) {
            cout << "\nNyomj Entert a folytatáshoz...";
            cin.ignore(10000, '\n');
            cin.get();
        }
    }
    return 0;
}
