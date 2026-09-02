## Purpose

Defines 浮译's application visual identity: the macOS app icon shown in Dock, Finder, and About, derived from the Tabler Icons `brand-tailwind` mark.

## ADDED Requirements

### Requirement: Application icon uses Tabler brand-tailwind mark

The shipped macOS application icon SHALL be derived from the Tabler Icons outline `brand-tailwind` artwork. The icon SHALL present a light-colored mark on a teal / Tailwind-style rounded square suitable for Dock and Finder. The About surface that displays the app icon SHALL show this same application icon when the app is built with the bundled AppIcon asset catalog.

#### Scenario: Dock and Finder show the new icon
- **WHEN** the user installs or launches a build that includes the updated AppIcon asset catalog
- **THEN** Dock and Finder show the teal rounded-square icon with the brand-tailwind mark instead of the previous chat-bubble translation artwork

#### Scenario: About shows the application icon
- **WHEN** the user opens the Settings About tab in a build that includes the updated AppIcon
- **THEN** the page shows the same application icon used by Dock and Finder
