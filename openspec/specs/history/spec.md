## Purpose

Defines how 浮译 stores completed translations on this Mac: the retention options including Do Not Record, when new rows are written, and how the user permanently deletes saved history.

## Requirements

### Requirement: Retention includes a Do Not Record option

History retention SHALL include 不记录 / Do Not Record in addition to the existing timed and forever options. All visible labels SHALL follow the selected interface language.

#### Scenario: Do Not Record is available
- **WHEN** the user views the History retention options
- **THEN** 不记录 is listed when the interface language is 中文, or Do Not Record when it is English, alongside 1 day, 7 days, 30 days, 6 months, and forever

### Requirement: Do Not Record does not save new translations

When retention is Do Not Record, a completed translation SHALL NOT be written to the local history store. Existing records SHALL remain until the user deletes them. Overlay, speech, replace, and copy behavior SHALL NOT depend on history being recorded.

#### Scenario: New translation is not stored
- **WHEN** retention is Do Not Record and a translation completes
- **THEN** no new history row is created for that translation

#### Scenario: Existing records stay until deleted
- **WHEN** retention is changed to Do Not Record and history already contains rows
- **THEN** those rows remain visible until the user confirms delete-all

#### Scenario: Timed retention still records
- **WHEN** retention is 1 day, 7 days, 30 days, 6 months, or forever and a translation completes
- **THEN** that translation is stored locally and older rows are pruned according to the selected retention

### Requirement: History retention defaults to Do Not Record

Fresh installs and installs with no stored retention value SHALL default to Do Not Record. An existing stored retention SHALL be kept and SHALL NOT be overwritten on upgrade.

#### Scenario: Fresh install
- **WHEN** no prior history-retention setting exists
- **THEN** retention is Do Not Record and new translations are not stored

#### Scenario: Existing stored retention is kept
- **WHEN** an existing install already has a stored retention other than Do Not Record
- **THEN** that stored value is used and new translations continue to be recorded under it

### Requirement: User can delete all history after confirmation

The system SHALL provide a delete-all action for local translation history. Activating it SHALL show a confirmation dialog. Confirming SHALL delete every stored history row. Canceling SHALL leave all rows unchanged. The action SHALL follow the selected interface language. When there are no rows, the action SHALL be unavailable.

#### Scenario: Confirm deletes every row
- **WHEN** history contains one or more rows and the user confirms delete-all
- **THEN** the store contains no history rows and the History page shows the empty state

#### Scenario: Cancel keeps every row
- **WHEN** history contains rows and the user cancels the delete confirmation
- **THEN** every previously stored row remains

#### Scenario: Delete is unavailable when empty
- **WHEN** history contains no rows
- **THEN** the delete-all action cannot be activated

### Requirement: History mutations honor user-visible order

The history controller SHALL apply reload, recording, and confirmed delete-all operations in a well-defined order. A confirmed delete-all establishes a boundary: work requested before that confirmation MUST NOT insert a row afterward or republish stale rows into the History page. A translation accepted after that boundary may be recorded according to the selected retention setting.

#### Scenario: Delete wins over queued record
- **WHEN** a translation record operation is queued, the user confirms Delete History before that operation is applied, and no later translation is accepted
- **THEN** the store remains empty and the History page shows the empty state

#### Scenario: Stale reload does not restore rows
- **WHEN** a reload started before the user confirms Delete History completes after deletion
- **THEN** it does not republish the pre-delete entries
