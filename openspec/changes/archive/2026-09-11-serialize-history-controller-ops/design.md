## Context

See proposal.md. `TranslationHistoryController.reload` / `record` / `deleteAll` each start an independent `Task` with no generation token, so a queued record can resurrect rows after delete-all.

## Goals / Non-Goals

**Goals:**
- User-visible history operations apply in order.
- A confirmed delete-all is a boundary that older writes cannot cross.

**Non-Goals:**
- Changing retention options, the SQLite schema, or when a translation is eligible to record.

## Decisions

### D1: Serialize commands and bump a generation on delete

Put reload, record, and delete-all behind one controller-owned queue or actor. Delete increments a mutation generation; records and reloads started before that generation cannot insert or publish afterward. Keep SQLite work actor-isolated; apply UI updates only for the current generation.

**Alternative considered:** Cancel the previous `Task` on each call. Cancellation does not stop a store write that already started, so a generation boundary is still required.

## Risks / Trade-offs

- [Operations run strictly in order] → User-visible state stays predictable; store operations are already small.

## Migration Plan

No database migration.

## Open Questions

None.
