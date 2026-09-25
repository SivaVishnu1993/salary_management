# Design Decisions & Trade-offs

A running log of non-obvious choices. Each entry: **decision → why → trade-off**.

## Data model

### Salary history is append-only; the current salary is cached on `employees`
- `salaries` holds one row per pay change (effective-dated). Persisted rows are read-only
  (`Salary#readonly?`), so history doubles as the audit trail. Corrections are recorded as new rows.
- `employees.current_salary_cents/_currency` is a denormalized copy of the latest row. The directory,
  sorting by salary, and every aggregate read one table instead of a lateral join / `DISTINCT ON` over history.
- **Trade-off:** two sources could drift. Mitigation: only `Salaries::Change` writes the cache, in the same
  transaction as the insert, and the seed spec asserts `cache == latest row` for every employee.

### No future-dated salaries
- `effective_date <= today` (validation). A future-dated raise would make the cache wrong until that date,
  requiring a scheduled job to roll it over.
- **Trade-off:** HR can't pre-enter next quarter's raises. That's acceptable for v1 and can be added with a scheduler later.

### Money = integer minor units + ISO currency
- `bigint` cents, never floats; `Money` value object (`Data.define`) with `BigDecimal` conversion.
- Every supported currency has 2 minor digits, so no per-currency exponent table is needed yet.
  Adding JPY/KWD-style currencies would require one.

### Country determines currency
- `config/countries.yml` is the single source (code → name, currency). A salary's currency must match its
  employee's country (`CurrencyMatchesCountryValidator`, reused by `Employee` and `Salary`).

### Static FX table in the database
- Rates come from `config/fx_rates.yml` (versioned, `as_of` date) and are stored in `fx_rates`, so USD
  conversion happens **in SQL** (`FxRate.usd_cents`, built from Arel nodes rather than interpolated strings) and aggregates never load rows into Ruby.
- The directory uses a LEFT JOIN: a missing rate shows a nil USD value rather than hiding an employee.

### Closed list of departments and job titles
- `config/org_structure.yml` defines 8 departments with 5-level ladders. `Employee` validates that the
  title belongs to the department.
- **Why:** free-text titles are what makes spreadsheet pay analysis unreliable ("Sr. Eng" vs "Senior
  Engineer"), and outlier medians group by (country, job title), so titles must be canonical.
- **Trade-off:** adding a title is a config change and deploy, not an HR action. It would become a managed table once HR needs to own it.

### `employee_code` is a stored generated column
- `'ACME-' || lpad(id::text, 6, '0')`, computed by Postgres. It is always unique, never typed by hand,
  works with `insert_all`, and Rails reads it back on insert.
- **Trade-off:** the code is tied to the surrogate id. That's fine for a single system of record.

### Reference data as `Data` value objects, not tables
- `Country`, `Department` and `JobTitle` are immutable in-memory registries loaded from YAML. They are tiny
  and change only on deploy, so a table would just add joins and seeding.

### Integrity enforced in the database too
- `NOT NULL`, `CHECK (amount > 0)`, ISO-format checks on currency, a unique `(employee_id, effective_date)`,
  and an FK with `ON DELETE CASCADE`. Model validations mirror these rules for friendly messages. Specs
  prove the DB rejects bad data even when validations are bypassed.

## Indexes

Each index serves a specific query; unused indexes only slow down writes.

| Index | Serves |
|---|---|
| `employees(email)` UNIQUE, `(employee_code)` UNIQUE | Uniqueness, lookup |
| `employees(country, department)` | Directory filters; by-department insight filtered by country |
| `employees(country, job_title, current_salary_cents)` | Job-title stats and outlier medians: covering index for the aggregate |
| `employees(department)`, `(job_title)` | Filters/GROUP BY without a country (not covered by the composites' leading column) |
| `employees(last_name, first_name, id)` | Default name sort with a stable tie-breaker for pagination |
| `employees(hire_date)` | Hire-date sort |
| GIN trigram on `lower(first_name ‖ last_name ‖ email ‖ code)` | Substring search (`Employee.search`). The expression in the model must match the index exactly |
| `salaries(employee_id, effective_date DESC)` UNIQUE | One change per day; history newest-first; latest-salary lookup |

## Code structure

- **Filter scopes return `all` for blank input** (`in_country(nil)` is a no-op), so query objects can chain
  them unconditionally without `if params[:x]` branches.
- **Custom validators** (`NotInFutureValidator`, `CurrencyMatchesCountryValidator`) instead of
  per-model methods: the same rule is shared by `Employee` and `Salary`.
- **`Monetizable` concern:** both models expose a cents/currency pair, so `monetize :name` builds the `Money` reader once.

## API design

### Response envelope and errors
- Success: `{ data }`, and lists add `meta: { page, per_page, total, total_pages }`. Errors always use
  `{ error: { code, message, details? } }`. 422 `details` are keyed by field (`salary.amount_cents` for nested
  input), so the UI puts each message next to its input.
- Login failures return one generic message for an unknown email or a wrong password. `authenticate_by`
  hashes even when no user matches, so response timing doesn't reveal which accounts exist.

### Pagination lives in `Paginator`, not in the query object
- The prompt put pagination in `EmployeesQuery`. It is split out instead: `PageRequest` validates and clamps
  params (a bad page never causes a 500), and `Paginator` (pagy under the hood) pages *any* relation. The same code
  serves the directory, salary history and outliers, and a query object has one job.
- OFFSET pagination with a total count, because HR expects "page N of M". Keyset is the upgrade path (see PERFORMANCE.md).

### Salary history is its own paginated endpoint
- `GET /employees/:id/salaries` rather than embedding history in the employee payload, so no endpoint
  returns an unbounded collection.

### Pay changes only through `POST /employees/:id/salaries`
- `PATCH /employees/:id` ignores salary fields. One code path (`Salaries::Change`) writes pay, locks the
  employee row, allows back-dated corrections, and always points the cache at the latest *effective* date.
- **Known limitation:** a relocation (country change) needs a salary in the new currency, so the API
  rejects a country change that mismatches the current salary (422). The UI disables the country field
  when editing. A "relocate" operation (new country + new salary atomically) is the natural next feature.

### Salary sanity limit
- Found while testing the UI: one extra paste turned A$188,300 into A$188 billion. Salaries worth more than
  **$10M USD** are now rejected server-side (`Salary#amount_plausible`). The UI also asks for explicit confirmation of
  changes of ±50% or more. The API doesn't rely on the client to catch typos in the most sensitive field.

### `/meta/filters` is not cached server-side
- It's served from YAML config (countries, departments, the FX version) with zero DB queries, so caching it
  would add invalidation work and save nothing. The client keeps it for the whole session.

### Insights results are plain hashes
- Every insight returns JSON-ready data, which makes it trivially cacheable (no Marshal'd AR objects) and
  lets the controller render it directly.
- **Outlier peer group = (country, job title), at least 5 peers.** Peers share a currency, so no FX conversion
  distorts the comparison. A median of 2–3 people isn't a benchmark. The threshold is clamped to 1–200%.
- **Job-title stats group by title only.** The department is implied by the title, which lets the covering index
  answer from the index alone (5.8 ms → 1.2 ms; see PERFORMANCE.md).

## Caching

- **What is cached:** the five insight endpoints (full-table aggregates that HR reloads often).
- **Not cached:** the directory and employee detail. They're already fast via indexes, and stale personal data costs more
  than the few milliseconds saved.
- **Invalidation by versioned keys:** keys embed `Insights::CacheVersion` (a random token in the cache) and the
  FX table version. Any committed write to employees or salaries bumps the token (`after_commit`, via the
  `InvalidatesInsightsCache` concern), which makes every old key unreachable at once. No key scanning, no
  `delete_matched`; old entries expire by TTL (12 h).
- **Bulk writes skip callbacks.** The seed generator bumps the version explicitly. This bug was caught by the
  end-to-end UI test: after a reseed, the dashboard served pre-seed totals. It now has a spec.
- **Decorator (`Insights::Cached`):** insight services know nothing about caching, so they're unit-tested
  without it. `race_condition_ttl` prevents a stampede of simultaneous refreshes when a hot key expires.
- **Resilience:** tight Redis timeouts plus an error handler mean a Redis outage turns into cache misses
  (Postgres answers), never a 500. A spec proves this against an unreachable Redis.

## Security

- bcrypt passwords (`has_secure_password`), a min length of 8.
- JWT HS256, 8 h expiry, issuer check, `alg: none` rejected, secret from `JWT_SECRET` (required in production).
- **Token in `localStorage` (trade-off):** simple, survives reloads, and has no CSRF surface because the token is sent as a
  header. The risk is theft by injected scripts (XSS). The production alternative is an httpOnly, SameSite cookie
  plus CSRF protection, or short-lived access tokens with refresh-token rotation. React escapes output by default
  and there is no `dangerouslySetInnerHTML`.
- Strong parameters everywhere. Sort columns are whitelisted. Search input goes through `sanitize_sql_like`. SQL fragments
  are constants or Arel nodes (Brakeman: 0 warnings).
- Emails and tokens are filtered from logs.
- Out of scope (documented in REQUIREMENTS.md): roles, SSO, refresh tokens, login rate limiting (`rack-attack` would be
  the next addition).

## Frontend

- **Feature folders + shared components.** Each feature owns its `api.ts`, hooks, components and pages.
  Generic UI (`ServerDataGrid`, `FilterBar`, `QueryStateBoundary`, `StatTile`, `MoneyText`, `ConfirmDialog`)
  is written once.
- **Server-mode DataGrid:** pagination and sorting go to the API, and filters live in `FilterBar`. The browser holds one
  page. `keepPreviousData` avoids flicker between pages.
- **TypeScript `strict` + `noUncheckedIndexedAccess`, ESLint `strictTypeChecked`**, no `any`.
- **Charts:** single-series horizontal bars (long category names stay readable), one validated hue per
  mode, no legend (the title names the series), and a chart/table toggle for exact values and accessibility.
  Deviation chips carry an arrow and text, not colour alone.
- **Money input** is in major units and converted to integer cents at the API boundary (`toCents`).
- **Frontend tests are out of scope** by agreement. Quality comes from strict typing and linting. The
  main flows were exercised end-to-end in headless Chrome during development.
- **Bundle:** ~356 kB gzipped main chunk (MUI + DataGrid). Charts are code-split. Acceptable for an
  internal tool; vendor chunking is a cheap next step.

## Infrastructure

- **Redis cache store** (dev/production), replacing the Rails 8 Solid Cache default. It uses tight timeouts
  and an error handler: Redis being down means cache misses, not failed requests. Tests use `:memory_store`
  so the suite needs no Redis server.
- **Bullet** raises in tests: an N+1 fails the spec that caused it.
- **Docker:** multi-stage production images. The API is non-root, uses jemalloc and has a health check; the SPA is served
  by nginx, which also reverse-proxies `/api`, so the browser sees one origin and CORS is unnecessary. `docker compose up`
  is the one-command path for reviewers. The entrypoint runs `db:prepare`, then `db:seed_if_empty`, so the first boot
  seeds and restarts never wipe data. `FORCE_SSL` defaults to on and is turned off only for local plain-HTTP runs.
  Kubernetes/Helm was deliberately not added, as it would be overkill for a single-service app.
- **Removed unused frameworks** (Action Mailer/Cable/Text, Active Storage, Active Job). Less surface area, faster boot.
