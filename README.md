# ACME Salary Management

A web app for ACME's HR Manager to manage salary data for **10,000 employees across 8 countries** and to
answer questions about how the organisation pays people. It replaces a set of spreadsheets.

**What an HR Manager can do**

- **Find anyone in seconds:** server-side search, filters (country, department, job title), sorting and
  pagination over 10k employees, with shareable URLs.
- **Maintain records safely:** create, edit and delete employees. Pay changes are **append-only, effective-dated
  history** (an audit trail Excel never had), with guards against typos and future dates.
- **Answer pay questions:** headcount and payroll by country and department (USD-normalized), and min/median/avg/max
  per job title within a country ("what do we pay a Senior Engineer in India?").
- **Act on it:** the **Pay outliers** view lists people paid more than ±X% from the median of their peers
  (same job title, same country).

| | |
|---|---|
| Requirements (goal, scope, what's left out and why) | [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) |
| Architecture & diagrams | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Design decisions & trade-offs | [docs/DECISIONS.md](docs/DECISIONS.md) |
| Performance (latency, `EXPLAIN ANALYZE`, index tuning) | [docs/PERFORMANCE.md](docs/PERFORMANCE.md) |
| How AI was used (prompts, iterations, what was caught) | [docs/prompts/](docs/prompts/README.md) |

## Stack

| Layer | Technology |
|---|---|
| API | Ruby 3.4, Rails 8.1 (API-only), PostgreSQL 16 (`pg_trgm`), Redis (cache), JWT auth |
| UI | React 19 + TypeScript (strict), Vite, MUI 9 (DataGrid, Charts), TanStack Query, React Router |
| Delivery | Docker (multi-stage production images), docker compose, nginx (serves the SPA, proxies `/api`) |
| Quality | RSpec (256 examples, 100% line and branch coverage, 90% gate), FactoryBot, shoulda-matchers, Bullet (N+1 → failure), RuboCop (0 offenses), Brakeman (0 warnings), ESLint `strictTypeChecked`, Prettier |

## Quick start with Docker (recommended)

Only Docker is required.

```bash
docker compose up --build
```

Open **http://localhost:8080** and sign in with `hr@acme.test` / `password123`.

- **First boot** migrates the database and seeds 10,000 employees (about a minute including image builds).
  Later boots keep your data.
- **Services:**
  - `web`: nginx serving the SPA and proxying `/api`
  - `api`: production Rails image, non-root, with a health check
  - `db`: Postgres 16
  - `redis`
- **Reset to fresh demo data:** `docker compose down -v && docker compose up`
- **Change the port:** `WEB_PORT=9000 docker compose up`
- **Secrets:** the compose file ships demo-only defaults. Override `SECRET_KEY_BASE`, `JWT_SECRET`,
  `POSTGRES_PASSWORD` and `SEED_ADMIN_PASSWORD` in a `.env` file for anything shared.

> These are **production images** (`RAILS_ENV=production`, compiled SPA, no dev or test gems or specs), used here to
> run the finished app with one command. For development (hot reload, running RSpec or RuboCop), use the setup below.

The same images deploy to any container host. `backend/Dockerfile` needs `DATABASE_URL`, `SECRET_KEY_BASE`,
`JWT_SECRET` and optionally `REDIS_URL`. SSL is enforced unless `FORCE_SSL=false`.

## Quick start without Docker

Prerequisites: Ruby 3.4.5, Node 20+, PostgreSQL 16 (with `postgresql-contrib` for `pg_trgm`), Redis 6+.

```bash
# 1. API (http://localhost:3000)
cd backend
bundle install
bin/rails db:prepare     # create + migrate
bin/rails db:seed        # FX rates, HR login, 10,000 employees (~6 s)
bin/rails server

# 2. UI (http://localhost:5173) in a second terminal
cd frontend
npm install
npm run dev              # proxies /api to localhost:3000
```

**Demo login:** `hr@acme.test` / `password123`. Set `SEED_ADMIN_PASSWORD` to change it; it's required in production.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `DB_HOST` / `DB_PORT` | `localhost` / `5432` | Postgres (dev/test) |
| `DB_USERNAME` / `DB_PASSWORD` | `postgres` / `postgres` | Postgres credentials (dev/test) |
| `DATABASE_URL` | – | Production database |
| `REDIS_URL` | `redis://localhost:6379/0` | Cache store (dev/production; tests use an in-memory store) |
| `JWT_SECRET` | `secret_key_base` in dev/test | Token signing key (**required in production**) |
| `CORS_ORIGINS` | `http://localhost:5173` | Allowed SPA origins, comma-separated |
| `SEED_EMPLOYEES` | `10000` | Seed size |
| `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD` | `hr@acme.test` / `password123` | Seeded HR login |
| `VITE_API_URL` (frontend) | `/api/v1` | API base URL for a separately hosted SPA |
| `FORCE_SSL` | `true` | Production only: set `false` to serve plain HTTP (local Docker) |
| `SEED_IF_EMPTY` | – | Container entrypoint: seed demo data on first boot only |

## Tests & quality checks

```bash
cd backend
bundle exec rspec          # fails below 90% line coverage or on any N+1 query
bundle exec rubocop        # 0 offenses
bin/brakeman --no-pager    # 0 warnings

cd frontend
npm run typecheck && npm run lint && npm run format:check && npm run build
```

The backend suite runs in under 10 s. It's deterministic (fixed dates via `travel_to`, factories, no network, no
Redis needed) and covers:
- models, scopes and DB constraints
- services, including hand-computed insight numbers such as an even-count median
- JWT (expired, tampered, `alg=none`)
- every endpoint: 401, 404, 422 shapes
- query counts and cache hit/invalidation/Redis-down fallback
- seed invariants

Performance report on the seeded data: `bin/rails runner script/perf_report.rb`.

## API (`/api/v1`, JSON, `Authorization: Bearer <token>`)

| Method & path | Purpose |
|---|---|
| `POST /auth/login` · `GET /auth/me` | Sign in (returns JWT) · current user |
| `GET /employees` | Directory: `q`, `country`, `department`, `job_title`, `sort` (`name`, `employee_code`, `country`, `department`, `job_title`, `hire_date`, `salary_usd`), `direction`, `page`, `per_page` (≤ 100) |
| `GET/PATCH/DELETE /employees/:id` · `POST /employees` | Employee CRUD. Create takes the starting salary; update is profile-only |
| `GET/POST /employees/:id/salaries` | Paginated salary history · record a pay change |
| `GET /meta/filters` | Countries (with currency), departments and job ladders, FX version |
| `GET /insights/summary` · `by_country` · `by_department` | Headcount and USD payroll (filters: `country`, `department`) |
| `GET /insights/job_titles?country=IN` | Min / median / avg / max per job title in local currency |
| `GET /insights/outliers?threshold_pct=20` | Employees beyond ±threshold of their peer median, paginated |

Errors always use `{ "error": { "code", "message", "details"? } }` (401 / 404 / 422 / 400).

## Repository layout

```
backend/             Rails API: app/{controllers,queries,services,serializers,models,validators}, lib/seeds, spec/
  Dockerfile         production image (multi-stage, non-root, health check)
  bin/docker-entrypoint   db:prepare + seed-on-first-boot, then the server
frontend/            React SPA: src/{app,lib,types,hooks,components,features/*}
  Dockerfile         build with Node, serve with nginx
  nginx.conf.template     SPA fallback, asset caching, /api reverse proxy
docker-compose.yml   db + redis + api + web for one-command local runs
docs/                requirements, architecture, decisions, performance, AI prompts
```

## Not yet done

- **Deployment:** the hosting target is still to be decided. The Docker images above run on any container host.
- **Demo video:** to be recorded against the seeded dataset.
