# Log Entries are keyed by Week and day, not CSV row

Each Log Entry is saved on the phone under `w_<week>_<day>` (e.g. `w_12_Kedd`). It used to be `w_<row index>`, which silently attached every entry to the wrong Workout as soon as a row was added to or reordered in the Plan CSV. Week + day is unique in the Plan and survives edits to it. We kept the athlete's existing Log rather than resetting it: on load, an entry missing under the new key is copied over from its old `w_<index>` key.

## Consequences

The key is the only link between a Log Entry and its Workout, and the Log exists only on the athlete's phone. Renaming a key, or a day name in the CSV, orphans that data with no error. Any key change needs a load-time migration like this one.
