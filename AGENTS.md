# EdzestervAPK

Flutter Android app: an Ironman 70.3 training plan and log, built from a CSV plan.

## Ownership

The GitHub repo belongs to `szegedimatee`; this user is a collaborator. Ask before any outward action: pushing, opening or commenting on issues and PRs, changing labels.

## Language

Write all code and comments in English: identifiers, comments, commit messages, issue and PR text. This holds whatever language the user speaks in the harness; a Hungarian prompt still gets English code. Translate an existing Hungarian comment to English when you touch it.

The app's UI language is Hungarian. Put every user-facing string in `lib/strings.dart` as an `S.<key>` and reference it from the code. Values that must match `assets/edzesterv_adatbazis.csv` (sport names, rest day) live in `PlanTerms` and stay Hungarian whatever the UI language.

## Code map

`lib/main.dart` holds the whole app; `grep -n '^class ' lib/main.dart` lists its screens. `_WorkoutHomeScreenState` (~1000 lines) owns all state: CSV loading, persistence, notification scheduling, the workout log sheet and the race countdown.

SharedPreferences keys (`w_<week>_<day>`, `race1_*`, `notif_*`, `gear_*`) hold the user's real training log on their phone. Keep them stable; a renamed key silently erases that data. When a key must change, migrate the old one as the `w_<index>` → `w_<week>_<day>` migration does.

## Verification

There are no tests yet: `flutter analyze` is the only automated check, so run it after every change and report exactly that. CI fails on analyzer errors and warnings; infos pass. `flutter build apk` needs the Android SDK; when it is missing locally, CI builds the APK on every push to `main`.

CI pins Flutter `3.47.7` in `.github/workflows/build.yml`; keep the local version in step.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `szegedimatee/EdzestervAPK` (via `gh`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
