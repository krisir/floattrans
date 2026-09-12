## 1. Serialize history ops

- [x] 1.1 Serialize reload, record, and delete-all controller operations with a mutation generation or command queue.
- [x] 1.2 Ensure Delete History leaves both store and UI empty despite any record or reload queued beforehand.
- [x] 1.3 Add deterministic race tests for delete-after-record scheduling and stale reload publication.

## 2. Verification

- [x] 2.1 Run the history tests and the full Swift test suite.
- [x] 2.2 Manually verify clearing history stays empty after in-flight translation work completes.
