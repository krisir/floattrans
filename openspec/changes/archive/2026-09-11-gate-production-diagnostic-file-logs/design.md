## Context

See proposal.md. `DiagnosticLog.write` synchronously appends `/tmp/liveenglish-debug.log` on the input polling path in all builds, with no rotation or debug gate.

## Goals / Non-Goals

**Goals:**
- Release builds must not pay unbounded file I/O for diagnostics.
- Keep OSLog for routine diagnostics.

**Non-Goals:**
- Remote telemetry, changing what text is sent to translation providers, or a user-facing Settings toggle unless needed for Debug.

## Decisions

### D1: Compile file logging out of Release; keep OSLog

Wrap file writes in `#if DEBUG` (or an equivalent explicit debug flag). Existing `Logger` / OSLog calls stay. If file logging is enabled, serialize writes off the 0.5s input path and cap or rotate the file.

**Alternative considered:** Always-on async `/tmp` writes. Rejected: production still grows an unbounded file.

## Risks / Trade-offs

- [Release builds lose always-on `/tmp` files] → OSLog remains available for Console.app.

## Migration Plan

Delete or ignore any existing `/tmp/liveenglish-debug.log`; no app data migration.

## Open Questions

None.
