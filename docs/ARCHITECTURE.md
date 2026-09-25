# Architecture

## System overview

```mermaid
flowchart LR
  HR["HR Manager<br/>(browser)"] -->|HTTPS| SPA["React SPA<br/>Vite · MUI · TanStack Query"]
  SPA -->|"JSON /api/v1<br/>Authorization: Bearer JWT"| API["Rails 8 API<br/>(Puma)"]
  API -->|"indexed queries,<br/>SQL aggregates"| PG[("PostgreSQL 16<br/>employees · salaries · fx_rates · users")]
  API -->|"cached insight results<br/>(versioned keys)"| R[("Redis<br/>Rails.cache")]
  R -. "down → cache miss,<br/>fall through to Postgres" .-> PG
```

- **Stateless API:** a JWT carries the identity, so any Puma worker or instance can serve any request.
- **Postgres is the source of truth.** Redis only holds derived aggregates and can be flushed at any time.
- In development, Vite proxies `/api` to Rails, so the SPA and API share an origin. In production CORS
  is restricted to `CORS_ORIGINS`.

## Request lifecycle (backend)

```mermaid
flowchart TD
  Req[HTTP request] --> Auth["Authenticatable concern<br/>Bearer JWT → current_user (401 otherwise)"]
  Auth --> Ctl["Controller (thin)<br/>strong params → call → render"]
  Ctl -->|lists| Q["Query object<br/>EmployeesQuery composes model scopes"]
  Ctl -->|writes| S["Service objects<br/>Employees::Create · Salaries::Change → Result"]
  Ctl -->|analytics| C["Insights::Cached (decorator)"]
  C -->|miss| I["Insights::* services<br/>one SQL aggregate each"]
  Q --> P["Paginator + PageRequest<br/>COUNT + LIMIT/OFFSET via pagy"]
  S --> M["Models<br/>validations · scopes · DB constraints"]
  P --> Ser["Serializers<br/>plain Ruby, JSON envelope"]
  M -. after_commit .-> V["Insights::CacheVersion.bump!"]
  Ctl --> Err["ErrorHandling concern<br/>{ error: { code, message, details } }"]
```

| Layer | Location | Responsibility |
|---|---|---|
| Controllers | `app/controllers/api/v1` | HTTP only: params, status codes, rendering |
| Concerns | `app/controllers/concerns` | `Authenticatable`, `Paginatable`, `ErrorHandling` (shared by every controller) |
| Query objects | `app/queries` | Read-side composition of scopes, whitelisted sorting |
| Services | `app/services` | Business operations returning `Result`; insight aggregates; JWT; FX config |
| Models | `app/models` | Persistence, validations, scopes; `Monetizable`, `InvalidatesInsightsCache` concerns |
| Value objects | `app/models/{money,country,department,job_title}.rb` | Immutable `Data` types and config-backed registries |
| Validators | `app/validators` | Rules shared across models (currency ↔ country, not-in-future) |
| Seeds | `lib/seeds` | Deterministic generator (weighted sampling, pay bands, names) |

## Data model

```mermaid
erDiagram
  employees ||--o{ salaries : "has history (append-only)"
  employees }o--|| fx_rates : "current_salary_currency"
  employees {
    bigint id PK
    string employee_code "generated: ACME-000123"
    string first_name
    string last_name
    string email UK
    string department
    string job_title
    string country "ISO alpha-2 → currency"
    date hire_date
    bigint current_salary_cents "cache of latest salary"
    string current_salary_currency
  }
  salaries {
    bigint id PK
    bigint employee_id FK "ON DELETE CASCADE"
    bigint amount_cents "CHECK > 0"
    string currency
    date effective_date "UNIQUE per employee"
    string note
  }
  fx_rates {
    string currency PK
    decimal usd_per_unit "static, versioned"
  }
  users {
    bigint id PK
    string email UK
    string password_digest "bcrypt"
  }
```

## Frontend structure

```
src/
  app/          App routes, theme (light + dark), QueryClient
  lib/          http (single axios instance + interceptors), formatters, API error helpers
  types/        API contract types (shared by every feature)
  hooks/        useUrlState (filters in the URL), useDebouncedValue, useChartColor
  components/   AppLayout, PageHeader, FilterBar, ServerDataGrid, QueryStateBoundary,
                StatTile, MoneyText, ConfirmDialog …   (generic, reused across features)
  features/
    auth/       AuthProvider (context), RequireAuth (route guard), LoginPage, api
    meta/       reference data (countries, departments) cached for the session
    employees/  directory, detail + salary history, create/edit, change-salary dialog
    insights/   KPI tiles, payroll-by-country / -department charts, job-title stats
    outliers/   threshold slider, peer-deviation grid
```

- **Data flow:** component → feature hook (TanStack Query) → feature `api.ts` → shared `http` client.
  Components never import axios.
- **Server state lives in TanStack Query.** Query keys are hierarchical, so a salary change invalidates
  `['employees']` and `['insights']` in one call.
- **URL state:** directory, insights and outliers filters and pagination live in the query string, so
  views are shareable and survive reloads.
- **Code splitting:** the chart-heavy Insights and Outliers pages are lazy-loaded.
