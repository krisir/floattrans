## 1. Resolve active display

- [x] 1.1 Resolve the overlay screen from the focused input window frame, then mouse location, then `NSScreen.main`.
- [x] 1.2 Pass that screen through the input snapshot path instead of always binding `NSScreen.main`.
- [x] 1.3 Add a focused test for screen resolution; keep Settings preview on the main display.

## 2. Verification

- [x] 2.1 Run the focused tests and the full Swift test suite.
- [x] 2.2 Manually verify typing on a secondary display shows the overlay on that display.
