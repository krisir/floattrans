## ADDED Requirements

### Requirement: History mutations honor user-visible order

The history controller SHALL apply reload, recording, and confirmed delete-all operations in a well-defined order. A confirmed delete-all establishes a boundary: work requested before that confirmation MUST NOT insert a row afterward or republish stale rows into the History page. A translation accepted after that boundary may be recorded according to the selected retention setting.

#### Scenario: Delete wins over queued record
- **WHEN** a translation record operation is queued, the user confirms Delete History before that operation is applied, and no later translation is accepted
- **THEN** the store remains empty and the History page shows the empty state

#### Scenario: Stale reload does not restore rows
- **WHEN** a reload started before the user confirms Delete History completes after deletion
- **THEN** it does not republish the pre-delete entries
