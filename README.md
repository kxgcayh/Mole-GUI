# 🐹 Mole GUI

<div align="center">

**A sleek, native macOS GUI for the [Mole CLI](https://github.com/tw93/mole) toolkit.**  
*Deep system cleanup, interactive visual disk exploration, leftover hunting, and real-time hardware telemetry.*

[![Platform](https://img.shields.io/badge/Platform-macOS_11.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com/macos)
[![Flutter](https://img.shields.io/badge/Built_with-Flutter_3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Riverpod_3.x-546E7A?style=for-the-badge)](https://riverpod.dev)
[![Mole CLI](https://img.shields.io/badge/Powered_by-Mole_CLI_(tw93)-FF6F00?style=for-the-badge&logo=gnubash&logoColor=white)](https://github.com/tw93/mole)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## 💡 About

**Mole GUI** is a native macOS application designed to bring the speed and depth of the popular open-source [**`mole`**](https://github.com/tw93/mole) CLI toolkit (created by [@tw93](https://github.com/tw93)) into an intuitive, modern desktop experience.

While the original `mole` command-line utility provides powerful system cleaning, residual file uninstallation, and developer artifact purging directly in the terminal, **Mole GUI** layers on top:
* A modern **macOS dark glassmorphic UI**.
* **Interactive visual disk treemaps** for visual storage analysis.
* **Real-time live hardware & performance telemetry** (CPU load, Apple Activity Monitor RAM metrics, network throughput, disk transfers, and top active processes).
* **1-click maintenance tasks** with live streaming terminal logs.

---

## ✨ Features

### 📊 Real-Time Hardware & System Telemetry
* **Hardware Gauges**: Live CPU load (User % vs. System %), RAM breakdown following Apple Activity Monitor metrics (*App Memory*, *Wired*, *Compressed*, and *Cached Files*), and dynamic Battery monitoring (automatically hidden on desktop Macs).
* **System Activity & Load**: 1m, 5m, and 15m load average badges, total tasks, running processes, and kernel thread counters.
* **Network & Disk I/O**: Live cumulative network inbound/outbound throughput and disk read/write transfer statistics.
* **Top Active Processes**: Real-time ranked list of top resource-consuming processes by CPU % and RAM % with PID tracking.

### 🗺️ Visual Disk Explorer (Analyze)
* **Squarified Treemap Visualization**: Visually explore your storage drives or home directory to pinpoint space hogs.
* **Interactive Drill-Down**: Click directories to zoom in, navigate via the breadcrumb header, and reveal parent hierarchies.
* **Finder Integration**: Right-click any file or directory chunk to instantly **Reveal in Finder** or **Move to Trash**.

### 🧹 Deep System Cleaner
* Powered by [Mole CLI](https://github.com/tw93/mole) to clean system & user caches, system logs, diagnostic reports, old downloads, and the Trash bin.
* Safe dry-run previews with granular category toggles.

### 📦 App Uninstaller & Remnant Hunter
* Inspect installed applications with exact install size and binary metadata.
* Scrub hidden application leftovers in `~/Library/Application Support`, `~/Library/Caches`, and `~/Library/Preferences`.

### 🛠️ Developer Project Purger
* Scan for orphaned development build artifacts across your projects (`node_modules`, `.dart_tool`, `build/`, `target/`, `.gradle/`).
* Free up tens of gigabytes with batch safe cleaning.

### ⚡ System Maintenance & Optimizer
* Flush macOS DNS cache, trigger Spotlight re-indexing, execute memory purges, and repair disk permissions with real-time output terminal streaming.

### 🚀 Onboarding & Prerequisite Middleware
* Automatic Homebrew and CLI engine detection.
* Integrated 1-click installer and copy-paste fallback for fresh macOS environments.

---

## 📥 Installation

### Option 1: Download DMG Installer (Recommended)
1. Download the latest `Mole-GUI.dmg` from the Releases page (or build locally using `./tool/build_dmg.sh`).
2. Open the `.dmg` file and drag **Mole GUI** into your **Applications** folder.
3. Launch **Mole GUI** from Launchpad or Spotlight.

### Option 2: Install Mole CLI via Homebrew
Mole GUI connects to the [Mole CLI](https://github.com/tw93/mole) engine. You can install it via Homebrew:
```bash
brew install mole
```
*(If Mole CLI is not found on launch, the built-in onboarding middleware will assist in installing it automatically with 1 click).*

---

## 🛠️ Development & Building from Source

### Prerequisites
* macOS 11.0 (Big Sur) or higher
* [Flutter SDK](https://flutter.dev/docs/get-started/install/macos) (v3.24+ recommended)
* Xcode 14+ command-line tools
* [create-dmg](https://github.com/create-dmg/create-dmg) (optional, for packaging DMG): `brew install create-dmg`
* [Mole CLI](https://github.com/tw93/mole): `brew install mole`

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/MoleCli_to_Flutter.git
cd MoleCli_to_Flutter/mole_gui
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run in Development Mode
```bash
flutter run -d macos
```

### 4. Run Unit & Widget Tests
```bash
flutter test
```

### 5. Build Release Application & DMG Installer
Use the automated build script:
```bash
chmod +x tool/build_dmg.sh
./tool/build_dmg.sh
```
The final DMG installer will be generated at `dist/Mole-GUI.dmg`.

---

## 🏗️ Architecture & Project Structure

```text
mole_gui/
├── assets/
│   └── icons/                 # App icon assets
├── lib/
│   ├── core/
│   │   ├── constants/         # App Colors, Styles, Routes
│   │   ├── services/          # System Info Service, CLI Service (Mole Bridge), Logger
│   │   ├── utils/             # Formatters, Helpers
│   │   └── widgets/           # GlassCard, Gauges, Sidebar, ActionButton
│   ├── features/
│   │   ├── analyze/           # Visual Disk Treemap Explorer & Breadcrumbs
│   │   ├── cleaner/           # System Cache, Log, and Trash Cleaner
│   │   ├── dashboard/         # Live Telemetry, Load Averages, Hardware Gauges
│   │   ├── installer/         # Installer (.dmg, .pkg, .iso) Cleaner
│   │   ├── maintenance/       # System Optimization Tasks & Terminal Stream
│   │   ├── projects/          # Developer Build Artifact Purger
│   │   ├── setup/             # Fresh Install Prerequisite Onboarding
│   │   └── uninstaller/       # App Uninstaller & Remnant Hunter
│   ├── routing/               # GoRouter with Setup Middleware
│   └── main.dart              # Application Entrypoint
├── macos/                     # Native macOS Runner & Window Constraints
└── tool/
    └── build_dmg.sh           # DMG Packaging Script with /Applications link
```

---

## 🤝 Credits & Acknowledgments

* **[Mole CLI](https://github.com/tw93/mole)**: Deep gratitude to [@tw93](https://github.com/tw93) and the contributors of the original [Mole](https://github.com/tw93/mole) project for building an outstanding, lightning-fast macOS cleanup and optimization command-line toolkit.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
