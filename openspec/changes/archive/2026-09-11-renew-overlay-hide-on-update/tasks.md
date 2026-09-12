## 1. Renew hide timer

- [x] 1.1 When updating an existing overlay's text, cancel its hide task and start a new one using the current hide-after setting.
- [x] 1.2 Leave never-hide overlays without an auto-hide task.
- [x] 1.3 Add a focused test that a content update restarts the hide duration.

## 2. Verification

- [x] 2.1 Run the overlay tests and the full Swift test suite.
- [x] 2.2 Manually verify a corrected translation stays visible for the full hide duration after the update.
