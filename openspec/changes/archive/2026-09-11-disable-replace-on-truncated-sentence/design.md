## Context

See proposal.md. `SentenceExtractor.extract` keeps only the last 300 characters. `FieldReplacement` then searches for that suffix, so Replace Original rewrites only the tail of a long sentence.

## Goals / Non-Goals

**Goals:**
- Truncated sources may still be translated, shown, and copied.
- Truncated sources MUST NOT become a replace payload.

**Non-Goals:**
- Raising the 300-character translation request limit.
- Translating the unsent prefix in a second request.

## Decisions

### D1: Disable replace when extraction truncated

Keep a `wasTruncated` flag on the extracted source. Display and Copy Translation still work. Drop the replacement payload so the replace shortcut is a no-op for that result.

**Alternative considered:** Keep the full original range and only truncate the string sent to the translation service. Rejected for replace: the translation would not correspond to the full range, so a successful write would still drop or mix the unsent prefix.

## Risks / Trade-offs

- [Users cannot replace very long sentences] → Safer than mixing languages; they can still copy the translation.

## Migration Plan

No persisted data changes.

## Open Questions

None.
