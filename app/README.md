# Hisab App

Flutter mobile app for the Hisab expense tracker.

## Setup

### Prerequisites

- Flutter 3.x ([install](https://docs.flutter.dev/get-started/install))
- Android Studio / Xcode (for emulators)
- Backend running (see [backend/README.md](../backend/README.md))

### Install

```bash
flutter pub get
```

### Configure API URL

Open `lib/core/constants/api_constants.dart` and set the base URL:

| Environment | URL |
|---|---|
| Android emulator | `http://10.0.2.2:5000/api` |
| Android physical | `http://<your-ip>:5000/api` |
| iOS simulator | `http://localhost:5000/api` |
| iOS physical | `http://<your-ip>:5000/api` |
| Production | `https://your-api.vercel.app/api` |

### Run

```bash
flutter run
```

## Build Release APK

```bash
# Split APKs (recommended — smaller per-device)
flutter build apk --release --split-per-abi

# Universal APK
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/`

## App Architecture

The app uses **Riverpod** for state management with a clean data flow:

```
Screen (ConsumerWidget/ConsumerStatefulWidget)
  → Provider (ref.watch)
    → Repository (data access layer)
      → ApiService (Dio HTTP client with JWT auto-refresh)
```

### Key Packages

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Declarative routing + bottom nav shell |
| `dio` | HTTP client with interceptors |
| `shared_preferences` | Theme persistence, onboarding flag |
| `fl_chart` | Pie chart (category breakdown), bar chart (monthly trend) |
| `table_calendar` | Daily log calendar view |
| `google_fonts` | Outfit (headings), DM Sans (body) |
| `flutter_launcher_icons` | App icon generation |

### Screens

| Screen | Route |
|---|---|
| Splash | `/` |
| Onboarding | `/onboarding` |
| Login | `/login` |
| Register | `/register` |
| Dashboard | `/home/dashboard` |
| Expenses | `/home/expenses` |
| Add Expense | `/home/expenses/add` |
| Expense Detail | `/home/expenses/:id` |
| Insights | `/home/insights` |
| Profile | `/home/profile` |
| Budget | `/home/profile/budget` |
| Groups List | `/home/profile/groups` |
| Create Group | `/home/profile/groups/create` |
| Group Detail | `/home/profile/groups/:id` |

### Development Notes

- Run `dart analyze lib/` before committing — project aims for 0 errors, 0 warnings.
- Amounts are displayed in rupees but stored as paise (int × 100) via `CurrencyFormatter`.
- Theme preference is persisted in SharedPreferences and loaded via `initialThemeModeProvider` override.
- The app uses `#1E2A3A` (dark navy) for status bar and app bar backgrounds across both themes.
- Back navigation: `PopScope(canPop: !isRoot)` prevents accidental app exit from main tabs.
- Group expense navigation: tapping a group expense opens the personal expense detail via `expenseRef`, and deleting there cascades to both records.
