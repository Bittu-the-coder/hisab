# Hisab — Personal Expense Tracker

> **Know where your money goes.**

Hisab is a clean, open-source expense tracking app for individuals and friend groups. Track daily spending, set category-wise budgets, visualize spending patterns through charts, and split shared expenses with friends — all in one app.

---

## Features

### Personal Finance

| Feature | Description |
|---|---|
| **Expense Logging** | Quick 3-tap flow: add title, amount, category, and you're done. Supports notes, tags, and payment modes (cash, UPI, card, netbanking). |
| **Monthly Dashboard** | See current month's total spending, expense count, daily averages, and top spending categories at a glance. |
| **Budget Management** | Set a monthly budget with per-category limits (food, transport, shopping, etc.). Get alerts when you're close to exceeding limits. |
| **Category Breakdown** | Pie chart showing exactly where your money went this month — tap any slice to see only that category's expenses. |
| **Daily Log** | Calendar view with spending marked per day. Tap any date to see all transactions for that day. |
| **Monthly Trends** | Bar chart of spending over the last 6 months — spot seasonal patterns at a glance. |
| **Search & Filter** | Filter expenses by category or search by title/note across any month. |

### Group Expenses

| Feature | Description |
|---|---|
| **Groups** | Create groups with a custom icon and invite code. Friends join by entering the code. |
| **Shared Expenses** | Add an expense to a group — it appears both in your personal log and the group's expense list. |
| **Balance Tracking** | Automatic balance calculation shows who owes whom. Tap any group expense to view its full detail. |
| **Group Management** | Edit group name/icon, invite members, or delete a group (admin only). |

### App Experience

| Feature | Description |
|---|---|
| **Dark & Light Themes** | Toggle between themes from the profile screen — your preference is saved. |
| **Onboarding** | First launch shows a 3-page intro with animated brand logo. |
| **Smooth Navigation** | Bottom tab bar with fade-transition page animations. Back button closes the app only from main tabs (sub-pages navigate back normally). |
| **Offline Handling** | Dashboard gracefully shows a zeroed summary with an offline banner when there's no connection. |
| **Real-Time Updates** | Adding or deleting an expense instantly refreshes dashboard, insights, and budget data. |

---

## Tech Stack

| Layer | Technology |
|---|---|
| **App** | Flutter 3.x (Dart) — Riverpod (state), GoRouter (navigation), Dio (HTTP) |
| **Backend** | Node.js + Express + Mongoose (MongoDB ODM) |
| **Database** | MongoDB Atlas (M0 free tier — ~512 MB storage) |
| **Auth** | JWT with access + refresh token rotation |
| **Hosting** | Vercel (serverless functions) |

---

## Project Structure

```
hisab/
├── backend/                 # Node.js Express API
│   ├── src/
│   │   ├── app.js           # Express app entry point
│   │   ├── config/          # Database connection, env config
│   │   ├── controllers/     # Auth, Expense, Budget, Group, Insights, User
│   │   ├── middleware/       # Auth middleware (JWT verification)
│   │   ├── models/          # Mongoose schemas
│   │   ├── routes/          # Route definitions per resource
│   │   └── services/        # Budget checker, debt simplifier
│   ├── .env.example
│   └── package.json
│
├── app/                     # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart        # App entry, theme loading
│   │   ├── app.dart         # GoRouter + ShellRoute + status bar
│   │   ├── core/
│   │   │   ├── theme/       # AppColors, light/dark themes
│   │   │   ├── utils/       # Currency formatter, date helpers
│   │   │   └── constants/   # API base URL
│   │   ├── data/
│   │   │   ├── models/      # Expense, Budget, Group, User models
│   │   │   ├── services/    # ApiService (Dio + JWT refresh)
│   │   │   └── repositories/ # Data access layer per model
│   │   ├── providers/       # Riverpod providers & notifiers
│   │   └── presentation/
│   │       ├── screens/     # 13 screens (splash, auth, dashboard,
│   │       │                #   expenses, insights, profile, groups, budget)
│   │       └── widgets/     # Shared widgets (category chip, logo, etc.)
│   └── pubspec.yaml
│
├── README.md                # You are here
├── LICENSE                  # MIT
└── .gitignore
```

---

## Setup Guide

### Prerequisites

- **Flutter 3.x** ([install guide](https://docs.flutter.dev/get-started/install))
- **Node.js 18+** + **pnpm** (`npm i -g pnpm`)
- **MongoDB Atlas** account (free tier: https://www.mongodb.com/atlas)

### 1. Backend Setup

```bash
cd backend

# Install dependencies
pnpm install

# Create environment file
cp .env.example .env
```

Edit `backend/.env` and fill in:

| Variable | Description | Example |
|---|---|---|
| `MONGODB_URI` | MongoDB connection string | `mongodb+srv://user:pass@cluster.abcde.mongodb.net/hisab?retryWrites=true&w=majority` |
| `JWT_SECRET` | Random string for access tokens | `your-access-secret-at-least-32-chars` |
| `JWT_REFRESH_SECRET` | Random string for refresh tokens | `your-refresh-secret-at-least-32-chars` |
| `NODE_ENV` | Environment mode | `development` or `production` |

Start the backend:

```bash
pnpm dev     # Development with auto-reload (nodemon)
# or
pnpm start   # Production start
```

Server runs on `http://localhost:5000`. Verify: `curl http://localhost:5000/api/health`

### 2. App Setup

```bash
cd app

# Get Flutter dependencies
flutter pub get

# Configure API URL
```

Open `app/lib/core/constants/api_constants.dart` and set:

| Environment | URL |
|---|---|
| **Android emulator** | `http://10.0.2.2:5000/api` (maps to host's localhost) |
| **Physical Android** | `http://<your-computer-ip>:5000/api` (same Wi-Fi required) |
| **Physical iOS** | `http://localhost:5000/api` (macOS) or `http://<your-computer-ip>:5000/api` |
| **Production** | `https://your-app.vercel.app/api` |

Run the app:

```bash
# Connect a device / start emulator, then:
flutter run
```

---

## Detailed Usage Guide

### First Launch

1. **Splash Screen**: The animated Hisab logo fades in with a slide-up effect.
2. **Onboarding**: Three pages introduce expense tracking, budget management, and group sharing. Swipe through or tap "Skip".
3. **Register**: Create an account with name, email, and password.
4. **Login**: Sign in with your email and password.

### Managing Expenses

#### Adding an Expense

1. Tap the **+** FAB (floating action button) on the Expenses tab.
2. Enter a **title** (e.g., "Lunch at Pizza Place").
3. Enter **amount** in rupees (e.g., `450` — stored as `45000` paise internally).
4. Select a **category** (food, transport, shopping, etc.).
5. (Optional) Add a **note**, change **payment mode** (cash/UPI/card), or add **tags**.
6. Tap **Save**. The expense appears instantly in the list, and dashboard/insights update automatically.

#### Viewing Expense Details

Tap any expense in the list to see full details: title, amount, category chip, payment mode, date, note, and tags. From here you can **Edit** or **Delete**.

#### Editing an Expense

1. Open the expense detail screen (tap the expense).
2. Tap **Edit** — make changes to title, amount, category, date, note, payment mode, or tags.
3. Tap **Save**.

#### Deleting an Expense

1. Open the expense detail screen.
2. Tap **Delete** — confirm in the dialog.
3. The expense is removed from personal logs AND from any group it was shared with.

#### Searching & Filtering

- On the Expenses tab, use the **search bar** to find expenses by title or note.
- Tap the **filter icon** to filter by category.

### Dashboard

The Dashboard tab shows your current month at a glance:

- **Total spending** (with currency formatting)
- **Number of expenses** this month
- **Daily average** spending
- **Top spending category** (highlighted card)
- **Recent transactions** (last 5)
- If offline, a banner appears and the summary zeroes out gracefully.

### Budget Management

Access via **Profile → Budget**:

1. Set a **total monthly budget** — it auto-calculates as the sum of category limits.
2. Set **per-category limits**: e.g., Food ₹5000, Transport ₹2000, Shopping ₹3000.
3. Tap **Save**. The backend stores limits and checks them when you add expenses.
4. The Insights tab shows **Budget Status** — a card comparing budget vs actual spending and per-category progress bars.
5. When you exceed a category limit, a **budget alert** shows after adding an expense.
6. To remove a budget, tap **Delete** (red button) — this clears all limits.

### Insights & Analytics

The Insights tab has four sections:

| Tab | What it shows |
|---|---|
| **Summary** | Total spent this month, budget remaining, largest expense |
| **Category Breakdown** | Interactive pie chart — tap a slice to filter expenses for that category |
| **Daily Log** | Calendar grid — dates with spending have colored dots. Tap a date to see all transactions for that day below the calendar |
| **Trend** | Bar chart of spending over the last 6 months |

### Group Expenses

#### Creating a Group

1. Go to **Profile → Groups**.
2. Tap **Create Group** (the full-width button).
3. Enter a **group name** and pick an **icon** (group, people, travel, home, work, etc.).
4. Tap **Create**. An invite code is generated automatically.

#### Joining a Group

1. On the Groups list screen, tap **Join Group** (bottom).
2. Enter the **invite code** shared by the group admin.
3. Tap **Join**. The group appears in your list.

#### Adding a Group Expense

1. Open the group detail screen.
2. Tap the **+** FAB.
3. Fill in title, amount, category like a personal expense.
4. Tap **Save**. The expense appears both:
   - In your **personal expense log** (Expenses tab)
   - In the **group's expense list** (Expenses tab within the group)

> **Note:** Currently the expense is recorded as paid by you with empty splits. Split calculation is coming in a future update.

#### Viewing Group Expenses

- The **Expenses** tab inside a group lists all shared expenses in reverse chronological order.
- **Tap any expense** to open the full expense detail screen (same as personal), where you can edit or delete it.

#### Group Balances

The **Balances** tab shows simplified settlements — who owes whom and how much.

#### Inviting Members

- Open the group detail screen. The **invite code** is displayed below the member avatars.
- Tap the code to **copy** it to your clipboard.
- Share it with friends via WhatsApp, Telegram, etc.

#### Editing a Group (Admin Only)

- Tap the **edit icon** (pencil) in the AppBar to change the group name or icon.

#### Deleting a Group (Admin Only)

- Tap the **delete icon** (trash) in the AppBar.
- Confirm deletion. All group expenses are removed (personal expenses remain in your own log).

### Profile & Settings

The Profile tab shows:

- **Your name** and **email** (displayed at top)
- **Edit Profile** — change name/email/password
- **Budget** — manage monthly budgets
- **Groups** — create, join, and manage groups
- **Theme Toggle** — switch between Light and Dark themes (persisted across sessions)
- **Logout** — signs out and clears all cached data

### Theme

- Toggle between **Light** and **Dark** modes from the Profile screen.
- Your preference is saved using SharedPreferences — no flash on app restart.
- The status bar and app bar use a cohesive dark navy (`#1E2A3A`) in both themes for consistent visibility.

---

## Screenshots

<!--
TODO: Add screenshots here

Suggested screenshots to include:
1. Dashboard (light theme)
2. Expenses list (dark theme)
3. Add expense screen
4. Expense detail screen
5. Category breakdown pie chart
6. Daily log calendar with transactions
7. Monthly trend chart
8. Budget setup screen
9. Budget status card
10. Group detail with expenses
11. Group balances
12. Profile screen
13. Onboarding page
-->

---

## API Overview

All API endpoints are prefixed with `/api`. Protected routes require a Bearer token.

**Auth**: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`

**Expenses**: `GET/POST /expenses`, `GET/PATCH/DELETE /expenses/:id`
- Query params: `month`, `year`, `category`, `page`, `limit`, `search`, `date`

**Budgets**: `GET/POST /budgets`, `PATCH/DELETE /budgets/:id`
- Query params: `month`, `year`

**Insights**: `GET /insights/summary`, `/category-breakdown`, `/daily-log`, `/monthly-trend`, `/budget-status`

**Groups**: `GET/POST /groups`, `POST /groups/join`, `GET/PUT/DELETE /groups/:id`

**User**: `GET/PATCH /users/me`

See [backend/README.md](backend/README.md) for full endpoint details.

---

## Deployment

### Backend (Vercel)

```bash
cd backend
vercel --prod
```

Set environment variables in Vercel dashboard:
- `MONGODB_URI` — your Atlas connection string
- `JWT_SECRET` — random string (≥32 chars)
- `JWT_REFRESH_SECRET` — random string (≥32 chars)
- `NODE_ENV` = `production`

### App (Release Build)

```bash
cd app

# Build split APKs (recommended — smaller per-device)
flutter build apk --release --split-per-abi

# Or universal APK
flutter build apk --release
```

The APK(s) will be in `app/build/app/outputs/flutter-apk/`.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request

Please open an issue before making large changes to discuss the approach.

## License

MIT — see [LICENSE](LICENSE).
