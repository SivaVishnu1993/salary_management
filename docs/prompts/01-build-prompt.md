# Build Prompt — ACME Salary Management

> This is the master prompt for the AI coding agent. It turns [REQUIREMENTS.md](../REQUIREMENTS.md) into build instructions. The agent works in **stages**: it stops after each one, and a human reviews and commits before the next stage begins.

---

## Role & context

You are a senior full-stack engineer. You are building an internal web app for ACME's **HR Manager** to manage salary data for **10,000 employees across multiple countries**, replacing Excel. The HR Manager must be able to (a) maintain employee and salary records and (b) answer questions about how the org pays people.

`docs/REQUIREMENTS.md` is the source of truth for scope. **Do not build anything listed as out of scope.** If a requirement is ambiguous, make the simplest reasonable choice, and write down the choice and why under "Decisions" in your stage summary.

## Tech stack (fixed)

- **Backend:** Ruby 3.4.5, Rails 8, API-only (`rails new backend --api -d postgresql -T`)
- **DB:** PostgreSQL
- **Cache:** Redis via `Rails.cache` (`:redis_cache_store`, `redis` gem). This deliberately replaces the Rails 8 Solid Cache default
- **Pagination:** `pagy` (fast and lightweight), wrapped by the `Paginatable` concern
- **N+1 detection:** `bullet` (dev + test)
- **Auth:** `has_secure_password` (bcrypt) + `jwt` gem
- **Backend tests:** RSpec, FactoryBot, shoulda-matchers, SimpleCov
- **Frontend:** React + TypeScript + Vite in `frontend/`, MUI (`@mui/material`, `@mui/x-data-grid`, `@mui/x-charts`), React Router, TanStack Query, axios
- **Lint:** RuboCop (`rubocop-rails-omakase` + `rubocop-rspec` + `rubocop-performance` + `rubocop-factory_bot`), ESLint + Prettier

Repo layout: `backend/`, `frontend/`, `docs/`, root `README.md`.

## Engineering principles (apply to backend AND frontend)

Code quality is assessed as closely as features. Every stage must follow these principles:

- **SOLID**
  - *Single Responsibility:* each class, module, component or hook has one reason to change. Controllers handle HTTP only, models handle persistence, validations and scopes, and services handle business operations.
  - *Open/Closed:* extend through new classes, not conditionals. For example, a new insight is a new service class and a new sort is a whitelist entry.
  - *Liskov:* subclasses and shared base classes (e.g. `ApplicationService`, `BaseQuery`) must be substitutable.
  - *Interface Segregation:* small, focused interfaces. Components take only the props they need, and services expose one public `call`.
  - *Dependency Inversion:* inject collaborators (e.g. `Salaries::Change.new(fx: FxConverter)`, API client passed or wrapped by hooks) so that units can be tested in isolation.
- **Design patterns, used where they earn their place:** Service Object, Query Object, Serializer / Presenter, Form Object (create employee + initial salary), Result object (`success?` / `errors`), Strategy (e.g. sort handlers), Provider / Context and Custom Hooks on the frontend. Don't add a pattern just to show it off. Record the reason for each non-obvious choice in `docs/DECISIONS.md`.
- **Reusable structure / DRY:** shared behaviour is extracted once and reused, never copy-pasted.
- **Readability:** small methods, intention-revealing names, no magic numbers (use named constants), and a comment only where the *why* isn't obvious.

### Backend conventions (Rails)

- **Thin controllers, thin models, services for business logic.** Controllers parse params → call a service or query → render a serializer. There are no business rules in controllers and no multi-model orchestration in callbacks.
- **Services:** `app/services/<namespace>/<verb>.rb`, inheriting `ApplicationService` with a `self.call(...)` class entry point. They return a `Result` object rather than raising for expected failures.
- **Scopes:** every reusable filter is a named model scope (e.g. `Employee.in_country(code)`, `.in_department(name)`, `.with_job_title(title)`, `.search(term)`, `Salary.effective_on_or_before(date)`, `.chronological`). Query objects and services **compose scopes**. Raw `where` chains repeated across files are not acceptable.
- **Concerns, only when behaviour is genuinely shared:**
  - Controller concerns: `Authenticatable` (JWT), `Paginatable` (page/per_page parsing + meta), `ErrorHandling` (`rescue_from` → consistent error JSON).
  - Model concerns: e.g. `Monetizable` (cents + currency helpers, USD conversion), `Searchable` if reused.
  - Don't use concerns as a dumping ground for code that belongs to a single class.
- **Serializers:** a `BaseSerializer` with a shared collection / pagination envelope. Each resource has its own serializer.
- Strong parameters in controllers. Constants and config (countries, FX, pagination limits) live in one place.

### Frontend conventions (React)

- **Feature-based folders:** `src/features/{auth,employees,insights,outliers}/` each hold that feature's `components/`, `hooks/` and `api.ts`. Shared code goes in `src/components/` (generic UI), `src/hooks/`, `src/lib/` (formatters, http client) and `src/types/`.
- **Separate logic from presentation:** data fetching and state live in custom hooks (`useEmployees`, `useEmployee`, `useChangeSalary`, `useInsights`, `useAuth`) built on TanStack Query. Components mostly render.
- **Reusable components:** e.g. `DataTable` wrapper, `FilterBar`, `MoneyText`, `StatTile`, `PageHeader`, `ConfirmDialog`, `QueryStateBoundary` (loading, empty and error). No duplicated table, filter or error-state markup across pages.
- **Single HTTP layer:** one configured axios instance with interceptors (auth header, 401 handling). Feature `api.ts` files wrap it with typed functions, and components never import axios.
- **Types:** shared TypeScript types for API contracts. `strict` mode. No `any`.
- Composition over prop drilling (context for auth and theme only).

## Domain model

```
users        id, name, email (unique, citext or downcased), password_digest, timestamps
employees    id, employee_code (unique, e.g. "ACME-000123"), first_name, last_name,
             email (unique), job_title, department, country (ISO-3166 alpha-2),
             hire_date, current_salary_cents (bigint), current_salary_currency (char 3),
             timestamps
salaries     id, employee_id (FK, cascade), amount_cents (bigint > 0), currency (char 3),
             effective_date, note (optional), timestamps
             UNIQUE (employee_id, effective_date)
fx_rates     currency (PK, char 3), usd_per_unit (decimal 18,8), timestamps
```

Rules:
- **Money is always integer minor units + ISO currency code.** Never floats. Any USD conversion is done in SQL or with `BigDecimal`.
- The country determines the currency, through a single `Country` config (e.g. `config/countries.yml` or a Ruby constant): code → name, currency. Supported countries: US, GB, DE, IN, CA, AU, SG, BR. A salary's currency **must** match its employee's country currency.
- `salaries` is the **source of truth and audit trail**. Salary rows are never updated in place: a pay change always inserts a new row.
- `employees.current_salary_*` is a **denormalized cache** of the latest salary. It exists so the directory and aggregates don't need a lateral join. It is written **only** by the `Salaries::Change` service, inside the same transaction as the insert. `effective_date` cannot be in the future, which keeps the cache correct without a scheduler (record this as a decision).
- Departments: Engineering, Product, Design, Sales, Marketing, Finance, HR, Operations. Job titles include a level (e.g. "Software Engineer II", "Senior Software Engineer").
- Indexes are covered in detail under **Database performance** below.

## Backend architecture

Keep controllers thin. Put logic in plain Ruby objects under `app/`:

- `app/queries/employees_query.rb`: composes model scopes for filtering and search; also handles sorting (whitelisted columns only) and pagination.
- `app/services/salaries/change.rb`: validates and inserts a salary row, then updates the employee cache, all in one transaction.
- `app/services/insights/*.rb`: pay statistics and outliers, computed **in SQL** (`GROUP BY`, `percentile_cont(0.5) WITHIN GROUP`).
- `app/services/auth/json_web_token.rb`: encodes and decodes JWTs (HS256, `exp` = 8h). The secret comes from `ENV["JWT_SECRET"]`, falling back to `secret_key_base` only in dev and test.
- `app/serializers/*`: plain Ruby serializer classes (no serializer gem).
- `Authenticatable` concern → `authenticate!`: reads `Authorization: Bearer <token>` and returns 401 if the token is missing, invalid or expired. It applies to every endpoint except login.
- `ErrorHandling` concern: every error uses one JSON shape, `{ "error": { "code": "validation_failed", "message": "...", "details": { field: [msgs] } } }`, returned with 401 / 404 / 422 through `rescue_from`.

## API (all under `/api/v1`, JSON)

| Method & path | Purpose |
|---|---|
| `POST /auth/login` | `{email, password}` → `{token, user}`; 401 on bad credentials (generic message) |
| `GET /auth/me` | Current user |
| `GET /employees` | Params: `q`, `country`, `department`, `job_title`, `sort` (`name`, `hire_date`, `salary_usd`, `country`…), `direction`, `page`, `per_page` (default 25, max 100) → `{data: [...], meta: {page, per_page, total, total_pages}}`. Each row includes local salary and a USD equivalent. |
| `GET /employees/:id` | Employee + salary history (newest first) |
| `POST /employees` | Create employee **with initial salary** (one transaction) |
| `PATCH /employees/:id` | Update profile fields only (not salary). Changing country with a mismatched currency → 422 |
| `DELETE /employees/:id` | Delete employee and their salaries |
| `POST /employees/:id/salaries` | Salary change `{amount_cents, effective_date, note}` via `Salaries::Change` |
| `GET /meta/filters` | Countries (with currency), departments, distinct job titles |
| `GET /insights/summary` | Total headcount, total annual payroll (USD), median salary (USD) |
| `GET /insights/by_country` | Per country: headcount, total payroll (local + USD), median, average (USD) |
| `GET /insights/by_department` | Per department: headcount, total payroll (USD), average (USD). Optional `country` filter |
| `GET /insights/job_titles?country=XX` | Per job title in one country: headcount, min / median / avg / max in **local currency** |
| `GET /insights/outliers` | Params `threshold_pct` (default 20), optional `country`, `department`. Employees whose salary deviates > threshold from the median for their **(country, job_title)** group, with their deviation % and the group median. Paginated |

The outlier median is computed within one country, so every value is in one currency and no FX conversion is needed. Note this in the code.

## Seed script (`db/seeds.rb` → delegates to `Seeds::Generator`)

- Generates **10,000 employees** deterministically (`Random.new(42)`; seed Faker with the same RNG if Faker is used). Realistic country mix (e.g. US 30%, IN 25%, GB 10%…).
- Salary bands per (country, job level) are plausible. Each employee gets 1–4 historical salary rows with raises going upward over time, and the cache columns match the latest row.
- Seeds FX rates and one HR user: `hr@acme.test`, password from `ENV["SEED_ADMIN_PASSWORD"]` (default `password123` for dev only).
- Uses `insert_all` in batches (no per-row `create!`) and is idempotent: it clears the tables first. Target: **under 15 s**. Print timing and row counts.
- Includes a spec that runs the generator with a small `count:` and asserts the invariants (cache equals latest salary, currencies match countries).

## Frontend

- Pages: **Login**, **Employees** (directory), **Employee detail** (profile, salary history table, "Change salary" dialog), **Employee form** (create/edit), **Insights** (dashboard), **Outliers**.
- The directory uses MUI DataGrid in **server mode** (pagination, sorting and filtering are sent to the API). Search is debounced by 300 ms. Filters and pagination are kept in the URL query string so views can be shared and bookmarked.
- Insights: KPI tiles (headcount, payroll USD, median USD); bar charts by country and by department; a country selector that drives the job-title stats table (local currency).
- Outliers: threshold slider/input, country and department filters, a table with a deviation % chip (red above the median, amber below). Each row links to the employee.
- Auth: an `AuthProvider` context holds the token in `localStorage` (trade-off: simple, but exposed to XSS; the production alternative is an httpOnly cookie, to be written up in the docs). An axios interceptor attaches the Bearer header and, on 401, clears the token and redirects to `/login`. Routes are protected with a `RequireAuth` wrapper.
- Currency display uses `Intl.NumberFormat` with the row's currency. All API calls live in one typed `src/api/` module, and components never call axios directly.
- Loading, empty and error states exist on every data view. Form validation errors from the 422 `details` are shown on the matching fields.

## Database performance

The app must stay fast at 10k employees (about 30k salary rows) and scale sensibly beyond that. Every stage that touches queries must follow these rules.

### Server-side ("remote") pagination, everywhere

- **Every list endpoint is paginated on the server:** employees, outliers, salary history, and job-title stats if they can be large. No endpoint returns an unbounded collection.
- `page` and `per_page` are parsed and clamped in `Paginatable` (default 25, **max 100**). A response always includes `meta: {page, per_page, total, total_pages}`. An invalid page (e.g. `page=0`, `page=abc`) falls back safely and never raises a 500.
- The frontend DataGrid runs with `paginationMode="server"`, `sortingMode="server"` and `filterMode="server"`, and never loads the full dataset. TanStack Query uses `placeholderData: keepPreviousData` so rows don't flicker between pages.
- *Decision to record:* OFFSET pagination with a total count is fine at 10k rows, and it supports "jump to page N", which HR users expect. Keyset/cursor pagination is the documented path if the data grows to millions of rows.

### Query rules

- **No N+1 queries.** Use `includes` / `preload` / `eager_load` deliberately whenever serializers touch associations. **Bullet** runs in development (log + footer) and in test with `Bullet.raise = true`, so an N+1 fails the spec suite.
- **Push work into SQL:** aggregates use `GROUP BY` / `percentile_cont` / `SUM` / `COUNT` in one query per insight, never Ruby `map` / `sum` over loaded records. Use `pluck` / `select` for only the columns a response needs. Don't use `.count` on already-loaded relations (use `.size`), and don't call `.all.each` (use `find_each` for batch jobs).
- The directory list reads the cached `current_salary_*` columns on `employees` and does **not** join `salaries`. The USD value comes from a single join to `fx_rates`, a tiny table. Sort columns are whitelisted and mapped to SQL expressions, with `id` as a tie-breaker so page order is stable.
- **Seeds and bulk writes use `insert_all`** in batches (e.g. 1,000 rows). No per-row callbacks.
- **The database enforces integrity**, not just model validations: `NOT NULL`, foreign keys (`on_delete: :cascade` for salaries), `CHECK (amount_cents > 0)`, and unique indexes. Models mirror these rules for friendly error messages.

### Indexes (single + composite)

Each index must match a real query. Write the justification in a migration comment and in `docs/DECISIONS.md`:

| Index | Serves |
|---|---|
| `employees(email)` UNIQUE, `employees(employee_code)` UNIQUE | Uniqueness + lookup |
| `employees(country, department)` | Directory filters, by-department insight with a country filter |
| `employees(country, job_title, current_salary_cents)` | Job-title stats + outlier median per (country, job_title), a covering index for the aggregate |
| `employees(department)` | Department-only filter and `GROUP BY` (the leading column of the composite above doesn't cover it) |
| `employees(job_title)` | Job-title-only filter |
| `employees(last_name, first_name, id)` | Default name sort + stable pagination |
| `employees(hire_date)` | Hire-date sort |
| GIN `pg_trgm` on `first_name`, `last_name`, `email`, `employee_code` (or one expression index on their concatenation) | `ILIKE '%term%'` search |
| `salaries(employee_id, effective_date DESC)` UNIQUE | Salary history for one employee, latest-salary lookup, and one-change-per-day enforcement |

Don't add indexes nothing uses: each one slows down writes.

### Verification

- Stage 5 includes `EXPLAIN ANALYZE` output for the directory (filtered + searched + sorted), the insights and the outliers queries on the 10k seed, recorded in `docs/PERFORMANCE.md` with the latency measured before and after caching.
- Request specs assert query counts for list endpoints (e.g. with a small `expect { }.to make_database_queries(count: ...)` helper or `ActiveSupport::Notifications`), so a regression fails the build.

## Caching (Redis)

Cache only where it clearly helps. The candidates are expensive, read-heavy data that changes rarely:

| Cached | Why | Key |
|---|---|---|
| `/insights/summary`, `/by_country`, `/by_department`, `/job_titles` | Full-table aggregates that HR reloads often | `insights/v{data_version}/{name}/{params-digest}` |
| `/insights/outliers` (per threshold + filters + page) | Window/median computation over all employees | same versioned scheme |
| `/meta/filters` | Distinct values, which almost never change | `meta/filters/v{data_version}` |
| FX rate map | Read on every salary conversion | `fx_rates/v{fx_version}` |

**Not cached:** the employee directory and employee detail. They are already cheap thanks to indexes, and a stale personal record causes more harm than a few milliseconds cost.

- **Invalidation:** a `CacheVersion` / `PayrollDataVersion` helper keeps a version counter in Redis. It is **bumped after commit** (`after_commit`, or explicitly inside the `Salaries::Change` / employee create, update and destroy services) whenever employees or salaries change. Bumping the version makes every old key unreachable in one step, with no key scanning or `delete_matched`. The seed script bumps it as well.
- Insight services receive the cache store through a small `Cacheable` wrapper (e.g. `Insights::Cached.new(Insights::ByCountry, cache: Rails.cache)`, a Decorator pattern). The query logic itself doesn't know about caching, so it can be unit-tested without it.
- Every entry has a TTL (e.g. 12 h) as a safety net, and uses `race_condition_ttl` against a stampede of simultaneous refreshes.
- **Resilience:** if Redis is down, the app must still work. The Redis cache store must log and fall through to the DB, never return a 500. There is a spec for this.
- **Config:** `REDIS_URL` comes from the environment. Development uses Redis; **test uses `:memory_store`** (plus `:null_store` where specs must not cache), so specs need no Redis server. Specs cover a cache hit, invalidation after a salary change, and the fallback.
- The frontend also caches with TanStack Query (`staleTime` of about 60 s for insights and filters) and invalidates the relevant query keys after a mutation.

## Static analysis & coverage (backend)

- **RuboCop covers all Ruby code:** `app/`, `lib/`, `config/`, `db/` (migrations and seeds) and `spec/`. Exclude only generated files (`db/schema.rb`, `bin/`, `vendor/`).
- The `.rubocop.yml` inherits `rubocop-rails-omakase` and enables the `rubocop-rspec`, `rubocop-performance` and `rubocop-factory_bot` plugins. Any cop that is relaxed or disabled needs a one-line comment in `.rubocop.yml` explaining why.
- **Zero offenses** is part of every stage's definition of done (`bundle exec rubocop`). No inline `# rubocop:disable` without a justification comment next to it. There is **no `.rubocop_todo.yml`**, because the codebase starts clean and stays clean.
- **SimpleCov:** starts at the top of `spec/spec_helper.rb`, with groups for Models / Services / Queries / Controllers / Serializers. `minimum_coverage 90` (line), so the suite fails below it. The coverage % goes in each stage summary.

## Testing standards

- **Backend: RSpec only.** Tests must be **fast and deterministic**: no network, no real time dependencies (`travel_to` / fixed dates), no reliance on seed data, and factories instead of fixtures.
- Backend must cover: model validations; `Salaries::Change` (happy path, currency mismatch, future date, duplicate date, cache update, transaction rollback); `EmployeesQuery` (each filter, search, sort whitelist, pagination bounds); insights services with hand-computed expected numbers on small datasets (including an even-count median); JWT codec (valid, expired, tampered); request specs for every endpoint, including 401 without a token and 422 shapes.
- Model specs also cover **each scope** (it returns the right records and excludes the wrong ones).
- **Frontend tests are out of scope for this project.** Only backend RSpec tests are required. Frontend quality comes from TypeScript strict mode, ESLint and a clean structure.
- Test names state behaviour (`"returns 422 when currency does not match country"`).

## Working agreement

1. Work **one stage at a time**. After each stage, stop and give: what was built, files touched, how to run it and test it, test results, decisions and trade-offs, and anything you're unsure about.
2. **Do not run git commits.** The human reviews and commits each stage.
3. `bundle exec rspec` (coverage ≥ 90%) and `bundle exec rubocop` (0 offenses) must pass before a stage counts as done. Never delete or weaken a test to make it pass.
4. No speculative features, no extra gems without a stated reason, and no secrets in source.
5. Update `README.md` (setup, run, test, demo credentials) and `docs/DECISIONS.md` as you go.

## Stages

| # | Stage | Done when |
|---|---|---|
| 1 | Backend scaffold: Rails API, Postgres, Redis config, RSpec, RuboCop, Bullet, models + migrations (constraints + all indexes above) + validations + scopes, `Country` config, FX rates | Model + scope specs pass, RuboCop 0 offenses, SimpleCov configured |
| 2 | JWT auth: User, login / me endpoints, `authenticate!`, error handling | Auth + 401 request specs pass |
| 3 | Employees API: CRUD, `EmployeesQuery`, `Salaries::Change`, salary endpoint, `/meta/filters`, server-side pagination via `Paginatable` | Service + request specs pass, Bullet raises on no spec, query-count specs pass |
| 4 | Insights + outliers services and endpoints | Specs with hand-computed numbers pass |
| 5 | Seed script: 10k employees; Redis caching layer + invalidation; `EXPLAIN ANALYZE` + latency before and after caching in `docs/PERFORMANCE.md` | Seeds under 15 s, key endpoints under 300 ms uncached, cached insights under 20 ms, Bullet clean |
| 6 | Frontend scaffold: Vite + TS + MUI, routing, API client, auth flow, app layout | Login works against the API; `tsc` + ESLint clean |
| 7 | Employees UI: directory, detail + salary history, create/edit, change salary | Manual flow works; `tsc` + ESLint clean |
| 8 | Insights + outliers UI | Charts render seeded data; `tsc` + ESLint clean |
| 9 | Polish: README, architecture diagram, `docs/DECISIONS.md`, performance notes, final RSpec + lint + coverage run | Fresh clone → setup → run works from README alone |

**Start with Stage 1.**
