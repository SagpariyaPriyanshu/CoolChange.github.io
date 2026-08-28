# CoolChange backend

Story 0.3 scaffold on the `backend` branch: folder layout, a local PostGIS database, and a local API server. Domain tables and read-only heat-map endpoints are not in this commit — they wait until Yu and Yipu lock the schema.

Team: FOXES EAT IT. Stack matches the onboarding project: **Node.js 20 + Express + PostgreSQL/PostGIS**.

---

## How to run the server

From the `backend/` folder:

```bash
nvm use          # Node 20 (.nvmrc)
npm install
cp .env.example .env
npm run db:up    # start local PostGIS (Docker)
npm run migrate  # enable PostGIS
npm run dev      # http://localhost:3000
```

Checks:

| URL | What it tells you |
|-----|-------------------|
| http://localhost:3000/health | process is up |
| http://localhost:3000/health/db | Postgres is reachable and PostGIS is installed |
| http://localhost:3000/api | placeholder for the future read-only API |

Production-style start (no reload): `npm start`.

Stop the database: `npm run db:down`.

### Without Docker (Homebrew Postgres)

Docker Desktop is the default. If it is not installed, a local Homebrew Postgres also works for this scaffold (PostGIS will be skipped until you use the Compose image):

```bash
brew services start postgresql@16
createdb coolchange   # skip if it already exists
```

In `.env`, use port 5432 and your macOS user (no password):

```
DATABASE_URL=postgres://localhost:5432/coolchange
DATABASE_SSL=false
```

Then `npm run migrate` and `npm run dev` as above.

### Tests

```bash
npm test
```

`/health` and `/api` do not need the database. `/health/db` does.

---

## How to connect the database

Local development uses Docker Compose, not a cloud RDS instance.

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and start it.
2. From `backend/`, run `npm run db:up` (wraps `docker compose up -d`).
3. Wait until the `db` service is healthy (`npm run db:logs` if it hangs).
4. Copy `.env.example` to `.env`. The default URL is:

```
postgres://coolchange:coolchange@localhost:5433/coolchange
```

| Piece | Value |
|-------|--------|
| Host | `localhost` |
| Port | `5433` (mapped from container `5432` so Homebrew Postgres on 5432 is left alone) |
| Database | `coolchange` |
| User / password | `coolchange` / `coolchange` |
| SSL | off (`DATABASE_SSL=false`) |

GUI clients (TablePlus, DBeaver, psql) use the same URL. Example:

```bash
psql postgres://coolchange:coolchange@localhost:5433/coolchange
```

When Savio has cloud RDS ready, point `DATABASE_URL` at that instance and set `DATABASE_SSL=true`. Do not commit `.env`.

The only migration in this scaffold is `001_enable_postgis.sql`. Mesh-block / heat / projection tables will be added as later numbered files under `src/db/migrations/` after the schema is agreed.

---

## Folder structure

```
CoolChange/
├── README.md                 # team / project stub (repo root)
├── .gitignore
└── backend/                  # this service (Story 0.3)
    ├── README.md             # this file
    ├── package.json
    ├── .env.example          # copy to .env (not committed)
    ├── .nvmrc                # Node 20
    ├── docker-compose.yml    # local PostGIS
    ├── src/
    │   ├── index.js          # Express entry: CORS, routes, listen
    │   ├── config/index.js   # PORT, DATABASE_URL, DATABASE_SSL
    │   ├── db/
    │   │   ├── pool.js       # shared pg pool
    │   │   ├── migrate.js    # applies migrations/*.sql in order
    │   │   ├── migrations/   # 001_enable_postgis.sql (domain SQL later)
    │   │   └── seeds/        # empty until Yu hands off joined data
    │   ├── routes/
    │   │   ├── health.js     # GET /health and GET /health/db
    │   │   └── api.js        # GET /api placeholder
    │   └── services/         # query helpers once endpoints exist
    └── tests/                # Jest + supertest
```

Git: `main` → `development` → `backend`. Keep backend work on this branch until it merges into `development`.

---

## Commands

| Command | What it does |
|---------|----------------|
| `npm run db:up` | Start local PostGIS |
| `npm run db:down` | Stop local PostGIS (volume kept) |
| `npm run db:logs` | Follow database logs |
| `npm run migrate` | Apply pending SQL migrations |
| `npm run dev` | API with reload |
| `npm start` | API without reload |
| `npm test` | Jest |

---

## Environment variables

| Variable | Meaning | Default |
|----------|---------|---------|
| `PORT` | API port | `3000` |
| `NODE_ENV` | `development` / `production` | `development` |
| `DATABASE_URL` | Postgres connection string | local Docker URL above |
| `DATABASE_SSL` | `true` for RDS | `false` |
