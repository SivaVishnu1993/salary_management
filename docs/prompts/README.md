# How AI was used

**Tool:** Claude Code (agentic CLI in VS Code), with Claude doing the implementation under human direction.
**Principle:** the human owns scope, constraints and review. The AI drafts, implements and verifies its own
work with tools (specs, linters, `EXPLAIN`, a headless browser) rather than asserting that it works.

## Workflow

1. **Requirements first.** The assessment brief was given to the AI, which asked clarifying questions (stack,
   UI library, deployment, pace) before writing anything. It then drafted [REQUIREMENTS.md](../REQUIREMENTS.md).
2. **Human review of the requirements:** switch SQLite → **PostgreSQL**; bring **JWT login** into scope
   (roles, SSO and refresh tokens stay out).
3. **A master build prompt** ([01-build-prompt.md](01-build-prompt.md)) turned the requirements into build instructions:
   stack, domain model, API, architecture, testing standards and a staged plan. The human then tightened it
   over several rounds:
   - "follow **SOLID**, design patterns, a reusable structure, **services**, **concerns** where required, **scopes**,
     for both backend and frontend"
   - "no frontend tests; **RSpec** for the backend"
   - "ensure **RuboCop** coverage", which became zero offenses plus a 90% SimpleCov gate
   - "ensure **DB optimisation**: queries, **N+1** handling, **indexes and composite indexes**, **remote (server-side)
     pagination**, **Redis cache** where required", which became the *Database performance* and *Caching* sections
4. **Staged execution** of the prompt: scaffold and models → auth → employees API → insights → seeds, caching and
   performance → frontend → polish. Mid-way, the human asked to pull the seed and login forward and to add
   controller (request) specs, then asked to "complete everything", frontend included.
5. **Human-owned git history:** the AI was told not to commit; the human commits each stage.
6. **Docker, added after the core build.** The human asked whether Docker would help the submission. The AI recommended
   production images plus a compose file (reviewers run one command) and advised against Kubernetes. It wrote the files
   before Docker was available but flagged them as unverified, then built and tested the whole stack once Docker was installed.

## How the AI's output was verified

| Check | Tool | Gate |
|---|---|---|
| Behaviour | RSpec: 256 examples, hand-computed expected values for aggregates | all green |
| Coverage | SimpleCov | ≥ 90% line (actual 100% line and branch) |
| N+1 queries | Bullet (`raise = true` in test) plus query-count specs | any N+1 fails |
| Style | RuboCop (omakase + rspec, performance, factory_bot) | 0 offenses, no todo file |
| Security | Brakeman | 0 warnings |
| Query plans | `EXPLAIN ANALYZE` on the 10k seed ([PERFORMANCE.md](../PERFORMANCE.md)) | indexes actually used |
| Docker | `docker compose up --build`, then HTTP checks through nginx and a headless-Chrome run | all services healthy, app works on :8080 |
| Frontend | `tsc --strict`, ESLint `strictTypeChecked`, Prettier, headless-Chrome run of every page, light and dark, desktop and mobile | clean, no console errors |

## What verification caught (and what changed)

Each of these was found by a tool, not by re-reading code:

- **Brakeman flagged interpolated SQL** in the USD conversion. The inputs were constants, so the warnings were false positives,
  but the code was rewritten with Arel and frozen SQL constants rather than silenced.
- **A trigram index silently failed to build**: Rails ignores `opclass:` on expression indexes. The operator class
  moved into the expression, and `EXPLAIN` confirmed a `Bitmap Index Scan` on it.
- **`EXPLAIN` showed the job-title aggregate ignoring the covering index** because of an extra `GROUP BY` column.
  Regrouping by title alone gave an index-only scan: 5.8 ms → 1.2 ms.
- **An end-to-end UI test typed into a pre-filled field** and recorded a salary of **A$188 billion**. That led to a
  server-side $10M (USD) sanity limit plus a UI confirmation for changes of ±50% or more.
- **After a reseed, the dashboard showed stale totals.** `insert_all` skips the `after_commit` cache bump. Fixed in
  the generator, with a spec. The same UI test then matched the hand-calculated payroll delta exactly.
- **The production boot was tested before Docker existed:** the entrypoint was run in `RAILS_ENV=production` against a
  fresh database, which confirmed migrate + seed on first boot and no reseed on restart.
- **The search box appeared broken in the Docker run.** Tracing key events showed no keystrokes reached the page at all:
  Chrome's "save password" prompt, shown after the login *form* submission, takes keyboard focus in headless mode.
  Signing in with a token proved the app was fine (search returns the same 154 results as the API). Temporary debug
  logging was removed afterwards.
- **A spec helper named `change` shadowed RSpec's `change` matcher**, and a query-count spec was flaky on the
  first request (one-time metadata queries). Both were fixed at the root rather than by loosening assertions.

## Deliberate deviations from the build prompt

Recorded in [DECISIONS.md](../DECISIONS.md):
- pagination lives in a reusable `Paginator` instead of the query object
- salary history is its own paginated endpoint
- `/meta/filters` is served from config with no server cache, because there is nothing to cache
