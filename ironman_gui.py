import tkinter as tk
from tkinter import messagebox, ttk
import csv
import os
from datetime import datetime

DB_FILE = "edzesterv_adatbazis.csv"

def load_data():
    workouts = []
    if not os.path.exists(DB_FILE):
        return workouts
    with open(DB_FILE, mode='r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter=';')
        header = next(reader, None)
        for index, row in enumerate(reader):
            if len(row) >= 7:
                workouts.append({
                    'index': index,  # 0-tól 349-ig a sorszám (heti 7 nap)
                    'week': int(row[0]) if row[0].isdigit() else 0,
                    'day': row[1],
                    'sport': row[2],
                    'plan_time': float(row[3]) if row[3].replace('.', '', 1).isdigit() else 0,
                    'plan_dist': float(row[4]) if row[4].replace('.', '', 1).isdigit() else 0,
                    'zone': row[5],
                    'desc': row[6],
                    'act_swim': float(row[7]) if len(row) > 7 and row[7].replace('.', '', 1).isdigit() else 0.0,
                    'act_bike': float(row[8]) if len(row) > 8 and row[8].replace('.', '', 1).isdigit() else 0.0,
                    'act_run': float(row[9]) if len(row) > 9 and row[9].replace('.', '', 1).isdigit() else 0.0,
                    'act_total': float(row[10]) if len(row) > 10 and row[10].replace('.', '', 1).isdigit() else 0.0,
                    'hr': int(row[11]) if len(row) > 11 and row[11].isdigit() else 0,
                    'swim_pace': row[12] if len(row) > 12 else "",
                    'bike_speed': float(row[13]) if len(row) > 13 and row[13].replace('.', '', 1).isdigit() else 0.0,
                    'run_pace': row[14] if len(row) > 14 else "",
                    'notes': row[15] if len(row) > 15 else ""
                })
    return workouts

def save_data(workouts, header):
    with open(DB_FILE, mode='w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, delimiter=';')
        writer.writerow(header)
        for w in workouts:
            writer.writerow([
                w['week'], w['day'], w['sport'], w['plan_time'], w['plan_dist'], w['zone'], w['desc'],
                w['act_swim'] if w['act_swim'] > 0 else "",
                w['act_bike'] if w['act_bike'] > 0 else "",
                w['act_run'] if w['act_run'] > 0 else "",
                w['act_total'],
                w['hr'] if w['hr'] > 0 else "",
                w['swim_pace'],
                w['bike_speed'] if w['bike_speed'] > 0 else "",
                w['run_pace'], w['notes']
            ])

def pace_to_seconds(pace_str):
    if not pace_str or pace_str == "-":
        return 0
    parts = pace_str.split(':')
    try:
        if len(parts) == 3:
            return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
        elif len(parts) == 2:
            return int(parts[0]) * 60 + int(parts[1])
    except ValueError:
        return 0
    return 0

def seconds_to_pace(total_sec):
    if total_sec <= 0:
        return "-"
    m = int(total_sec // 60)
    s = int(round(total_sec % 60))
    return f"{m:02d}:{s:02d}"

class IronmanApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Ironman 70.3 Edzésnapló & Előrehaladás")
        self.root.geometry("1080x680")
        self.root.state('zoomed')  # <-- TELJES KÉPERNYŐS INDÍTÁS
        
        self.header = ["Hét", "Nap", "Sportág", "Terv Idő (p)", "Terv Táv (km)", "Zóna", "Részletes edzésmunka", 
                       "Mért Úszás (km)", "Mért Bringa (km)", "Mért Futás (km)", "Összes Mért Táv (km)", 
                       "Mért Átlagpulzus (bpm)", "Úszás Tempó (mm:ss)", "Bringa Seb. (km/h)", "Futás Tempó (mm:ss)", "Megjegyzés / Érzet (RPE 1-10)"]
        self.workouts = load_data()

        # Számítógép valós dátumának alapú automatikus nap- és hétszámítás (Kezdőnap: 2026. október 5.)
        start_date = datetime(2026, 10, 5)
        today_date = datetime.now()
        
        days_passed = (today_date.date() - start_date.date()).days
        if days_passed < 0:
            days_passed = 0
        if days_passed > 349:
            days_passed = 349

        self.today_index = days_passed
        self.current_week = (days_passed // 7) + 1

        # Felső keret gombokkal
        top_frame = tk.Frame(root, bg="#1E1E1E", pady=10)
        top_frame.pack(fill=tk.X)

        title_lbl = tk.Label(top_frame, text="IRONMAN 70.3 FŰZFŐ - EDZÉSNAPLÓ", fg="white", bg="#1E1E1E", font=("Arial", 14, "bold"))
        title_lbl.pack(side=tk.LEFT, padx=15)

        stat_btn = tk.Button(top_frame, text="5 Hetes Blokkok Statisztikája", command=self.show_block_stats, bg="#FF9800", fg="white", font=("Arial", 10, "bold"))
        stat_btn.pack(side=tk.RIGHT, padx=10)

        global_btn = tk.Button(top_frame, text="Globális Összesítő", command=self.show_global_stats, bg="#007ACC", fg="white", font=("Arial", 10, "bold"))
        global_btn.pack(side=tk.RIGHT, padx=5)

        # Hét választó sáv + "Aktuális Hét" gomb
        filter_frame = tk.Frame(root, pady=10)
        filter_frame.pack(fill=tk.X, padx=15)

        tk.Label(filter_frame, text="Válassz hetet (1-50):", font=("Arial", 10, "bold")).pack(side=tk.LEFT)
        self.week_spin = tk.Spinbox(filter_frame, from_=1, to=50, width=5, font=("Arial", 10), command=self.load_week_table)
        self.week_spin.pack(side=tk.LEFT, padx=10)
        self.week_spin.delete(0, tk.END)
        self.week_spin.insert(0, str(self.current_week))

        load_btn = tk.Button(filter_frame, text="Hét betöltése", command=self.load_week_table, bg="#4CAF50", fg="white", font=("Arial", 10))
        load_btn.pack(side=tk.LEFT, padx=5)

        today_btn = tk.Button(filter_frame, text="📍 Ugrás a mai hétre", command=self.jump_to_today_week, bg="#607D8B", fg="white", font=("Arial", 10, "bold"))
        today_btn.pack(side=tk.LEFT, padx=15)

        # Fő táblázat (Treeview)
        table_frame = tk.Frame(root)
        table_frame.pack(fill=tk.BOTH, expand=True, padx=15, pady=5)

        columns = ("Nap", "Sportág", "Terv Idő", "Terv Táv", "Zóna", "Leírás", "Mért Táv", "Pulzus", "RPE / Megjegyzés")
        self.tree = ttk.Treeview(table_frame, columns=columns, show="headings", height=15)
        
        col_widths = [90, 110, 80, 80, 80, 350, 90, 80, 180]
        for col, width in zip(columns, col_widths):
            self.tree.heading(col, text=col)
            self.tree.column(col, width=width, anchor=tk.W)

        # Színstílusok
        self.tree.tag_configure("completed", background="#D4EDDA") # Zöld (teljesítve)
        self.tree.tag_configure("today", background="#F8D7DA")     # Pirosas (a mai nap)
        self.tree.tag_configure("missed", background="#FFF3CD")    # Sárga (múltbeli kihagyott)
        self.tree.tag_configure("future", background="#FFFFFF")    # Fehér (jövőbeli)

        scrollbar = ttk.Scrollbar(table_frame, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscrollcommand=scrollbar.set)
        
        self.tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.tree.bind("<Double-1>", self.edit_selected_workout)

        # Alsó információs sáv jelmagyarázattal
        bottom_frame = tk.Frame(root, pady=15)
        bottom_frame.pack(fill=tk.X, padx=15)

        tk.Label(bottom_frame, text="🟢 Zöld: Teljesítve", fg="#2e7d32", font=("Arial", 9, "bold")).pack(side=tk.LEFT, padx=5)
        tk.Label(bottom_frame, text="🔴 Piros: A mai nap", fg="#c62828", font=("Arial", 9, "bold")).pack(side=tk.LEFT, padx=15)
        tk.Label(bottom_frame, text="🟡 Sárga: Múltbeli kihagyott", fg="#b7791f", font=("Arial", 9, "bold")).pack(side=tk.LEFT, padx=15)
        tk.Label(bottom_frame, text="⚪ Fehér: Jövőbeli edzésnap", fg="#555", font=("Arial", 9)).pack(side=tk.LEFT, padx=5)

        self.load_week_table()

    def jump_to_today_week(self):
        self.week_spin.delete(0, tk.END)
        self.week_spin.insert(0, str(self.current_week))
        self.load_week_table()

    def load_week_table(self):
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        try:
            target_week = int(self.week_spin.get())
        except ValueError:
            target_week = 1

        for w in self.workouts:
            if w['week'] == target_week:
                act_str = f"{w['act_total']:.1f} km" if w['act_total'] > 0 else "-"
                hr_str = f"{w['hr']} bpm" if w['hr'] > 0 else "-"
                
                is_completed = (w['act_total'] > 0) or (w['sport'] == "Pihenő")
                
                if is_completed:
                    tag = "completed"
                elif w['index'] == self.today_index:
                    tag = "today"
                elif w['index'] < self.today_index:
                    tag = "missed"
                else:
                    tag = "future"

                self.tree.insert("", tk.END, values=(
                    w['day'], w['sport'], f"{w['plan_time']}p", f"{w['plan_dist']} km", w['zone'], w['desc'], act_str, hr_str, w['notes']
                ), tags=(tag,))

    def edit_selected_workout(self, event):
        selected_item = self.tree.selection()
        if not selected_item:
            return
        
        item_values = self.tree.item(selected_item, "values")
        target_week = int(self.week_spin.get())
        day_name = item_values[0]

        workout_obj = None
        for w in self.workouts:
            if w['week'] == target_week and w['day'] == day_name:
                workout_obj = w
                break

        if not workout_obj:
            return

        sport = workout_obj['sport'].lower()

        win = tk.Toplevel(self.root)
        win.title(f"Edzés rögzítése: {target_week}. hét, {day_name} ({workout_obj['sport']})")
        win.geometry("450x420")

        tk.Label(win, text=f"Előírás: {workout_obj['desc']}", wraplength=400, font=("Arial", 9, "italic"), fg="#333").pack(pady=10)

        form_frame = tk.Frame(win)
        form_frame.pack(padx=20, pady=5, fill=tk.BOTH)

        entries = {}
        row_idx = 0

        is_swim = "úszás" in sport
        is_bike = "bringa" in sport or "görgő" in sport or "kerékpár" in sport
        is_run = "futás" in sport
        is_brick = "tégla" in sport or (is_bike and is_run)

        if "pihenő" in sport:
            tk.Label(form_frame, text="Ez egy pihenőnap. Add meg az érzetedet:", anchor="w").grid(row=row_idx, column=0, columnspan=2, sticky="w", pady=2)
            row_idx += 1

        if is_swim or is_brick or ("úszás" in workout_obj['desc'].lower()):
            tk.Label(form_frame, text="Mért Úszás táv (km):", anchor="w").grid(row=row_idx, column=0, sticky="w", pady=2)
            e1 = tk.Entry(form_frame, width=20)
            e1.grid(row=row_idx, column=1, sticky="e", pady=2)
            e1.insert(0, str(workout_obj['act_swim']) if workout_obj['act_swim'] > 0 else "")
            entries['swim_dist'] = e1
            row_idx += 1

            tk.Label(form_frame, text="Úszás tempó (mm:ss / 100m):", anchor="w").grid(row=row_idx, column=0, sticky="w", pady=2)
            e2 = tk.Entry(form_frame, width=20)
            e2.grid(row=row_idx, column=1, sticky="e", pady=2)
            e2.insert(0, workout_obj['swim_pace'])
            entries['swim_pace'] = e2
            row_idx += 1

        if is_bike or is_brick or ("görgő" in workout_obj['desc'].lower() or "bringa" in workout_obj['desc'].lower()):
            tk.Label(form_frame, text="Mért Kerékpár táv (km):", anchor="w").grid(row=row_idx, column=0, sticky="w", pady=2)
            e3 = tk.Entry(form_frame, width=20)
            e3.grid(row=row_idx, column=1, sticky="e", pady=2)
            e3.insert(0, str(workout_obj['act_bike']) if workout_obj['act_bike'] > 0 else "")
            entries['bike_dist'] = e3
            row_idx += 1

            tk.Label(form_frame, text="Kerékpár sebesség (km/h):", anchor="w").grid(row=row_idx, column=0, sticky="w", pady=2)
            e4 = tk.Entry(form_frame, width=20)
            e4.grid(row=row_idx, column=1, sticky="e", pady=2)
            e4.insert(0, str(workout_obj['bike_speed']) if workout_obj['bike_speed'] > 0 else "")
            entries['bike_speed'] = e4
            row_idx += 1

        if is_run or is_brick or ("futás" in workout_obj['desc'].lower()):
            tk.Label(form_frame, text="Mért Futás táv (km):", anchor="w").grid(row=row_idx, column=0, sticky="w", pady=2)
            e5 = tk.Entry(form_frame, width=20)
            e5.grid(row=row_idx, column=1, sticky="e", pady=2)
            e5.insert(0, str(workout_obj['act_run']) if workout_obj['act_run'] > 0 else "")
            entries['run_dist'] = e5
            row_idx += 1

            tk.Label(form_frame, text="Futás tempó (mm:ss / km):", anchor="w").grid(row=row_idx, column=0, sticky="w", pady=2)
            e6 = tk.Entry(form_frame, width=20)
            e6.grid(row=row_idx, column=1, sticky="e", pady=2)
            e6.insert(0, workout_obj['run_pace'])
            entries['run_pace'] = e6
            row_idx += 1

        if not (is_swim or is_bike or is_run or is_brick):
            tk.Label(form_frame, text="Teljesített táv (km):", anchor="w").grid(row=row_idx, column=0, sticky="w", pady=2)
            e_tot = tk.Entry(form_frame, width=20)
            e_tot.grid(row=row_idx, column=1, sticky="e", pady=2)
            e_tot.insert(0, str(workout_obj['act_total']) if workout_obj['act_total'] > 0 else "")
            entries['total_dist'] = e_tot
            row_idx += 1

        tk.Label(form_frame, text="Mért Átlagpulzus (bpm):", anchor="w").grid(row=row_idx, column=0, sticky="w", pady=2)
        e_hr = tk.Entry(form_frame, width=20)
        e_hr.grid(row=row_idx, column=1, sticky="e", pady=2)
        e_hr.insert(0, str(workout_obj['hr']) if workout_obj['hr'] > 0 else "")
        entries['hr'] = e_hr
        row_idx += 1

        tk.Label(form_frame, text="Megjegyzés / RPE (1-10):", anchor="w").grid(row=row_idx, column=0, sticky="w", pady=2)
        e_notes = tk.Entry(form_frame, width=20)
        e_notes.grid(row=row_idx, column=1, sticky="e", pady=2)
        e_notes.insert(0, workout_obj['notes'])
        entries['notes'] = e_notes

        def save_changes():
            try:
                workout_obj['act_swim'] = float(entries['swim_dist'].get().replace(',', '.') or 0) if 'swim_dist' in entries else 0.0
                workout_obj['swim_pace'] = entries['swim_pace'].get() if 'swim_pace' in entries else ""
                
                workout_obj['act_bike'] = float(entries['bike_dist'].get().replace(',', '.') or 0) if 'bike_dist' in entries else 0.0
                workout_obj['bike_speed'] = float(entries['bike_speed'].get().replace(',', '.') or 0) if 'bike_speed' in entries else 0.0
                
                workout_obj['act_run'] = float(entries['run_dist'].get().replace(',', '.') or 0) if 'run_dist' in entries else 0.0
                workout_obj['run_pace'] = entries['run_pace'].get() if 'run_pace' in entries else ""

                if 'total_dist' in entries:
                    workout_obj['act_total'] = float(entries['total_dist'].get().replace(',', '.') or 0)
                else:
                    workout_obj['act_total'] = round(workout_obj['act_swim'] + workout_obj['act_bike'] + workout_obj['act_run'], 2)

                workout_obj['hr'] = int(entries['hr'].get() or 0)
                workout_obj['notes'] = entries['notes'].get()

                save_data(self.workouts, self.header)
                self.load_week_table()
                messagebox.showinfo("Siker", "Edzésadatok sikeresen elmentve!")
                win.destroy()
            except ValueError:
                messagebox.showerror("Hiba", "Kérlek ellenőrizd a számok formátumát (tizedesekhez pontot használj)!")

        tk.Button(win, text="Mentés", command=save_changes, bg="#4CAF50", fg="white", font=("Arial", 10, "bold"), width=15).pack(pady=15)

    def show_block_stats(self):
        stat_win = tk.Toplevel(self.root)
        stat_win.title("5 Hetes Periodizációs Statisztika")
        stat_win.geometry("950x450")

        columns = ("Blokk", "Hetek", "Terv idő(h)", "Terv táv", "Mért táv", "Telj %", "Úszás", "Ú.Tempó", "Bringa", "Br.Seb", "Futás", "F.Tempó")
        tree = ttk.Treeview(stat_win, columns=columns, show="headings", height=12)
        
        for col in columns:
            tree.heading(col, text=col)
            tree.column(col, width=75, anchor=tk.CENTER)
        tree.column("Blokk", width=80, anchor=tk.W)
        tree.column("Hetek", width=90, anchor=tk.W)

        scrollbar = ttk.Scrollbar(stat_win, orient=tk.VERTICAL, command=tree.yview)
        tree.configure(yscrollcommand=scrollbar.set)
        
        tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=10, pady=10)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y, pady=10)

        for b in range(10):
            start_w = b * 5 + 1
            end_w = (b + 1) * 5

            plan_min = sum(w['plan_time'] for w in self.workouts if start_w <= w['week'] <= end_w)
            plan_km = sum(w['plan_dist'] for w in self.workouts if start_w <= w['week'] <= end_w)
            swim_km = sum(w['act_swim'] for w in self.workouts if start_w <= w['week'] <= end_w)
            bike_km = sum(w['act_bike'] for w in self.workouts if start_w <= w['week'] <= end_w)
            run_km = sum(w['act_run'] for w in self.workouts if start_w <= w['week'] <= end_w)
            act_km = swim_km + bike_km + run_km

            pct = (act_km / plan_km * 100) if plan_km > 0 else 0

            swim_secs = [pace_to_seconds(w['swim_pace']) for w in self.workouts if start_w <= w['week'] <= end_w and w['act_swim'] > 0 and pace_to_seconds(w['swim_pace']) > 0]
            avg_swim_pace = seconds_to_pace(sum(swim_secs) / len(swim_secs)) if swim_secs else "-"

            bike_speeds = [w['bike_speed'] for w in self.workouts if start_w <= w['week'] <= end_w and w['bike_speed'] > 0]
            avg_bike_spd = f"{sum(bike_speeds)/len(bike_speeds):.1f}" if bike_speeds else "-"

            run_secs = [pace_to_seconds(w['run_pace']) for w in self.workouts if start_w <= w['week'] <= end_w and w['act_run'] > 0 and pace_to_seconds(w['run_pace']) > 0]
            avg_run_pace = seconds_to_pace(sum(run_secs) / len(run_secs)) if run_secs else "-"

            tree.insert("", tk.END, values=(
                f"{b+1}. Blokk", f"{start_w}-{end_w}. hét", f"{plan_min/60:.1f}h", f"{plan_km:.1f}", f"{act_km:.2f}",
                f"{pct:.1f}%", f"{swim_km:.2f}", avg_swim_pace, f"{bike_km:.2f}", avg_bike_spd, f"{run_km:.2f}", avg_run_pace
            ))

    def show_global_stats(self):
        total_plan_min = sum(w['plan_time'] for w in self.workouts)
        total_plan_km = sum(w['plan_dist'] for w in self.workouts)
        total_act_km = sum(w['act_total'] for w in self.workouts)
        swim_km = sum(w['act_swim'] for w in self.workouts)
        bike_km = sum(w['act_bike'] for w in self.workouts)
        run_km = sum(w['act_run'] for w in self.workouts)
        pct = (total_act_km / total_plan_km * 100) if total_plan_km > 0 else 0

        hrs = [w['hr'] for w in self.workouts if w['hr'] > 0]
        avg_hr = sum(hrs) / len(hrs) if hrs else 0

        stat_text = (
            f"--- IRONMAN 70.3 GLOBÁLIS ÖSSZESÍTŐ ---\n\n"
            f"• Összes tervezett edzésidő: {total_plan_min} perc ({total_plan_min/60:.1f} óra)\n"
            f"• Összes tervezett távolság: {total_plan_km:.1f} km\n\n"
            f"• Összes teljesített táv: {total_act_km:.2f} km ({pct:.2f}%)\n"
            f"  - Úszás: {swim_km:.2f} km\n"
            f"  - Kerékpár / Görgő: {bike_km:.2f} km\n"
            f"  - Futás: {run_km:.2f} km\n\n"
            f"• Átlagosan mért pulzus: {avg_hr:.1f} bpm ({len(hrs)} rögzített edzés alapján)\n"
        )
        messagebox.showinfo("Globális Összesítő", stat_text)

if __name__ == "__main__":
    root = tk.Tk()
    app = IronmanApp(root)
    root.mainloop()