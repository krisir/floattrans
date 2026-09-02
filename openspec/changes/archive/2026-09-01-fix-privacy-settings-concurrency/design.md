## Context

The current Accessibility monitor polls through a timer and obtains the focused application's snapshot before the higher-level translation flow applies exclusions. Translation speed is held in runtime state even though the settings model already persists other user preferences. See proposal.md and the existing `settings` specification for the required behavior.

## Goals / Non-Goals

**Goals:**

- Make the excluded-application check the first gate before any Accessibility text request.
- Store and restore the existing three-way translation speed without changing its user-facing values or default.
- Make timer-triggered snapshot reads explicitly compatible with main-actor isolation.
- Preserve current settings migration behavior and keep the change testable without requiring live Accessibility permission.

**Non-Goals:**

- Redesigning the settings UI or changing translation algorithms.
- Adding new privacy controls or changing the meaning of an excluded application.
- Replacing the timer/polling architecture or adding third-party dependencies.

## Decisions

1. **Gate on the active application's bundle ID inside the Accessibility monitor.** The monitor will identify the focused application and compare its bundle ID against the current excluded set before requesting the focused element value. This keeps the privacy guarantee at the point where data enters the process. Checking only in the coordinator was rejected because it is too late and allows reads to occur.

2. **Persist the delay through the existing settings store.** The persisted representation will remain the delay value already used by runtime state, with validation against the supported speed options and the existing fallback default. Storing only a UI label was rejected because labels are localized and can change.

3. **Schedule main-actor work explicitly.** The timer callback will dispatch snapshot work through the main actor (or use a main-actor-bound timer API) and retain cancellation/invalidation behavior. Making the whole monitor nonisolated was rejected because its AppKit/Accessibility state and callbacks are already main-thread-oriented.

4. **Test at the boundaries.** Add settings-store coverage for speed round trips and monitor/coordinator coverage proving an excluded app short-circuits before text access. Build with the project’s current Swift settings and require the existing actor-isolation warning to disappear.

## Risks / Trade-offs

- [Risk] A stale excluded-app set could briefly allow processing after the user changes privacy settings → update the monitor’s exclusion set synchronously with the settings change before the next poll.
- [Risk] Persisted delay values from older or manually corrupted preferences may be unsupported → normalize them to the nearest supported/default value when loading.
- [Risk] Dispatching timer work asynchronously can allow overlapping polls → keep the existing in-flight/coalescing guard and invalidate pending work on stop.

## Migration Plan

Read the existing speed preference if present and normalize it; otherwise retain the current default. No schema migration or destructive data operation is required. If a build must be rolled back, the new code can be reverted while existing preference keys remain readable.
