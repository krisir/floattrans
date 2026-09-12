## Context

See proposal.md. Input monitoring always assigns `NSScreen.main`, so an overlay for typing on a secondary display can appear on the main display.

## Goals / Non-Goals

**Goals:**
- Present live translation overlays on the display that contains the focused input.

**Non-Goals:**
- Changing overlay position-within-screen (右上 / 底部居中 / 右下).
- Moving the Settings preview overlay off the main screen.

## Decisions

### D1: Resolve screen from focused geometry, then mouse

Prefer the `NSScreen` containing the focused element's window frame. If that frame is missing, use the screen containing the mouse location. Fall back to `NSScreen.main` only when neither is usable.

**Alternative considered:** Always use mouse location. Rejected: the caret can be on a different display from the pointer.

## Risks / Trade-offs

- [Some AX hosts expose no window frame] → Mouse, then main-screen fallback.

## Migration Plan

No persisted settings changes.

## Open Questions

None.
