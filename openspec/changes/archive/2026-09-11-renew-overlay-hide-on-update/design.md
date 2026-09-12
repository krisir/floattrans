## Context

See proposal.md. Updating an existing overlay replaces its content view but returns without recreating `hideTask`, so a late correction can vanish immediately.

## Goals / Non-Goals

**Goals:**
- A content update starts a fresh hide duration from the moment the new text appears.

**Non-Goals:**
- Changing hide-after bounds, never-hide, or overlay stacking.

## Decisions

### D1: Cancel and restart the hide task on update

On the existing-entry path in `OverlayCoordinator.show`, cancel `hideTask` and, unless never-hide is on, schedule a new sleep using the current `hideAfter`.

**Alternative considered:** Only extend remaining time. Rejected: the user-visible contract is a full hide duration after the text they just saw.

## Risks / Trade-offs

- [Rapid corrections keep the overlay visible longer] → Intended; each update is a new result.

## Migration Plan

No persisted settings changes.

## Open Questions

None.
