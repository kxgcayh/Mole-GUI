# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-09-15

### Added
- **Visual Disk Treemap Explorer (`/analyze`)**:
  - Squarified proportional interactive treemap canvas with custom macOS color palette.
  - Interactive drill-down directory navigation with dynamic breadcrumbs.
  - Multi-threaded disk scanning with accurate byte aggregation.
  - Right-click context menu offering **Reveal in Finder** and **Move to Trash**.
- **Live System & Hardware Telemetry**:
  - Hardware gauges for CPU load (User % vs System %), RAM breakdown following Apple Activity Monitor metrics (*App Memory*, *Wired*, *Compressed*, and *Cached Files*), and APFS disk utilization.
  - Dynamic Battery gauge with automatic hardware detection (hidden on desktop Macs without batteries).
  - System activity telemetry with `1m`, `5m`, and `15m` load average badges, active task counts, running processes, and kernel thread counters.
  - Cumulative network inbound/outbound I/O and disk transfer read/write metrics.
  - Real-time ranked Top 4 Active Processes list monitoring CPU % and RAM % consumption.
- **Deep System Cleanup (`/cleaner`)**:
  - System cache, user cache, logs, diagnostic reports, and Trash bin cleaner.
  - Dry-run mode with granular category selection and preview.
- **App Uninstaller & Remnant Hunter (`/uninstaller`)**:
  - App scanning with exact disk footprints and metadata.
  - Residual leftover scanner for `~/Library/Application Support`, `~/Library/Caches`, and `~/Library/Preferences`.
- **Developer Project Build Purger (`/projects`)**:
  - Batch scanner for build folders (`node_modules`, `.dart_tool`, `build/`, `target/`, `.gradle/`).
- **System Maintenance & Optimizer (`/maintenance`)**:
  - DNS cache flush, Spotlight re-indexing, RAM purge, and disk repair with live terminal output streaming.
- **Onboarding & Setup Middleware (`/setup`)**:
  - Automatic detection of Homebrew and Mole CLI engine.
  - 1-click automatic Homebrew install, curl fallback, copy-paste terminal commands, and GUI-only bypass.
- **Packaging & Build Tooling**:
  - Automated `./tool/build_dmg.sh` script to generate release DMG installers.
  - Custom macOS App Icon (`.icns` / `.appiconset`) and volume branding.
  - Applications drag-and-drop link with custom Finder window positioning.
  - Native macOS minimum window constraint (`960x600`) in `MainFlutterWindow.swift`.

### Changed
- Refactored CLI bridge service to prioritize global Homebrew executable resolution (`/opt/homebrew/bin/mole`, `/usr/local/bin/mole`).
- Enhanced dashboard responsive layout to dynamically switch between multi-column and single-column modes without UI overflow.
- Updated app display name and metadata to **Mole GUI**.
- Upgraded state management to Riverpod 3.x `Notifier` patterns with safe mounted guards.

### Security
- Verified sandboxing and execution permission handlers for macOS shell command bridges.
- Ensured destructive cleaning actions require explicit user confirmation.
