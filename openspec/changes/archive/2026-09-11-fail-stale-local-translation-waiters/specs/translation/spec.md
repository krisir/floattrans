## ADDED Requirements

### Requirement: Translation sessions reject obsolete language-pair work

When the selected source or target language changes, local translation work waiting for the previous language pair MUST be cancelled or fail promptly with an unavailable or cancelled error. A session attached for a newly selected pair MUST resume only requests for that same pair. Obsolete requests MUST NOT receive a translation from the new pair or remain blocked until the local-session readiness timeout.

#### Scenario: Direction changes while local session is unavailable
- **WHEN** a request for one language pair is waiting for a local translation session and the user changes direction
- **THEN** the old request finishes without a result promptly and the new direction can establish its own session

#### Scenario: New session does not satisfy old request
- **WHEN** a local session attaches after the user changed to another language pair
- **THEN** only requests for the newly configured pair use that session
