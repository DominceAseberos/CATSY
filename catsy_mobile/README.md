# Catsy POS — Setup Guide

> **CATSY POS** is an offline-first, local-sync Point of Sale (POS) system built with Flutter. It serves as the primary interface for café staff to manage orders, tables, inventory, and customer loyalty.

---

## 🚀 1. Clone & Initialize

Clone the repository and install dependencies:

```bash
git clone https://github.com/Domincee/POS-Catsy-Cafe.git
cd catsy_pos
flutter pub get
```

## 🔑 2. Environment Configuration

1.  Create a `.env` file in the root directory.
2.  Configure your local development settings:

```env
# API Bridge server URL (usually running locally on port 8000)
API_BRIDGE_BASE_URL=http://localhost:8000

# Feature Flags
ENABLE_OFFLINE_MODE=true
ENABLE_PRINTING=true
```

## 🌿 3. Branch Management

Always create a new branch for your task:

```bash
# Verify you are on main and up to date
git checkout main
git pull origin main

# Create your feature branch
git checkout -b feature/my-new-feature
```

**Before pushing code:**
1. Run `flutter analyze` to check for lint issues.
2. Ensure your changes follow the local-first architecture (DAO → Repository → Provider).

## 🛠️ 4. Running the App

### Debug Mode (Preferred)
```bash
flutter run
```

### Build for Production
```bash
# Android
flutter build apk --split-per-abi

# iOS
flutter build ios
```

---

## 🏗️ Architecture & Implementation Status

> ⚠️ **IMPORTANT: Must Read** ⚠️  
> Before starting development, you **must read** the implementation status document. It contains the *true* state of the UI and outlines which components are finished vs. just placeholders.
> 
> 👉 **[implemented.md](file:///mnt/datadrive/Project/CATSY/catsy_pos/implemented.md)** (Live Documentation)

---

## 🔜 Next Steps

Please refer to the "What to Touch Next" section in `implemented.md` for full details. Top priorities include:

- [ ] Build `order_summary_screen.dart` UI (currently a placeholder).
- [ ] Fix Staff Reservation API integration (Backend returns 404).
- [ ] Remove hardcoded staff IDs in the Rewards flow and wire Dashboard quick actions.
