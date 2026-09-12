## 1. Invalidate waiters

- [x] 1.1 Tag local translation waiters with a language-pair configuration generation.
- [x] 1.2 Fail or remove obsolete waiters immediately when direction changes, and resume only matching waiters on session attach.
- [x] 1.3 Add tests for changing direction while the local session is unavailable, and for an old request not using a new language session.

## 2. Verification

- [x] 2.1 Run the local-session tests and the full Swift test suite.
