## Context

See proposal.md. Extraction returns a string; `InputCoordinator` and `FieldReplacement` rediscover it with `NSString.range(of:options: .backwards)`, so duplicates resolve to the last occurrence.

## Goals / Non-Goals

**Goals:**
- Replace only the caret-captured occurrence after validating that UTF-16 range still matches.

**Non-Goals:**
- Changing when translation starts, automatic replacement, or AX write success in hosts that reject it.

## Decisions

### D1: Carry the captured UTF-16 range with the source

Introduce a value that keeps source text and its exact UTF-16 range in the observed field. Use that range as identity from extract → pending action → replace. Before writing, re-read the focused field and require the substring at that range to equal the captured source. Do not scan backward as a fallback.

**Alternative considered:** Search forward from the caret instead of backwards. Still ambiguous when the same sentence appears nearby; an explicit range is the only stable identity.

## Risks / Trade-offs

- [Some AX hosts report invalid ranges] → Validate bounds and content, then leave text untouched.

## Migration Plan

No persisted data changes. Rollback keeps the new range-bearing types unused.

## Open Questions

None.
