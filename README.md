# Internal Financial Management Web Application

A complete internal web app for managing crypto and financial transactions with role-based access, client management, unified ledger, audit logs, dashboard analytics, and Excel export.

## Tech Stack
- Backend: Node.js + Express
- ORM/DB: Sequelize + PostgreSQL
- Frontend: HTML + CSS + Vanilla JavaScript
- Auth: JWT
- Export: exceljs

## Project Structure
```
backend/src/
  app.js
  server.js
  config/database.js
  controllers/
  middleware/
  models/
  routes/
  services/
  utils/
frontend/
  index.html
  styles.css
  app.js
schema.sql
```

## Features Implemented
1. JWT authentication and role-based authorization (`admin`, `finance`, `operations`, `viewer`)
2. Dashboard with total transactions, balances, revenue, recent transactions
3. Client CRUD with wallet addresses and per-client transaction history
4. Transaction creation + searchable/filterable listing with pagination
5. Unified ledger table synced with each transaction creation
6. Excel export endpoint with filters, totals row, and summary sheet
7. Audit logs for login, client actions, transaction actions, exports plus read endpoint for admin/finance
8. Responsive UI with sidebar navigation and role-aware controls
9. RESTful API endpoints:
   - `/api/auth`
   - `/api/clients`
   - `/api/transactions`
   - `/api/reports/export`

## Local Setup
1. Install dependencies:
```bash
npm install
```

2. Create PostgreSQL DB, then configure environment:
```bash
cp .env.example .env
# edit .env with your PostgreSQL credentials
```

3. Run the app:
```bash
npm run dev
```

4. Open:
- Frontend: `http://localhost:4000`
- Health: `http://localhost:4000/api/health`

## Seeded Users
On first startup, default users are auto-created:
- `admin@internal.local` / `Admin123!`
- `finance@internal.local` / `Finance123!`
- `ops@internal.local` / `Ops123!`
- `viewer@internal.local` / `Viewer123!`

## API Quick Reference
### Auth
- `POST /api/auth/login`
- `POST /api/auth/logout`

### Clients
- `GET /api/clients`
- `GET /api/clients/:id`
- `POST /api/clients`
- `PUT /api/clients/:id`
- `DELETE /api/clients/:id`

### Transactions
- `GET /api/transactions?search=&asset=&status=&type=&clientId=&startDate=&endDate=&page=&limit=`
- `POST /api/transactions`
- `PUT /api/transactions/:id`

### Reports
- `GET /api/reports/export?startDate=&endDate=&clientId=&asset=`

### Audit
- `GET /api/audit-logs?limit=30`

## Notes
- Sequelize `sync()` is used for fast setup. For production, add migrations.
- JWT expiration is set to 8 hours.
- Audit logging can be extended to include IP/User-Agent metadata.
