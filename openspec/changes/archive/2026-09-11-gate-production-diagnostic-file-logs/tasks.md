## 1. Gate file diagnostics

- [x] 1.1 Stop writing `/tmp/liveenglish-debug.log` in Release builds (Debug-only or explicit debug flag).
- [x] 1.2 Keep OSLog for routine diagnostics; if file logging is enabled, serialize writes and cap or rotate the file.
- [x] 1.3 Confirm input polling no longer opens the debug file on the hot path in Release.

## 2. Verification

- [x] 2.1 Run the full Swift test suite.
- [x] 2.2 Confirm a Release-like run does not create or grow `/tmp/liveenglish-debug.log`.
