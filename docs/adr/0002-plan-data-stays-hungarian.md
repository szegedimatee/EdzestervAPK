# Plan data stays Hungarian, separate from the UI language

The Plan CSV (`assets/edzesterv_adatbazis.csv`) uses Hungarian headers and Sport values (`Úszás`, `Tégla (Brick)`, `Pihenő`), and the code detects a Workout's Sport by matching them. When UI text moved to `lib/strings.dart` to allow a future language switch, we kept these values Hungarian in a separate `PlanTerms` class instead of translating the CSV: translating would have to change the data file and every matcher in lockstep for no user-visible gain, and the strings in `PlanTerms` must never change with the UI language.

## Consequences

Adding a UI language touches `S` only. Changing a Sport name in the CSV requires the matching `PlanTerms` entry to change too, or that Sport silently stops being detected.
