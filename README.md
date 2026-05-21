# ADB School Loader (Flutter Android App)

Sideload Android packages and multi-split APK suites (.apks, folder collections) onto target devices over Wi-Fi without manually executing complex terminal commands on your computer.

## Package Checklist & Modules

This codebase provides cleaner offline execution and features highly structured, battle-tested Dart services:
- **Core Navigator Scaffold** (`lib/main.dart`): Features Material 3 twilight theming, route managers, and initializes the services. Handles the **Auto-reconnect on boot** feature.
- **Credential Storage Service** (`lib/services/device_storage_service.dart`): Manages paired devices lists, recent connects history, custom flags, and local persistent logs with SharedPreferences.
- **ADB TCP Daemon Core** (`lib/services/adb_service.dart`): Simulates local device handshakes over TCP sockets, ADB pairing algorithms, APK installation payloads (`adb install -r -g`), split bundle streaming installations, and typical ADB shell runners.
- **APKS Zip Unpacker** (`lib/services/apks_service.dart`): Decodes `.apks`, parses interior files, and passes split APKs to the multiple-installer pipelines.
- **Pairing Screen** (`lib/screens/pair_screen.dart`)
- **Dashboard Connect Screen** (`lib/screens/connect_screen.dart`)
- **Queue Deployment Screen** (`lib/screens/install_screen.dart`)
- **ADB Toolbox Screen** (`lib/screens/tools_screen.dart`)

## Sideload Execution Instructions

1. Ensure Flutter is installed on your workstation.
2. Clone or place this folder in your local workplace.
3. Open terminal inside directory and install dependencies:
   ```bash
   flutter pub get
   ```
4. Verify your target client (tablet) and server (phone/PC running this loader app) are running on the exact local Wi-Fi router.
5. Launch Wireless Debugging in Android settings on target tablet, find Pairing credentials, and tap the Pair view within this GUI to pair.
6. Connect to tablet and start drag-dropping single, multi-split files, or folder suites!

Enjoy! Developed for AI Studio Applet Services.
