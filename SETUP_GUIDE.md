# 🛒 Ashop – Smart Shop Manager & POS
## Complete Setup Guide

**Developed by Aaron Codes and Computing Services | 📞 +256766088271**

---

## 📋 Project Overview

Ashop is a **fully offline Flutter POS app** with:

| Feature | Status |
|---|---|
| Beautiful dashboard with real-time stats | ✅ |
| Point of Sale (cart, barcode scan, discounts) | ✅ |
| Product management (CRUD, images, categories) | ✅ |
| Order history with refunds | ✅ |
| Analytics & revenue charts | ✅ |
| Bluetooth thermal receipt printing | ✅ |
| PDF receipt generation | ✅ |
| PIN security lock | ✅ |
| Dark / Light theme | ✅ |
| Multi-currency support (UGX default) | ✅ |
| 100% offline — Hive local database | ✅ |
| Low stock & out-of-stock alerts | ✅ |
| Demo data seeded on first launch | ✅ |

---

## ⚙️ Prerequisites

Install the following before starting:

1. **Flutter SDK 3.x** — https://flutter.dev/docs/get-started/install
2. **Android Studio** (or VS Code with Flutter extension)
3. **Java JDK 17** — Required by Android Gradle
4. A **physical Android device** (API 21+) — recommended for camera/Bluetooth features

Verify setup:
```bash
flutter doctor
# All checkmarks should be green
```

---

## 🚀 Getting Started

### Step 1 – Extract the zip
```bash
unzip ashop_flutter_project.zip
cd ashop
```

### Step 2 – Install dependencies
```bash
flutter pub get
```

### Step 3 – Run the app
```bash
# On a connected Android device
flutter run

# Or build a release APK
flutter build apk --release
# APK is at: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📁 Project Structure

```
ashop/
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_theme.dart        ← All colors, fonts, theme
│   │   │   └── constants.dart        ← App-wide constants
│   │   └── utils/
│   │       ├── currency_formatter.dart
│   │       ├── date_formatter.dart
│   │       └── printer_helper.dart   ← PDF receipt generator
│   │
│   ├── features/
│   │   ├── product/
│   │   │   ├── data/models/          ← ProductModel + Hive adapter
│   │   │   ├── data/repositories/    ← ProductRepository (Hive CRUD)
│   │   │   └── presentation/bloc/    ← ProductCubit
│   │   ├── sale/
│   │   │   ├── data/models/          ← SaleModel + SaleItemModel
│   │   │   ├── data/repositories/    ← SaleRepository
│   │   │   └── presentation/bloc/    ← SaleCubit (cart state)
│   │   └── settings/
│   │       └── data/                 ← SettingsRepository (Hive box)
│   │
│   ├── presentation/
│   │   ├── splash/                   ← Animated splash + PIN check
│   │   ├── home/                     ← Dashboard screen
│   │   ├── pos/                      ← POS + cart + checkout + receipt
│   │   ├── products/                 ← Product list, detail, add/edit
│   │   ├── analytics/                ← Charts and reports
│   │   ├── order_history/            ← Sales history + refunds
│   │   ├── settings/                 ← Full settings screen
│   │   ├── inventory/                ← Stock value overview
│   │   └── auth/                     ← PIN lock screen
│   │
│   ├── shared/widgets/               ← Reusable UI components
│   └── main.dart                     ← App entry point
│
├── android/                          ← Android config + permissions
├── pubspec.yaml                      ← Dependencies
└── README.md
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management (Cubit) |
| `hive_flutter` | Fast local database |
| `mobile_scanner` | Camera barcode scanning |
| `fl_chart` | Revenue/analytics charts |
| `pdf` + `printing` | PDF receipt generation |
| `blue_thermal_printer` | Bluetooth thermal printing |
| `google_fonts` | Syne + Inter typography |
| `image_picker` | Product photo from camera/gallery |
| `share_plus` | Share receipts |
| `go_router` | Navigation |

---

## 🎨 Design System

- **Primary:** `#6C63FF` (Purple)
- **Accent:** `#00E5A0` (Green)
- **Font:** Syne (headings) + Inter (body)
- **Dark BG:** `#0D0E1C`
- **Supports:** Dark & Light themes

---

## 🔧 Customization

### Change shop defaults
Edit `lib/core/config/constants.dart`:
```dart
static const String defaultCurrency = 'UGX'; // Change to your currency
```

### Change demo products
Edit `lib/features/product/data/repositories/product_repository.dart` → `seedDemoProducts()`.

### Change app theme colors
Edit `lib/core/config/app_theme.dart` → `primaryColor`, `accentColor`.

---

## 📱 Building Release APK

```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore ashop-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ashop

# Build signed APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

---

## 🛠️ Troubleshooting

| Issue | Fix |
|---|---|
| `flutter pub get` fails | Run `flutter clean` then retry |
| Gradle build fails | Ensure JDK 17 is installed |
| Camera not working | Run on a physical device, not emulator |
| Bluetooth print not working | Grant Bluetooth permissions in device settings |
| Hive adapter error | Run `flutter pub run build_runner build --delete-conflicting-outputs` |

---

## 📞 Support

**Developer:** Aaron Codes and Computing Services  
**Phone:** +256766088271  

---

*Ashop v1.0.0 — Built with ❤️ in Flutter*
