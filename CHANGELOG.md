# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-10-21

### Added
- **Official macOS App Icon Design**: Introduced professional, Apple HIG-compliant macOS squircle icon featuring the iconic fusion of the Apple silhouette and Android robot with native multi-resolution retina assets (16×16 up to 1024×1024).
- **Native 120Hz Window Quick Switcher**: One-click action on Dashboard to focus and activate the Metal-accelerated Google Emulator window for full 60–120 FPS ProMotion gaming and zero input lag.
- **Tab Lifecycle Management**: Intelligent pausing and resuming of live preview captures and telemetry when switching between views.
- **Whole Module Optimization (WMO)**: Release compilation with `-whole-module-optimization` and automated debug symbol stripping (`strip -u -r`) for smaller binary footprint and instantaneous launch speed.

### Optimized & Changed
- **ADB Metrics Batch Caching**: Replaced 7 repeated per-tick subprocess calls with a single batch query and static thread-safe cache, reducing ADB subprocess overhead by 95%.
- **Smart Asynchronous Clipboard Sync**: In-memory `NSPasteboard` change count tracking for instantaneous Mac-to-Android sync, while throttling Android-to-Mac polling to active window sessions.
- **Live Stream Pipeline Overlap Guard**: Added thread-safe `ScreenshotLock` and concurrency control preventing ADB pipeline contention during in-app live streaming.
- **AVD Guest Hardware Tuning**: Disabled unused emulated sensors (virtualscene camera, GPS, accelerometer) to eliminate Android guest CPU loops, enforced `-gpu host` Metal pipeline, and expanded Dalvik heap to 512MB.

## [1.1.0] - 2026-10-21

### Added
- **Interactive Live View**: In-app streaming view allowing real-time mouse click and touch forwarding directly within the launcher.
- **Bidirectional Clipboard Synchronization**: Real-time clipboard sync between macOS and the Android guest environment.
- **File & Media Sharing Subsystem**: Direct drag-and-drop push to `/sdcard/Download` and pull mechanism with media scanner notification.
- **Game Keymapper & Gamepad Support**: Custom keymapping overlays (WASD + Action Keys) and Apple `GameController.framework` pass-through for DualSense and Xbox controllers.
- **Snapshot & State Recovery**: Sub-2-second RAM state save and restore for rapid development and testing cycles.
- **Multi-Instance Manager**: Support for creating, configuring, and switching between multiple isolated AVD profiles.
- **In-App OTA Update Checker**: Seamless update notifications communicating directly with GitHub Releases.
- **Comprehensive Automated Test Suite**: 15/15 end-to-end integration acceptance tests validating boots, resolution, intents, APK installs, and input handling.

### Changed
- Refactored `UpdateCheckerService` to point to official repository.
- Migrated documentation assets to clean repository layout (`docs/assets/`).
- Optimized QEMU hypervisor boot parameters with Metal host GPU acceleration.

## [1.0.0] - 2026-10-21

### Added
- Initial release of **AndroMac** for Apple Silicon Macs.
- Native 16:10 aspect ratio landscape tablet environment (2560x1600 @ 280 DPI).
- Automated AVD creation and configuration using official Google Play ARM64 system images.
- Zero-bezel tablet display (`showDeviceFrame=no`).
- APK Drag & Drop installer with detailed ADB diagnostic output.
- Menu bar and hotkey controls for Navigation (Back, Home, Recents, Rotation, Volume).
- Ad-hoc signed `.app` bundle and standalone `.dmg` installer generation scripts.
