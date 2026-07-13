# PROJECT_ANALYSIS.md — Krishi Bandhu (PMFBY App)

> **Generated:** 2026-07-12 | **Analyzer:** Antigravity IDE  
> **Repository:** `/Users/rohan/pmfby-app/pmfby-app-master`  
> **Package name:** `krashi_bandhu` | **Version:** 1.0.0+1

---

## 1. Project Overview

**Krishi Bandhu** (meaning "Farmer's Friend") is a Flutter mobile application built to digitize and streamline India's **Pradhan Mantri Fasal Bima Yojana (PMFBY)** — the national crop insurance scheme. The app serves two categories of users:

- **Farmers** — to monitor their crops, report crop loss, file insurance claims, and track their policies.
- **Government Officials / Field Officers** — to manage and review claims, inspect farms, view district-level analytics, and administer the scheme.

The application is designed primarily for **Android** (with web support scaffolded) and targets rural India with heavy emphasis on multilingual support (16 Indian languages), offline-first operation, and visual simplicity for low-tech users.

**Target audience:** Small and marginal farmers across rural India, PMFBY field officers, district insurance administrators.

---

## 2. Folder Structure

```
pmfby-app-master/
├── lib/
│   ├── main.dart                  # App entry point, router, top-level providers
│   ├── firebase_options.dart      # Firebase platform config (FlutterFire generated)
│   └── src/
│       ├── config/                # App-wide configuration
│       │   └── mongodb_config.dart
│       ├── features/              # Feature-first module organization (20 features)
│       │   ├── auth/              # Authentication (login, register, providers)
│       │   │   ├── data/services/ → auth_service.dart
│       │   │   ├── domain/models/ → user_model.dart
│       │   │   └── presentation/  → login screens, auth_provider
│       │   ├── dashboard/         # Farmer dashboard
│       │   ├── officer/           # Officer dashboard & district efficiency
│       │   ├── camera/            # Camera, Enhanced Camera, AR Camera
│       │   ├── claims/            # Insurance claims list & filing
│       │   ├── complaints/        # Farmer complaints management
│       │   ├── crop_loss/         # Crop loss intimation & filing
│       │   ├── crop_monitoring/   # Basic crop image capture
│       │   ├── feedback/          # Farmer feedback reports & admin view
│       │   ├── multi_image/       # Bulk image capture & batch upload
│       │   ├── batch_upload/      # Enhanced batch upload screen
│       │   ├── satellite/         # Satellite monitoring (NDVI/EVI maps)
│       │   ├── weather/           # Weather screen (OpenWeatherMap)
│       │   ├── premium_calculator/# PMFBY premium calculation
│       │   ├── pmfby_info/        # Scheme information & FAQ
│       │   ├── profile/           # User profile management
│       │   ├── schemes/           # Scheme listing
│       │   ├── settings/          # Language settings
│       │   ├── splash/            # Animated splash screen
│       │   └── uploads/           # Upload status tracking
│       ├── localization/          # app_localizations.dart (3,600+ lines, 16 languages)
│       ├── models/                # Shared data models
│       │   ├── crop_image.dart
│       │   ├── insurance_claim.dart
│       │   ├── user_profile.dart
│       │   └── mongodb/           # MongoDB-specific document models
│       │       ├── claim_model.dart
│       │       ├── crop_image_model.dart
│       │       ├── crop_loss_model.dart
│       │       ├── farmer_model.dart
│       │       ├── feedback_model.dart
│       │       └── official_model.dart
│       ├── providers/             # Global state providers
│       │   └── language_provider.dart
│       ├── repositories/          # Data access layer
│       │   ├── auth_repository.dart
│       │   ├── crop_image_repository.dart
│       │   ├── crop_loss_repository.dart
│       │   └── farmer_repository.dart
│       ├── services/              # Business logic & external integrations (16 services)
│       │   ├── aadhar_service.dart
│       │   ├── audio_service.dart
│       │   ├── auto_sync_service.dart
│       │   ├── cloud_image_service.dart      # Cloudinary integration
│       │   ├── connectivity_service.dart
│       │   ├── email_otp_service.dart
│       │   ├── firebase_auth_service.dart
│       │   ├── firestore_service.dart
│       │   ├── image_deduplication_service.dart
│       │   ├── image_upload_service.dart
│       │   ├── local_storage_service.dart
│       │   ├── mongodb_service.dart
│       │   ├── security_service.dart
│       │   ├── sentinel_hub_service.dart     # ESA Sentinel-2 satellite imagery
│       │   ├── translation_service.dart      # Google ML Kit on-device translation
│       │   └── weather_service.dart          # OpenWeatherMap API
│       ├── theme/                 # Material 3 theming
│       │   ├── app_themes.dart
│       │   └── pmfby_theme.dart
│       └── widgets/               # Shared UI components
│           ├── app_icon.dart
│           ├── audio_player_dialog.dart
│           ├── language_selector_widget.dart
│           ├── shimmer_loading.dart
│           └── wheat_field_background.dart
├── assets/
│   ├── images/                    # Background and app images
│   └── audio/                     # Audio guidance files
├── android/                       # Android native project
├── web/                           # Flutter web scaffold
├── test/                          # Tests (minimal)
├── pubspec.yaml
└── analysis_options.yaml
```

**Total features (screens):** ~30 unique screens across 20 feature modules  
**Total services:** 16  
**Total Dart files (lib/):** ~70+  
**Localization:** 1 massive file, 3,632 lines, covering 16 Indian languages

---

## 3. Architecture

### Pattern
The project targets **feature-first Clean Architecture** with a layered model per feature:

```
Feature
  ├── data/          # Data sources, external services
  ├── domain/        # Business logic models
  └── presentation/  # Widgets, Screens, Providers
```

However, this pattern is **partially applied** — only the `auth` feature strictly follows the three-layer split. Most other features (camera, claims, satellite, etc.) contain screens directly at the feature root or just inside a `presentation/` folder, without a `domain/` or `data/` layer. The distinction collapses in practice for ~80% of features.

### Layering overview

| Layer | Implementation |
|-------|----------------|
| Presentation | Stateful/Stateless widgets, GoRouter navigation |
| Business Logic | `ChangeNotifier` providers (AuthProvider, LanguageProvider, ImageUploadService, FirebaseAuthService) |
| Service Layer | 16 service singletons + `ChangeNotifier` hybrids |
| Data Access | 4 repository classes + direct Firestore/MongoDB calls from services |
| Local Persistence | `SharedPreferences` (user sessions, language pref, image hashes) |
| Remote Persistence | Firebase Firestore (primary) + MongoDB Atlas (secondary/backup) |
| Media Storage | Cloudinary |

### Initialization flow

```
main() → MultiProvider (ThemeProvider, LanguageProvider)
   └── KrashiBandhuApp.build()
         ├── SplashScreen (until _initialize() completes)
         └── _initialize():
               ├── Firebase.initializeApp() [with 5s timeout]
               ├── MongoDBService.connect() [with 3s timeout]
               ├── AuthService.initialize()
               ├── AuthProvider.initialize()
               ├── AutoSyncService.initializeNotifications()
               └── AutoSyncService.initializeBackgroundSync()
                     └── MainApp (GoRouter)
```

All external service initializations have timeout + catch-and-continue guards, making the app resilient to backend failures.

---

## 4. State Management

The project uses **Provider** (`ChangeNotifier`-based) throughout. No Riverpod, Bloc, or GetX.

### Active Providers (registered at runtime)

| Provider | Scope | Purpose |
|----------|-------|---------|
| `ThemeProvider` | Global (root) | Light/dark theme toggle |
| `LanguageProvider` | Global (root) | Language selection, translation cache |
| `AuthProvider` | App (after init) | Current user, login/logout state |
| `FirebaseAuthService` | App (after init) | Firebase Auth identity |
| `ConnectivityService` | App (after init) | Online/offline monitoring |
| `AutoSyncService` | App (after init) | Background sync scheduling |
| `ImageUploadService` | App (after init) | Upload queue tracking & progress |

### Gotchas
- `ThemeProvider` and `LanguageProvider` are registered **before** Firebase/DB init, enabling the UI to bootstrap immediately.
- `AuthProvider` is created manually (outside the provider tree) and passed in via `.value` — this is non-standard but functional.
- There is **no global loading/error state provider**. Each screen manages its own loading and error states locally via `setState`.
- `ImageUploadService` extends `ChangeNotifier`, doubling as a service and state store — a mixing of concerns.

---

## 5. Major Features

### 5.1 Authentication
- **Local auth** (primary): `SharedPreferences` stores users as JSON. Plaintext password comparison in `auth_service.dart` (critical security issue — see §13).
- **Firebase Auth** (secondary): Wired up via `FirebaseAuthService`, but largely unused in flows.
- **Email OTP**: Full SMTP-based OTP service via `mailer` package using Gmail. OTPs stored in-memory (`Map<String, OTPData>`).
- **Aadhaar Verification**: Verhoeff checksum algorithm implemented locally. Simulated OTP sent to registered mobile (no real UIDAI API integration).
- **Roles**: `farmer` and `official` — role is stored in user JSON, determines which dashboard is shown.
- **Demo users**: Auto-created on first launch (demo farmer + demo official).

### 5.2 Farmer Dashboard (`dashboard_screen.dart` — 1,387 lines)
- Greeting with scroll-responsive header (parallax-like effect via `ScrollController`)
- Quick action grid: Camera, Crop Health, Claims, Satellite, Premium Calculator, Crop Loss, Schemes, Batch Upload
- Pending upload count badge
- Language switcher widget
- Audio player for voice guidance
- Wheat field animated background widget
- Auto-sync trigger (30-second periodic scan)

### 5.3 Officer Dashboard (`officer_dashboard_screen.dart` — 1,963 lines)
- Role-based view toggle (National / State / District officer)
- Hardcoded demo statistics (1,247 claims, 5,680 farmers, ₹12.54 Cr premium)
- Recent claims list with status chips
- fl_chart integration for visual analytics
- Weather widget (live via OpenWeatherMap)
- GPS-based location display
- Access to satellite monitoring and admin feedback view

### 5.4 AR Camera (`ar_camera_screen.dart` — 1,770 lines)
- Full AR overlay with real-time validation engine
- Multi-angle capture mode with sequential task queuing (`CaptureTaskManager`)
- Image quality analysis (`ImageQualityAnalyzer`)
- GPS tagging on capture
- Flash control, zoom (up to 8x), front/back camera toggle
- Custom AR overlay painters (grid, tilt indicator, ghost frame)
- Multiple animation controllers (pulse, capture flash, warning, task transition, focus)

### 5.5 Satellite Monitoring (`enhanced_satellite_screen.dart` — 1,444 lines)
- `flutter_map` with OpenStreetMap tiles
- Sentinel Hub integration (NDVI, EVI, Moisture Index, True Color from Sentinel-2)
- District-level color-coded overlays
- Tab views: Map, NDVI Chart, Scenes list, Weather
- Data layers: NDVI, EVI, Moisture, True Color (with fallback demo data when unconfigured)

### 5.6 Crop Loss Intimation
- Two-screen flow: Intimation form → Filing form
- GPS-based location auto-fill
- Photo evidence attachment
- Loss type selection (flood, drought, pest, fire, etc.)

### 5.7 Claims Management
- Tab view: All / Active / Approved / History
- Demo data (hardcoded) — no live backend fetch
- Status chips (pending → under review → approved / rejected)
- Navigation to file new claim

### 5.8 Batch Upload
- Multi-image selector (up to 10 images)
- Compression pipeline (70% quality, max 500 KB each)
- Batch upload with progress tracking (`ImageUploadService`)
- Upload queue persisted locally until sync
- Deduplication using perceptual hashing (aHash algorithm)

### 5.9 Premium Calculator
- Supports PMFBY, WBCIS, Modified NAIS
- State/District/Crop selectors backed by `IndiaData` static dataset
- Kharif (2%) / Rabi (1.5%) premium rates per PMFBY norms
- Calculates farmer premium, government subsidy, insurer share

### 5.10 Multilingual Support
- 16 languages: English + 15 Indian languages (Hindi, Punjabi, Marathi, Gujarati, Tamil, Telugu, Kannada, Malayalam, Bengali, Odia, Assamese, Urdu, Sanskrit, Rajasthani, Bhojpuri)
- **Approach 1 — Static strings:** `AppStrings` class with nested `Map<String, Map<String, String>>` (all strings hardcoded for all languages in a 3,600-line file)
- **Approach 2 — ML Kit on-device translation:** `TranslationService` with `google_mlkit_translation` for dynamic content. Language models downloaded on demand.
- Preference persisted via `SharedPreferences`
- `LanguageProvider` caches translations to avoid repeated ML Kit calls

### 5.11 Complaints System
- Farmer can submit and view complaints
- `Complaint` model passed via GoRouter `extra` parameter for detail view

### 5.12 Feedback / Reports
- `FeedbackReportScreen` for farmers to submit reports
- `MyReportsScreen` to view submitted reports
- `AdminFeedbackScreen` for officers to review and manage feedback (stored in MongoDB `feedback_reports` collection)

### 5.13 District Efficiency Score (`district_efficiency_screen.dart` — 34 KB)
- "Traffic light" gamified dashboard showing pending claims load
- Color-coded indicators (green/yellow/red) per district
- Animated metric cards

### 5.14 Weather Screen (`weather_screen.dart` — 72 KB, largest file)
- OpenWeatherMap API integration
- GPS-based current location weather
- Forecast and agricultural advisories

---

## 6. User Flows

### Farmer Flow
```
App Launch → Splash Screen (Firebase + MongoDB init + demo users)
    → Dashboard Selection Screen
        ↓ [Farmer]
    → Farmer Dashboard
        ├── Camera → Enhanced Camera / AR Camera → Image Preview → Upload
        ├── Claims → Claims List → File Claim
        ├── Satellite Monitoring → NDVI Map / EVI / Weather
        ├── Crop Loss → Intimation Form → Filing Form
        ├── Premium Calculator → Result
        ├── Batch Upload → Progress Screen
        ├── Schemes → Scheme Details
        ├── Profile → Edit Profile
        ├── Complaints → Complaint Detail
        ├── Feedback → My Reports
        └── Language Settings → Language Selection
```

### Officer Flow
```
App Launch → Splash → Dashboard Selection
    → Officer Dashboard
        ├── Claims Review (filter: all/pending/approved/rejected)
        ├── Satellite Map
        ├── District Efficiency Score
        ├── Admin Feedback View
        └── Language Settings
```

### Authentication Flow
```
Dashboard Selection Screen
    ↓ [Login button]
Enhanced Login Screen
    ├── Email+Password → local SharedPreferences lookup → Dashboard
    ├── Email OTP → Gmail SMTP send → OTP verify → Demo user inject → Dashboard
    └── Register → Farmer/Officer Registration → SharedPreferences + MongoDB save → Auto-login → Dashboard
```

> **Note:** The router `redirect` callback is stubbed (`return null`) — there is **no enforced auth guard**. Any route is accessible without login.

---

## 7. Dependencies

### Core Framework
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | UI framework |
| `go_router` | ^17.0.0 | Declarative navigation |
| `provider` | ^6.1.5+1 | State management |
| `google_fonts` | ^6.3.2 | Typography (Poppins, NotoSans, Roboto) |

### Firebase
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^3.6.0 | Firebase initialization |
| `firebase_auth` | ^5.3.1 | Firebase authentication |
| `cloud_firestore` | ^5.4.4 | Document database |
| `firebase_storage` | ^12.3.4 | File storage (declared, lightly used) |

### Camera & Media
| Package | Version | Purpose |
|---------|---------|---------|
| `camera` | ^0.11.0+2 | Camera access & AR overlay |
| `image_picker` | ^1.1.2 | Gallery/camera image selection |
| `flutter_image_compress` | ^2.3.0 | Image compression before upload |
| `image` | ^4.3.0 | Perceptual hashing (deduplication) |

### Location
| Package | Version | Purpose |
|---------|---------|---------|
| `geolocator` | ^13.0.2 | GPS coordinates |
| `geocoding` | ^3.0.0 | Reverse geocoding (coords → city name) |
| `sensors_plus` | ^6.0.1 | Accelerometer for tilt detection in AR |

### Backend / Storage
| Package | Version | Purpose |
|---------|---------|---------|
| `mongo_dart` | ^0.10.3 | MongoDB Atlas direct connection |
| `shared_preferences` | ^2.3.3 | Local key-value storage |
| `path_provider` | ^2.1.5 | App file paths |

### Network & Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.2.0 | REST API calls (Cloudinary, Weather, Sentinel Hub) |
| `connectivity_plus` | ^6.1.0 | Network state monitoring |
| `mailer` | ^6.1.2 | Email OTP via SMTP |
| `url_launcher` | ^6.3.1 | Open external URLs |
| `intl` | ^0.19.0 | Date/number formatting |
| `uuid` | ^4.5.1 | UUID generation for IDs |

### Security & Crypto
| Package | Version | Purpose |
|---------|---------|---------|
| `crypto` | ^3.0.3 | SHA-256 hashing |
| `bcrypt` | ^1.1.3 | bcrypt (declared but SHA-256 is actually used) |

### Maps & Satellite
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_map` | ^7.0.2 | OpenStreetMap/Leaflet-style maps |
| `latlong2` | ^0.9.1 | Lat/Long types |

### ML / Translation
| Package | Version | Purpose |
|---------|---------|---------|
| `google_mlkit_translation` | ^0.13.0 | On-device translation (40+ languages) |

### Background & Notifications
| Package | Version | Purpose |
|---------|---------|---------|
| `workmanager` | ^0.6.0 | Background tasks (15-min sync) |
| `flutter_local_notifications` | ^18.0.1 | Upload sync notifications |

### UI / Animation
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_animate` | ^4.5.2 | Declarative animations |
| `shimmer` | ^3.0.0 | Loading shimmer effects |
| `lottie` | ^3.3.2 | Lottie JSON animations |
| `fl_chart` | ^0.69.0 | Charts for analytics |

---

## 8. Database / API Layer

### Local Storage (SharedPreferences)
- **Users list** (`krashi_bandhu_users`): JSON-encoded list of all registered users
- **Current user** (`krashi_bandhu_user`): JSON-encoded active session
- **Login flag** (`krashi_bandhu_is_logged_in`): Boolean
- **Language preference** (`app_language`): Language code string
- **Pending uploads** (`pending_uploads`): JSON array of `PendingUpload` objects
- **Image hashes** (`uploaded_image_hashes`): Perceptual hash strings for deduplication

### MongoDB Atlas
**Database:** `pmfby-app`  
**Collections:**

| Collection | Contents |
|------------|---------|
| `farmers` | Farmer documents (`FarmerModel`) — name, Aadhaar hash, address, land parcels, crop history |
| `officials` | Officer documents (`OfficialModel`) — name, phone, role, permissions, district |
| `crop_images` | Image metadata — farmerId, parcelId, Cloudinary URL, GPS coords, AI inference results |
| `claims` | Insurance claim documents — farmerId, crop, damage %, status, payout |
| `ai_inferences` | ML model outputs (placeholder for future AI integration) |
| `satellite_data` | Cached satellite observation data |
| `audit_logs` | Change audit trail |
| `feedback_reports` | Farmer feedback with status, category, priority |

**Connection:** Direct `mongo_dart` driver to MongoDB Atlas cluster (`cluster0.erhip.mongodb.net`). Credentials embedded as `--dart-define` defaults with hardcoded fallback values.

**Indexes created on startup:**
- `farmers.farmerId` (unique), `farmers.phone`, `farmers.aadhaar.number`
- `crop_images.imageId` (unique), `farmerId`, `parcelId`, compound `{farmerId, season}`
- `claims.claimId` (unique), `farmerId`, `status`, compound `{farmerId, season}`
- `officials.userId` (unique), `phone`
- `feedback_reports.farmerId`, `status`, `category`, `priority`, `createdAt`

### Firebase Firestore
**Collections:**

| Collection | Contents |
|------------|---------|
| `users` | `UserProfile` documents — name, phone, village, district, crops, land area |
| `crop_images` | Crop image metadata linked to farmer UID |
| `insurance_claims` | Insurance claim records per farmer |

> Firestore is used primarily through `FirestoreService` for the **Firebase-authenticated session flow**. The MongoDB path is for the **local-auth session flow**. The two authentication systems run in parallel without a unified identity layer.

### Cloudinary (Image CDN)
- **Upload URL:** `https://api.cloudinary.com/v1_1/dxahqsgwv/image/upload`
- **Upload preset:** `pmfby-app`
- **Folder:** `pmfby_crops`
- Images compressed to 500 KB max before upload, uploaded via `http.MultipartRequest`
- Metadata (farmerId, imageType) stored in Cloudinary `context` field

---

## 9. External Services

| Service | Integration | Status |
|---------|-------------|--------|
| **Firebase Auth** | `firebase_auth` SDK | Wired but secondary to local auth |
| **Cloud Firestore** | `cloud_firestore` SDK | Used for user profiles, crop images, claims |
| **Firebase Storage** | `firebase_storage` SDK | Declared as dependency, not visibly used |
| **MongoDB Atlas** | `mongo_dart` (direct TCP) | Primary backend for farmer/official data |
| **Cloudinary** | REST API via `http` | Image CDN for crop photos |
| **OpenWeatherMap** | REST API via `http` | Weather data (API key hardcoded: `b6907d289e10d714a6e88b30761fae22`) |
| **Sentinel Hub (ESA)** | REST API via `http` | Satellite imagery (OAuth2 client_credentials) |
| **Google ML Kit Translation** | `google_mlkit_translation` | On-device translation for 40+ languages |
| **Gmail SMTP** | `mailer` package | Email OTP delivery |
| **OpenStreetMap** | `flutter_map` tile layers | Base map for satellite screen |

---

## 10. Build Configuration

### SDK Requirements
- **Dart SDK:** `^3.9.0`
- **Flutter:** Compatible with SDK 3.9+

### Environment Variables (via `--dart-define`)
```
MONGO_USER       → MongoDB Atlas username (default: 'rohanbairagi')
MONGO_PASSWORD   → MongoDB Atlas password (default: 'rohan123')
MONGO_CLUSTER    → Atlas cluster host (default: 'cluster0.erhip.mongodb.net')
MONGO_DB         → Database name (default: 'pmfby-app')
```

### `.idx/dev.nix` (Firebase Studio)
The project uses Firebase Studio's `.idx` workspace environment for development.

### Launcher Icons
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/background.jpg"
  adaptive_icon_background: "#FFFFFF"
```

### Target Platforms
- **Primary:** Android (explicitly enabled in launcher icons)
- **Web:** Scaffolded (`web/` directory exists)
- **iOS:** Not configured (launcher icons disabled)

### Lint Rules
- Uses `flutter_lints/flutter.yaml` (recommended set)
- No custom rules added or rules disabled — default out-of-the-box

---

## 11. Code Quality Assessment

### Strengths
- **Feature-first structure** provides good module separation intent
- **Resilient initialization** — every external service wrapped in timeout + catch-continue
- **Rich localization** — static string maps for 16 languages is thorough
- **AR Camera implementation** is technically impressive (1,770 lines, multiple animation controllers, validation engine)
- **Perceptual hash deduplication** (aHash) is a thoughtful implementation for preventing duplicate uploads
- **Aadhaar Verhoeff validation** correctly implements the checksum algorithm
- **Clean provider usage** — providers properly disposed and not leaked
- **Type safety** — models implement `toJson`/`fromJson` consistently

### Weaknesses
- **Massive screens** — `officer_dashboard_screen.dart` (1,963 lines), `weather_screen.dart` (72 KB), `dashboard_screen.dart` (1,387 lines) are excessively large and violate single-responsibility
- **Duplicated auth systems** — Firebase Auth and local SharedPreferences auth run in parallel with no reconciliation layer, creating identity confusion
- **Demo data hardcoded** — Officer dashboard statistics and claims are hardcoded `Map<String, dynamic>` lists (not fetched from any backend)
- **Inconsistent architecture** — only `auth/` follows clean architecture; all other features are flat or two-layer at best
- **`print()` used in production** — multiple files use `print()` instead of `debugPrint()` or a logging framework (e.g., `weather_service.dart`, `image_deduplication_service.dart`)
- **No unit tests** — `test/` directory exists but appears empty or minimal
- **Backup file in production** — `enhanced_satellite_screen_backup.dart` (61 KB) committed to source
- **Unresolved git merge conflict** — `main.dart` line 207 contains raw git conflict markers (`<<<<<<< HEAD`, `=======`, `>>>>>>> 7714536`)
- **Router auth redirect is a stub** — `redirect: (context, state) { return null; }` means any route is fully accessible without authentication
- **bcrypt declared but SHA-256 used** — `bcrypt` package listed in `pubspec.yaml` but actual password hashing uses `crypto` (SHA-256)
- **Missing `copyWith` immutability** — `FarmerModel`, `OfficialModel` lack `copyWith` methods
- **`AppStrings` locale map is incomplete** — many language entries only have 8–10 languages while the app advertises 16

---

## 12. Technical Debt

| Debt Item | Severity | Location |
|-----------|----------|----------|
| Git merge conflict markers in source | 🔴 Critical | `lib/main.dart:207–215` |
| No auth route guard (redirect stub) | 🔴 Critical | `lib/main.dart` router |
| Passwords stored and compared in plaintext | 🔴 Critical | `auth_service.dart:271` |
| Hardcoded MongoDB credentials in config | 🔴 Critical | `mongodb_config.dart:8–11` |
| Hardcoded Cloudinary API secret in source | 🔴 Critical | `cloud_image_service.dart:13` |
| Hardcoded OpenWeatherMap API key in source | 🔴 Critical | `weather_service.dart:8` |
| OTP stored in-memory Map (not secure, not persistent) | 🟠 High | `email_otp_service.dart:19` |
| Backup `.dart` file committed | 🟠 High | `satellite/enhanced_satellite_screen_backup.dart` |
| Sentinel Hub credentials as `YOUR_*` placeholders | 🟠 High | `sentinel_hub_service.dart:13–15` |
| Demo hardcoded data presented as real | 🟡 Medium | `officer_dashboard_screen.dart:51–64` |
| Two parallel auth systems (Firebase + local) | 🟡 Medium | `main.dart`, `dashboard_screen.dart` |
| `bcrypt` dep declared but unused | 🟡 Medium | `pubspec.yaml:83` |
| Screen files >1,000 lines (God widgets) | 🟡 Medium | 5+ screens |
| `print()` instead of `debugPrint()` | 🟡 Medium | Multiple service files |
| Incomplete language translations | 🟡 Medium | `app_localizations.dart` |
| No integration/widget tests | 🟡 Medium | `test/` directory |
| `demo_farmer_001` user hardcoded in `main.dart` | 🟢 Low | `main.dart:113` |
| Hardcoded "Anshika" profile in dashboard | 🟢 Low | `dashboard_screen.dart:91` |
| `salt` generated from timestamp (weak entropy) | 🟢 Low | `security_service.dart:36` |

---

## 13. Performance Concerns

### Memory
- **Massive localization file loaded entirely** — `app_localizations.dart` (150 KB, 3,600+ lines) is a single class with all language maps as `static const`. This is loaded entirely into memory at startup.
- **`LanguageProvider` translation cache** grows unbounded until language changes. For long sessions with many unique strings, this could grow significantly.
- **Multiple `AnimationController`s per screen** — AR Camera has 5+ controllers; dashboard and splash have 3 each. All appear to be disposed correctly, but the overhead is non-trivial.

### Network
- **MongoDB direct TCP connection from mobile** — Connecting to MongoDB Atlas directly from a mobile app bypasses any API gateway. Latency on mobile networks will be significant, and the 3-second timeout may frequently trigger.
- **No HTTP caching** for OpenWeatherMap or Sentinel Hub responses.
- **Cloudinary upload without retry** — single attempt with no exponential backoff.

### UI Rendering
- **`setState()` on scroll offset** in `DashboardScreen._scrollController` — triggers a full `setState` on every scroll frame, causing unnecessary rebuilds of the entire dashboard.
- **`print()` calls in production builds** — logging in hot paths (weather, image services) adds minor overhead.

### Startup
- Firebase + MongoDB initialization happen sequentially with timeouts, adding up to ~8 seconds of potential blocking at startup if both are slow.

### Background Sync
- WorkManager registers a 15-minute periodic task, which is the minimum allowed interval. This is correct but means batching logic must handle upload failures gracefully.

---

## 14. Security Concerns

### Critical Issues

#### 1. Plaintext Password Storage & Comparison
```dart
// auth_service.dart:271
if (user.email == email && user.password == password) { ... }
```
Passwords are stored as plaintext JSON strings in `SharedPreferences`. Any app with file system access (rooted device, ADB) can extract all user credentials. `SecurityService.hashPassword()` exists but is **not used** by `AuthService`.

#### 2. Hardcoded API Credentials in Source Code
| Secret | File | Value |
|--------|------|-------|
| MongoDB password | `mongodb_config.dart` | `'rohan123'` (default) |
| Cloudinary API secret | `cloud_image_service.dart` | `'X2GoZB5cN3lnPSE4HEuOAby1m80'` |
| OpenWeatherMap API key | `weather_service.dart` | `'b6907d289e10d714a6e88b30761fae22'` |

All three are committed to version control. An attacker with repository access can use these directly.

#### 3. In-Memory OTP Storage
OTPs are stored in a static `Map<String, OTPData>` in `EmailOTPService`. This means:
- OTPs are lost on app restart (users must re-request)
- There is no server-side validation — the client validates its own OTP, which could be bypassed

#### 4. No Auth Route Guard
The GoRouter `redirect` callback returns `null` unconditionally. Any deep link or URL can open any screen without authentication.

#### 5. Direct MongoDB Atlas Connection from Client
The app connects directly to MongoDB Atlas using a connection string with embedded credentials. This approach:
- Exposes credentials in the APK (visible via APK decompilation)
- Bypasses server-side authorization rules
- Allows direct database manipulation from any reverse-engineered client
- Violates MongoDB Atlas best practices (API via backend only)

#### 6. Weak Salt Generation
```dart
// security_service.dart:36
final random = DateTime.now().millisecondsSinceEpoch.toString();
```
The salt is derived from a timestamp, not a cryptographically secure random generator. This makes salts guessable and reduces resistance to precomputed table attacks.

#### 7. Input Sanitization is Incomplete
`SecurityService.sanitizeInput()` strips `$`, `{`, `}`, `[`, `]`, but Dart string interpolation and MongoDB's BSON format are not susceptible to traditional SQL injection — so the sanitization effort is misplaced. The real risk (MongoDB operator injection via map keys like `$where`) is not addressed.

#### 8. Aadhaar Data Handling
Aadhaar numbers are hashed with SHA-256 before MongoDB storage (good), but the display number (`xxxx-xxxx-XXXX`) is derived from the raw number in memory. The plaintext Aadhaar is also stored in SharedPreferences as part of the user JSON — it should be hashed or omitted at rest.

---

*This document was generated by static analysis only — no code was run or modified.*
