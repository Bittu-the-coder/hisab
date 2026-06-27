# Hisab Backend

Node.js + Express + MongoDB API for the Hisab expense tracker.

## Setup

```bash
pnpm install
cp .env.example .env
```

Edit `.env` with your MongoDB URI and JWT secrets. Then:

```bash
pnpm dev     # Development (nodemon auto-reload)
pnpm start   # Production
```

## API Endpoints

Base: `http://localhost:5000/api`

### Health
- `GET /api/health` — Server status check

### Auth
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register` | Register (body: name, email, password) |
| POST | `/api/auth/login` | Login (body: email, password) → accessToken + refreshToken |
| POST | `/api/auth/refresh` | Refresh access token (body: refreshToken) |
| POST | `/api/auth/logout` | Invalidate refresh token (auth required) |

### Expenses (auth required)
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/expenses` | List (query: month, year, category, page, limit, search, date) |
| POST | `/api/expenses` | Create (body: title, amount, category, date, note, paymentMode, tags, groupId?) |
| GET | `/api/expenses/:id` | Get single expense |
| PATCH | `/api/expenses/:id` | Update |
| DELETE | `/api/expenses/:id` | Delete (cascades to GroupExpense if linked) |

### Budgets (auth required)
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/budgets` | Get budget (query: month, year) |
| POST | `/api/budgets` | Create/update (body: categories[{category, limit}]) |
| PATCH | `/api/budgets/:id` | Update |
| DELETE | `/api/budgets/:id` | Delete budget |

### Insights (auth required)
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/insights/summary` | Monthly summary (query: month, year) |
| GET | `/api/insights/category-breakdown` | Per-category totals |
| GET | `/api/insights/daily-log` | Daily spending breakdown |
| GET | `/api/insights/monthly-trend` | Last N months (query: months) |
| GET | `/api/insights/budget-status` | Budget vs actual comparison |

### Groups (auth required)
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/groups` | List user's groups |
| POST | `/api/groups` | Create (body: name, icon) |
| POST | `/api/groups/join` | Join by inviteCode |
| GET | `/api/groups/:id` | Group details + expenses + balances |
| PUT | `/api/groups/:id` | Update name/icon (admin only) |
| DELETE | `/api/groups/:id` | Delete group + cascade GroupExpenses (admin only) |
| POST | `/api/groups/:id/expenses` | Add group expense directly |
| GET | `/api/groups/:id/expenses` | List group expenses |
| GET | `/api/groups/:id/balances` | Get simplified balances |

### User (auth required)
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/users/me` | Get profile |
| PATCH | `/api/users/me` | Update profile |

## Data Model

- **Amounts** are stored as integers in **paise** (×100). The app divides by 100 for display.
- **Expense** with a `groupId` creates both an `Expense` and a `GroupExpense` record linked via `expenseRef`.
- Deleting an `Expense` that has a `groupId` cascades to its linked `GroupExpense`.
- Deleting a `Group` cascades to all its `GroupExpense` documents.

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `MONGODB_URI` | Yes | MongoDB connection string |
| `JWT_SECRET` | Yes | Access token signing key (≥32 chars) |
| `JWT_REFRESH_SECRET` | Yes | Refresh token signing key (≥32 chars) |
| `NODE_ENV` | No | `development` (default) or `production` |
| `PORT` | No | Server port (default: 5000) |
