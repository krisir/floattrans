## Context

See proposal.md for motivation. Specs: `specs/history/spec.md` (Do Not Record, skip-on-record, default, confirmed delete-all) and `specs/settings/spec.md` (History page picker and delete UI, persist/migrate).

Today `HistoryRetention` is `1d` / `7d` / `30d` / `6mo` / `forever`. `SettingsStore` falls back to `.sevenDays` when the UserDefaults key is missing, and writes that value on first launch. `TranslationHistoryStore.recordAndLoad` always INSERTs a completed translation, then prunes by cutoff. There is no delete-all API. The History page (`SettingsUI.swift`) has the retention picker, a local-only hint, and an export menu.

## Goals / Non-Goals

**Goals:**

- Extend retention with a first-class Do Not Record case that skips INSERT and does not age-prune existing rows.
- Factory-default missing/`nil` retention to Do Not Record without rewriting an already stored value.
- Add store + controller delete-all, wired to a destructive confirmation dialog on the History page.

**Non-Goals:**

- Per-row delete, search, or edit.
- Auto-deleting existing rows when the user switches to Do Not Record.
- Changing export, SQLite schema, or overlay/speech/replace/copy.
- Forcing existing installs that already stored `7d` (or another value) onto Do Not Record.

## Decisions

### 1. Add `HistoryRetention.none` (`rawValue: "none"`) as the first case

Put `none` first in `CaseIterable` so the picker lists 不记录 / Do Not Record above the timed options. `cutoffDate` returns `nil` (same as `.forever`) so `prune` is a no-op and switching to Do Not Record does not wipe rows.

**Alternatives considered:** A separate boolean `recordHistory` (two settings, easy to desync from retention). Treating Do Not Record as `cutoffDate = now` (would auto-delete on load, against the spec).

### 2. Skip INSERT inside the store; App still calls `record`

`recordAndLoad` returns `load(...)` without INSERT when retention is `.none`. `App.swift` can keep calling `history.record(...)` so overlay/speech/actions stay on the same path. Defense in depth: empty/whitespace skip already exists; `.none` is another early return.

**Alternatives considered:** Guard only in `App.swift` (easy to miss a future caller). Drop the SQLite file while Do Not Record is on (destructive, loses unread rows).

### 3. Missing UserDefaults key → `.none`; stored keys stay

Change the fallback from `.sevenDays` to `.none`. Keep the existing “write key if missing” so a fresh default is persisted as `"none"`. Do not migrate `"7d"` / `"30d"` / etc. Almost every install that has launched already has `historyRetention` written; those users keep recording until they pick 不记录 or delete.

Unknown/corrupt raw values also fall back to `.none` (safer than resuming recording).

**Alternatives considered:** Force every install to `"none"` on upgrade (spec forbids overwriting a stored value). Leave the 7-day factory default (does not match the requested default).

### 4. Delete-all is `DELETE FROM translation_history`, then reload

Add `TranslationHistoryStore.deleteAll()` and `TranslationHistoryController.deleteAll()`. No schema change. No `VACUUM` in v1 (history DBs are small; reclaiming pages is out of scope). After success, `entries` is `[]` so the empty state and disabled delete button appear immediately.

**Alternatives considered:** Delete the `.sqlite` file and reopen (more failure modes, WAL/SHM leftovers). Per-row delete (out of scope).

### 5. SwiftUI `confirmationDialog` with a destructive confirm role

Place **删除历史记录 / Delete History** on the History page next to the existing export menu. Use `.confirmationDialog` (title + message + Cancel + destructive Confirm). Disable the button when `history.entries.isEmpty`. Strings live in `L10n` for 中文 / English.

**Alternatives considered:** `NSAlert` (more AppKit, no benefit here). Delete without a dialog (spec requires confirmation).

## Risks / Trade-offs

- [Existing installs keep 7-day recording] → Mitigation: documented; only missing keys default to Do Not Record. Users who want opt-out pick 不记录 and can delete.
- [Do Not Record leaves old rows on disk] → Mitigation: spec’d; delete-all is the wipe path. Empty-state copy still applies when rows exist.
- [Delete-all is irreversible] → Mitigation: confirmation dialog; Cancel is a no-op.
- [SQLite DELETE does not zero freed pages] → Mitigation: accepted for v1; no VACUUM/secure-delete.

## Migration Plan

Ship the new enum case, default, skip-on-record, and delete UI together. Rollback is revert: unknown `"none"` values would currently fall back to 7 days on an old binary, so a rollback after users saved `"none"` would start recording again until they upgrade. If a rollback is needed after release, treat that as a known behavior change.

## Open Questions

None.
