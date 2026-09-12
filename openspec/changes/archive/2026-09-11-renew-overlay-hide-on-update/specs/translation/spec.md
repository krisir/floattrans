## ADDED Requirements

### Requirement: Overlay content updates renew the hide duration

When an accepted translation updates an existing overlay, the overlay SHALL remain visible for a full configured hide duration starting from that update. When never-hide is on, the overlay SHALL still not auto-hide.

#### Scenario: Corrected translation renews hide duration
- **WHEN** a visible overlay is updated with a corrected translation before its current hide timer expires
- **THEN** it remains visible for the configured duration after the corrected text appears
