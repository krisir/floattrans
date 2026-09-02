## Purpose

Defines how 浮译 is packaged for installation on macOS: on-disk bundle and executable identity, drag-to-Applications disk images, and code signing plus notarization for distribution outside the App Store.

## Requirements

### Requirement: Packaged app uses English on-disk names

The shipped application bundle SHALL be named `FloatTrans.app`. The Mach-O executable inside the bundle SHALL be named `FloatTrans` and SHALL match `CFBundleExecutable`. User-visible product strings (`CFBundleDisplayName` and `CFBundleName`) SHALL remain 浮译. The Swift source module name is not part of this contract.

#### Scenario: Finder shows the English bundle filename
- **WHEN** a user mounts a release disk image or copies the packaged app into Applications
- **THEN** the application item is named `FloatTrans.app` (Finder may hide the `.app` extension) and is not named `LiveEnglish.app` or `浮译.app`

#### Scenario: Launch uses the FloatTrans executable
- **WHEN** the user opens the packaged app
- **THEN** macOS launches the `FloatTrans` executable declared by `CFBundleExecutable` and the app starts instead of failing because the executable name does not match the Info.plist

#### Scenario: UI still shows 浮译
- **WHEN** the packaged app is running
- **THEN** system and in-app display names that use `CFBundleDisplayName` / `CFBundleName` remain 浮译

### Requirement: Release disk image supports drag-to-Applications install

A release disk image SHALL contain the packaged `FloatTrans.app` and an Applications drop link. Opening the image SHALL present a Finder window suitable for dragging the app onto Applications. The image SHALL NOT include source trees, build artifacts, or other repository files.

#### Scenario: User installs from the disk image
- **WHEN** the user opens the release disk image
- **THEN** they see `FloatTrans.app` and an Applications shortcut and can copy the app into Applications by dragging

#### Scenario: Disk image contains only install payload
- **WHEN** a release disk image is created from a successful app package
- **THEN** the volume does not contain project source, `.build`, tests, or documentation folders from the repository

### Requirement: Local builds remain ad-hoc signed

A default local package build SHALL produce a runnable `.app` signed with an ad-hoc identity so the developer can launch it on the build machine without a Developer ID certificate.

#### Scenario: Developer builds without a Developer ID
- **WHEN** the developer runs the app packaging script with no Developer ID identity configured
- **THEN** the resulting `FloatTrans.app` is ad-hoc signed and can be opened on that Mac

### Requirement: Outside-App-Store builds use Developer ID, Hardened Runtime, and notarization

When distributing a disk image for other Macs outside the App Store, the packaged app SHALL be signed with a Developer ID Application identity, Hardened Runtime, and a secure timestamp. The disk image SHALL be submitted for Apple notarization and, after an Accepted result, SHALL have the notarization ticket stapled so Gatekeeper can verify it without a network lookup.

#### Scenario: Notarized disk image opens under Gatekeeper
- **WHEN** a user downloads a stapled, notarized release disk image and opens it on a Mac with Gatekeeper enabled
- **THEN** Gatekeeper does not block the image solely for lacking Developer ID or notarization, and the user can drag `FloatTrans.app` into Applications and launch it without using Open Anyway as the only path

#### Scenario: Signing identity is present for a public build
- **WHEN** a Developer ID Application identity is configured for the release build
- **THEN** `FloatTrans.app` is signed with that identity, Hardened Runtime, and a timestamp before the disk image is created

#### Scenario: Notarization is skipped without credentials
- **WHEN** a disk image is built and no notarization credentials are configured
- **THEN** the build still produces a disk image from the signed app, and it does not claim to be notarized
