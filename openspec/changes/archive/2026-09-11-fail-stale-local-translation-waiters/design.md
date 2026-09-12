## Context

See proposal.md. `TranslationSessionHolder.configure` drops the session but leaves `waiters`. The next `attach` resumes them on the new pair, or they sit until the 8s timeout.

## Goals / Non-Goals

**Goals:**
- Fail obsolete waiters immediately on language-pair change.
- Resume only waiters that match the attached pair/generation.

**Non-Goals:**
- Changing TranslationSession APIs, LLM routing, or the 8s timeout for a still-valid current pair.

## Decisions

### D1: Tag waiters with a configuration generation

Associate each waiter with the language-pair generation that created it. On `configure`, resume old waiters immediately with `TranslationSessionError.unavailable`. On `attach`, resume only matching-generation waiters.

**Alternative considered:** Key waiters by `(source, target)` only. A generation counter is simpler when configure/attach interleave on the same pair.

## Risks / Trade-offs

- [In-flight local requests fail on direction change] → Correct; the result would be the wrong pair.

## Migration Plan

No persisted data changes.

## Open Questions

None.
