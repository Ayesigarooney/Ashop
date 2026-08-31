# Ashop – Smart Shop Manager & POS

**Tagline:** Simple. Fast. Reliable. Offline POS for small & micro businesses.

---

## Overview

Ashop is a fully offline Point-of-Sale and Inventory Management app built with Flutter, designed for small retail shops, kiosks, boutiques, pharmacies, and street vendors — especially in markets like Kampala.

> Developed by **Aaron Codes and Computing Services** | 📞 +256766088271

---

## Features

### ✅ Core Features
- **Dashboard** – Real-time revenue, profit, and stock overview
- **Point of Sale** – Fast cart-based checkout with barcode scanning
- **Product Management** – Full CRUD with categories, barcode, images, and stock tracking
- **Order History** – Full sales records with search, filter by date, and refund support
- **Analytics** – Revenue trends, top products, payment method breakdown
- **Receipt Printing** – Bluetooth thermal printer support + PDF/share
- **Settings** – Shop profile, currency (UGX default), tax, PIN lock, dark/light theme

### 🔋 Technical Highlights
- 100% Offline-first (Hive local database)
- Clean Architecture (Data → Domain → Presentation)
- Flutter BLoC / Cubit state management
- Dark & Light themes with premium UI

---

## Getting Started

### Requirements
- Flutter 3.x
- Android SDK / Android Studio
- A physical Android device (for Bluetooth printing + camera scanning)

### Setup

```bash
# Clone the project
git clone <repo-url>
cd ashop

# Install dependencies
flutter pub get

# Run on device
flutter run --release
```

### Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Project Structure

```
lib/
├── core/             # Theme, constants, utilities
├── features/         # Product, Sale, Settings (Clean Architecture)
├── presentation/     # All screens / pages
└── main.dart         # App entry point
```

---

## Developed By

**Aaron Codes and Computing Services**  
📞 +256766088271

---

*Ashop v1.0.0 — © 2024 Aaron Codes and Computing Services. All rights reserved.*
