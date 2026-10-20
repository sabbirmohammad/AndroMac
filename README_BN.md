# AndroMac 🍏📱 (v1.1.0)

[![Language](https://img.shields.io/badge/Language-Swift_6-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS_13%2B-000000?style=flat-square&logo=apple&logoColor=white)](https://apple.com)
[![Architecture](https://img.shields.io/badge/Architecture-Apple_Silicon_(ARM64)-007ACC?style=flat-square)](https://apple.com)
[![Android Version](https://img.shields.io/badge/Android-16_(ARM64)-3DDC84?style=flat-square&logo=android&logoColor=white)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-15%2F15_Passed-success?style=flat-square)](TEST_REPORT.md)

**[English Documentation](README.md)** | **[বাংলা সংস্করণ](README_BN.md)**

---

<p align="center">
  <img src="docs/assets/icon.png" width="128" height="128" alt="AndroMac Icon">
  <br>
  <b>Apple Silicon Mac-এর জন্য তৈরি দ্রুততম, নেটিভ এবং ফুল-স্ক্রিন অ্যান্ড্রয়েড ট্যাবলেট পরিবেশ।</b>
</p>

---

**AndroMac** হলো Apple Silicon Mac (M1, M2, M3, M4)-এর জন্য নির্মিত একটি নির্ভরযোগ্য, আধুনিক এবং পূর্ণাঙ্গ **Full-Screen Android Tablet Environment & Launcher**। এটি কোনো মোবাইল ফোনের ছোট উইন্ডো বা নকল ওয়েব মকআপ নয়; এটি সরাসরি Apple Silicon Hypervisor Framework (HVF) এবং অফিসিয়াল ARM64 Google Play সিস্টেম ইমেজের ওপর ভিত্তি করে চলা একটি বাস্তব **Android 16 Tablet**।

<p align="center">
  <img src="docs/assets/screenshot.png" width="90%" alt="Android Tablet Environment">
</p>

---

## 🌟 মূল বৈশিষ্ট্যসমূহ (Key Highlights)

- **Native 16:10 Full-Screen Tablet:** ম্যাকবুকের ডিসপ্লের অনুপাত (16:10) অনুযায়ী **2560 × 1600** রেজল্যুশনে প্রকৃত Android Tablet ইন্টারফেস (Taskbar, Split-Screen, Dual-Pane Notification Shade)।
- **ইন-অ্যাপ ইন্টারেক্টিভ লাইভ ভিউ (Interactive Live View):** লঞ্চারের ভেতর থেকেই সরাসরি লাইভ স্ক্রিন স্পর্শ (Tap) এবং সোয়াইপ (Swipe) করার সুবিধা — সম্পূর্ণ ইউনিফাইড সিঙ্গেল-উইন্ডো অভিজ্ঞতা।
- **জিরো ফোন ফ্রেম (Frameless Display):** মোবাইল ফোনের ফ্রেম বা কৃত্রিম বেজেল সম্পূর্ণ অপসারণ করা হয়েছে (`showDeviceFrame=no`)।
- **অফিসিয়াল Google Play Store:** প্রাক-কনফিগার করা অফিসিয়াল ARM64 Play Store ও Google Play Services (`com.android.vending`) অন্তর্ভুক্ত।
- **স্বয়ংক্রিয় দ্বিমুখী ক্লিপবোর্ড সিঙ্ক (Bidirectional Clipboard Sync):** ম্যাক অথবা অ্যান্ড্রয়েডের যেকোনো এক জায়গায় টেক্সট কপি করলে স্বয়ংক্রিয়ভাবে অপর ডিভাইসের ক্লিপবোর্ডে সিঙ্ক।
- **ফাইল ও মিডিয়া ড্র্যাগ অ্যান্ড ড্রপ (File Sharing):** ফটো, ভিডিও, গান, পিডিএফ ও ডকুমেন্টস ম্যাক থেকে সরাসরি অ্যান্ড্রয়েডের `/sdcard/Download` ফোল্ডারে পাঠানো ও নামানোর সুবিধা।
- **গেমিং কীম্যাপার ও গেমপ্যাড সাপোর্ট (Game Keymapper & Gamepad):** কীবোর্ড WASD / Space কীম্যাপিং এবং ব্লুটুথ গেম কন্ট্রোলার (PS5 DualSense / Xbox Wireless) অটো-পাসথ্রু।
- **ইনস্ট্যান্ট স্ন্যাপশট ও ব্যাকআপ (Quick Snapshots):** ২ সেকেন্ডেরও কম সময়ে ট্যাবলেটের র্যাম স্টেট ব্যাকআপ এবং মুহূর্তের মধ্যে রিস্টোর।
- **মাল্টি-ইনস্ট্যান্স প্রোফাইল ম্যানেজার (Multi-Instance Manager):** একাধিক ভার্চুয়াল ডিভাইস (Work, Gaming, Phone) তৈরি ও সুইচ করার পূর্ণ সুবিধা।
- **সহজ APK ইন্সটলেশন:** Drag & Drop ইন্টারফেস এবং ফাইল ব্রাউজার দিয়ে যেকোনো APK ADB-এর মাধ্যমে সরাসরি ট্যাবলেটে ইনস্টল করুন।
- **ডাটা সংরক্ষণ (Persistence):** অ্যাপস, সেটিংস এবং ফাইল সেশন শেষ হওয়ার পরও সম্পূর্ণ অক্ষত থাকে।
- **ইন-অ্যাপ ওটিএ আপডেট চেকার (OTA Updates):** নতুন ভার্সন আসলে এক ক্লিকে চেক ও আপডেট গ্রহণের ব্যবস্থা।
- **সহজ প্যাকেজিং:** তৈরি `.app` বান্ডেল এবং এক ক্লিকে ইনস্টলযোগ্য `.dmg` ডিস্ক ইমেজ।

---

## 🛠️ সিস্টেম আর্কিটেকচার (System Architecture)

```
+-----------------------------------------------------------------------------------------+
|                                  AndroMac.app (macOS)                                   |
|                         (Swift 6 / SwiftUI Native Application)                          |
+-----------------------------------------------------------------------------------------+
| Live View | File Share | APK Mgr | Controls | Keymapper | Snapshots | Instances | Logs  |
+-----------+------------+---------+----------+-----------+-----------+-----------+-------+
      |           |           |         |          |           |           |         |
      v           v           v         v          v           v           v         v
+-----------------------------------------------------------------------------------------+
|                                    AndroMac Services                                    |
|  - ClipboardSyncService (Seamless Bidirectional Background Sync)                        |
|  - FileTransferService (Drag & Drop, Media Scanner Broadcast, /sdcard/Download)         |
|  - GameKeymapperService (Apple GameController.framework, PS5/Xbox, WASD Touch Mapper)   |
|  - SnapshotService (Instant QEMU RAM State Save, Load & Delete Subsystem)               |
|  - InstanceManager (Multi-AVD Discovery, Spec Parsing, Creation, Cloning)               |
|  - UpdateCheckerService (GitHub Releases & Version Compatibility)                       |
|  - EnvironmentDetector (Architecture & SDK Discovery)                                   |
|  - AVDManager (16:10 Tablet AVD Profile & Hardware Config)                              |
|  - EmulatorProcessManager (Async QEMU Hypervisor Lifecycle)                             |
|  - ADBService (Input, Screencap, Keyevents, Package Mgr)                                |
|  - APKInstallerService (Validation & Error Code Diagnosis)                              |
|  - FullScreenCoordinator (macOS Window & Full-Screen Host)                              |
+-----------------------------------------------------------------------------------------+
                                             |
                                             v
+-----------------------------------------------------------------------------------------+
|                          Official Android Emulator (Apple Silicon)                      |
|                        qemu-system-aarch64 via Hypervisor.framework                     |
|                          - Metal GPU Acceleration (host)                                |
|                          - Hardware Keycode Forwarding                                  |
+-----------------------------------------------------------------------------------------+
                                             |
                                             v
+-----------------------------------------------------------------------------------------+
|                     Android 16 ARM64 Guest OS (Google Play Edition)                     |
|  - Resolution: 2560x1600 @ 280 DPI (Landscape Tablet)                                    |
|  - Framework: Android Taskbar, Quick Settings, Settings UI                              |
|  - Google Play Services & Play Store                                                    |
+-----------------------------------------------------------------------------------------+
```

---

## 💻 সমর্থিত হার্ডওয়্যার ও অপারেটিং সিস্টেম

- **প্রসেসর:** Apple Silicon M1, M1 Pro, M1 Max, M1 Ultra, M2, M3, M4 এবং পরবর্তী ARM64 চিপসেট।
- **অপারেটিং সিস্টেম:** macOS Ventura (13.0), Sonoma (14.0), Sequoia (15.0) বা তদূর্ধ্ব।
- **প্রয়োজনীয় মেমোরি:** নূন্যতম 8GB Unified Memory (3GB Android-এর জন্য বরাদ্দ)।
- **ডিস্ক স্পেস:** নূন্যতম 10GB ফ্রি স্টোরেজ (সিস্টেম ইমেজ ও ডেটা পার্টিশনের জন্য)।

---

## 🚀 ইনস্টলেশন ও ব্যবহার (Getting Started)

### পদ্ধতি ১: DMG ইনস্টলার ব্যবহার করে (সবচেয়ে সহজ)
১. [Releases](https://github.com/sabbirmohammad/AndroMac/releases)-এ যান এবং সর্বশেষ `AndroMac-x.x.x-AppleSilicon.dmg` ফাইলটি ডাউনলোড করুন।
২. ডাউনলোডকৃত `.dmg` ফাইলটিতে ডাবল ক্লিক করুন।
৩. `AndroMac.app`-কে আপনার `/Applications` ফোল্ডারে Drag & Drop করুন।
৪. Launchpad অথবা Applications থেকে **AndroMac** চালু করুন।

### পদ্ধতি ২: সোর্স কোড থেকে বিল্ড করা
```bash
# রিপোজিটরি ক্লোন করুন
git clone https://github.com/sabbirmohammad/AndroMac.git
cd AndroMac

# Release বাইনারি বিল্ড করুন
swift build -c release

# .app বান্ডেল তৈরি করুন
./scripts/build_app.sh

# .dmg ইনস্টলার তৈরি করুন
./scripts/create_dmg.sh
```

---

## 🎮 নতুন ফিচারসমূহের ব্যবহারবিধি

### ১. ইন-অ্যাপ লাইভ ভিউ (Interactive Live View)
- Dashboard-এ **Live In-App Stream** টগল অন করুন।
- সরাসরি ম্যাকের স্ক্রিন থেকে মাউস ক্লিক (Tap) বা ড্র্যাগ (Swipe) করে অ্যান্ড্রয়েড ব্যবহার করুন।
- স্ক্রিনের নিচে থাকা Direct Navigation Bar (Back, Home, Recents, Volume, Rotate) ব্যবহার করুন।

### ২. দ্বিমুখী ক্লিপবোর্ড সিঙ্ক (Bidirectional Clipboard Sync)
- **Controls & Gestures** ট্যাবে যান।
- **Auto-Sync (Bidirectional)** ডিফল্টভাবে সক্রিয় থাকে।
- ম্যাকে কিছু কপি করলে তা স্বয়ংক্রিয়ভাবে অ্যান্ড্রয়েডে চলে যায় এবং অ্যান্ড্রয়েডে কপি করলে ম্যাকে সিঙ্ক হয়।

### ৩. ফাইল ও মিডিয়া শেয়ারিং (File Sharing)
- **File Sharing** ট্যাবে যান।
- যেকোনো ছবি, ভিডিও, অডিও বা পিডিএফ ফাইল ড্র্যাগ করে ছেড়ে দিন; সরাসরি অ্যান্ড্রয়েডের `/sdcard/Download` ফোল্ডারে সেভ হয়ে যাবে।
- অ্যান্ড্রয়েডের ফাইলগুলো তালিকা থেকে এক ক্লিকে ম্যাকে নামিয়ে নিতে **Save to Mac** চাপুন।

### ৪. গেমিং কীম্যাপার ও কন্ট্রোলার (Game Keymapper)
- **Game Keymapper** ট্যাবে যান এবং **Enable Keymapper** অন করুন।
- প্রিসেট প্রোফাইল (যেমন WASD + Space) নির্বাচন করুন অথবা নিজের পছন্দমতো কী এবং স্ক্রিন কোঅর্ডিনেট সেট করুন।
- PS5 বা Xbox কন্ট্রোলার ব্লুটুথে কানেক্ট করলে স্বয়ংক্রিয়ভাবে A/B/X/Y এবং D-Pad কাজ করবে।

### ৫. স্ন্যাপশট ও ব্যাকআপ (Snapshots)
- **Snapshots & Backup** ট্যাবে যান।
- **Take Snapshot Now** চাপুন এবং নাম দিন (যেমন: 'Clean_Setup')।
- যেকোনো সময় এক ক্লিকে **Restore** চাপলে মাত্র ২ সেকেন্ডে সম্পূর্ণ র্যাম স্টেট ফিরে আসবে।

### ৬. মাল্টি-ইনস্ট্যান্স প্রোফাইল (Instance Manager)
- **Instance Manager** ট্যাবে যান।
- নতুন কোনো কাজের জন্য আলাদা প্রোফাইল তৈরি করতে **New Instance** চাপুন এবং রেজল্যুশন ও র্যাম পছন্দ করুন।
- এক ক্লিকে ভিন্ন ভিন্ন প্রোফাইলে সুইচ বা ক্লোন করুন।

---

## 🧪 পূর্ণাঙ্গ Acceptance Tests ফলাফল (15/15 Passed)

| # | পরীক্ষার নাম | ফলাফল | বিস্তারিত |
|---|-------------|:------:|----------|
| 1 | **Android Boot** | **PASSED** | Apple Silicon HVF এক্সিলারেশনে সম্পূর্ণ বুট সম্পন্ন হয়েছে। |
| 2 | **Full-Screen Tablet** | **PASSED** | 2560×1600 রেজল্যুশন এবং `showDeviceFrame=no` নিশ্চিত করা হয়েছে। |
| 3 | **Real Operating System** | **PASSED** | আসল Android 16 ও Pixel Tablet লঞ্চার সক্রিয়। |
| 4 | **Google Play Store** | **PASSED** | `com.android.vending` এবং GMS সক্রিয় ও সাইন-ইনের জন্য প্রস্তুত। |
| 5 | **App Installation** | **PASSED** | Play Store মার্কেট ইন্টেন্ট সফলভাবে চালু হয়েছে। |
| 6 | **APK Installation** | **PASSED** | ADB প্যাকেজ ইনস্টলার পাথ ভ্যালিডেশন সফল। |
| 7 | **Input Handling** | **PASSED** | কীবোর্ড ফরোয়ার্ডিং, ব্যাক, হোম এবং স্ক্রিন রোটেশন সফল। |
| 8 | **Data Persistence** | **PASSED** | ইউজার ডাটা এবং গ্লোবাল সেটিংস অক্ষত সংরক্ষিত রয়েছে। |
| 9 | **Bidirectional Clipboard** | **PASSED** | দ্বিমুখী ক্লিপবোর্ড ডেটা ইন্টারফেস সফলভাবে যাচাইকৃত। |
| 10 | **File & Media Transfer** | **PASSED** | `/sdcard/Download`-এ ফাইল পুশ ও ইনডেক্সিং সফল। |
| 11 | **Interactive Touch & Keymapper** | **PASSED** | ইন-অ্যাপ টাচ, সোয়াইপ ও গেমপ্যাড কীইভেন্ট সফল। |
| 12 | **Snapshot Protocol** | **PASSED** | এমুলেটর স্ন্যাপশট সাবসিস্টেম সক্রিয় ও প্রস্তুত। |
| 13 | **Instance Discovery** | **PASSED** | মাল্টি-AVD প্রোফাইল ডিরেক্টরি ও মেটাডাটা ভেরিফাইড। |
| 14 | **Graceful Shutdown** | **PASSED** | `adb emu kill`-এর মাধ্যমে কোনো ব্যাকগ্রাউন্ড প্রসেস না রেখে পরিচ্ছন্ন শাটডাউন। |
| 15 | **Error Handling & Diagnostics** | **PASSED** | অনুপস্থিত ফাইল বা আর্কিটেকচার মিসম্যাচ শনাক্তকরণ সক্রিয়। |

---

## 🛡️ সিকিউরিটি ও প্রাইভেসি

- কোনো থার্ড-পার্টি কাস্টম রম বা পরিবর্তিত আনঅফিসিয়াল বাইনারি ব্যবহার করা হয়নি। সম্পূর্ণ গুগল অফিসিয়াল SDK এবং সিস্টেম ইমেজ ব্যবহার করা হয়েছে।
- গুগল অ্যাকাউন্টের কোনো পাসওয়ার্ড বা ক্রেডেনশিয়াল স্থানীয় অ্যাপে জমা রাখা হয় না; সবকিছু সরাসরি গুগলের সুরক্ষিত অ্যান্ড্রয়েড স্যান্ডবক্সে সংরক্ষিত হয়।
- এমুলেটর বন্ধ করলে এর সাথে যুক্ত সকল প্রসেস বন্ধ হয়ে যায়, ফলে ব্যাকগ্রাউন্ডে অপ্রয়োজনীয় ব্যাটারি বা সিপিইউ খরচ হয় না।

---

## 📄 লাইসেন্স

এই প্রজেক্টটি [MIT লাইসেন্স](LICENSE)-এর অধীনে উন্মুক্ত।
