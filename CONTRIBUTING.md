# Contributing to AndroMac

Thank you for your interest in contributing to **AndroMac**! We welcome contributions from the community to make running Android tablet environments on macOS smoother, faster, and more versatile.

---

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please be respectful and considerate in all interactions.

---

## How Can I Contribute?

### 1. Reporting Bugs
- Before submitting an issue, search existing [Issues](https://github.com/sabbirmohammad/AndroMac/issues) to avoid duplicates.
- Use the **Bug Report** issue template.
- Include details such as:
  - macOS version (`sw_vers`)
  - Mac model & chip (e.g., M1 Pro, M3 Max)
  - Android SDK & system image version
  - Steps to reproduce and relevant console/ADB logs.

### 2. Suggesting Features
- Open a feature request using our **Feature Request** issue template.
- Clearly describe the problem the feature solves and how you envision the user experience.

### 3. Submitting Pull Requests
1. **Fork** the repository and create your branch from `main`:
   ```bash
   git checkout -b feature/my-new-feature
   ```
2. **Make your changes**:
   - Write clean, idiomatic Swift 6 code.
   - Follow Swift standard formatting conventions.
   - Ensure backwards compatibility with macOS 13.0+ (Ventura, Sonoma, Sequoia).
3. **Verify the build**:
   ```bash
   swift build -c release
   ```
4. **Run integration tests** (if Android SDK is configured locally):
   ```bash
   ./scripts/test_suite.sh
   ```
5. **Commit your changes**:
   - Use clear and descriptive commit messages (e.g., `feat: add custom gamepad deadzone config`).
6. **Push to your fork** and open a Pull Request against `main`.

---

## Development Environment Setup

- **Hardware**: Apple Silicon Mac (M1/M2/M3/M4 or newer).
- **macOS**: macOS 13.0 Ventura or later.
- **Xcode / Command Line Tools**: Swift 6.0+ toolchain.
- **Android SDK**:
  - `platform-tools` (adb)
  - `emulator`
  - `system-images;android-34;google_apis_playstore;arm64-v8a` (or Android 15/16 preview).

---

## Project Structure

```
AndroMac/
├── Package.swift               # Swift Package Manager manifest
├── Sources/
│   └── AndroMac/
│       ├── main.swift          # Entrypoint & NSApplication delegate
│       ├── Models/             # State & configuration structs
│       ├── ViewModels/         # Observable state managers
│       ├── Views/              # SwiftUI views and subcomponents
│       ├── Services/           # ADB, AVD, Emulator, Sync, and IO services
│       └── Resources/          # Assets, Info.plist, AppIcon
├── scripts/                    # App bundling, DMG packaging, and test scripts
├── docs/                       # Screenshots and documentation assets
└── Tests/                      # Unit & integration test suites
```
