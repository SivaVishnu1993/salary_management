# Performance

**Targets** (from [REQUIREMENTS.md](REQUIREMENTS.md)): directory and insights under 300 ms uncached at 10k
employees, cached insights under 20 ms, seed under 15 s.

**Reproduce:** `cd backend && bin/rails db:seed && bin/rails runner script/perf_report.rb`

## Results

Measured on a laptop in the **development** environment (Bullet, verbose query logs and query-log tags
enabled, so production is faster). The timings are in-process requests through the full Rails stack,
including JWT auth, and exclude network time.

- **Seed:** 10,000 employees + 23,079 salary rows in **~5.7 s** (batched `insert_all`, one transaction).

Dataset: 10000 employees, 23079 salary rows. Median of 20 requests, in-process (no network).

| Endpoint | Uncached (ms) | Cached (ms) |
|---|---:|---:|
| Directory, page 1 (default sort) | 20.1 | not cached |
| Directory, filtered + searched + sorted by USD | 15.3 | not cached |
| Directory, deep page (page 300) | 54.9 | not cached |
| Employee detail | 8.9 | not cached |
| Insights summary | 26.3 | 6.4 |
| Insights by country | 30.3 | 7.0 |
| Insights by department | 27.9 | 7.1 |
| Insights job titles (IN) | 13.7 | 7.7 |
| Outliers (20%) | 37.5 | 8.5 |

### Observations

- **Everything is 5–10× under target without caching.** The cache brings insights down to about 7 ms. What
  remains is framework overhead plus the JWT user lookup, so caching matters more for protecting the DB
  under concurrent dashboard use than for single-request latency.
- **Deep pages are the slowest path** (page 300 ≈ 55 ms): `OFFSET 7475` still has to walk the name index up
  to the offset. That's acceptable at this scale, and HR users navigate with filters rather than by paging to page 300.
  Keyset (cursor) pagination on `(last_name, first_name, id)` is the upgrade path if data grows to millions of rows.
- **The directory never joins salary history.** It reads the cached `current_salary_*` columns plus a
  memoized one-row lookup into `fx_rates` (see the `Memoize` node below: 1 miss, 24 hits).

## Query plans (`EXPLAIN ANALYZE`, 10k rows)

### Directory: filtered + searched + sorted

```
Limit (actual time=0.501..0.514 rows=25 loops=1)
  ->  Sort (actual time=0.500..0.507 rows=25 loops=1)
        Sort Key: (round(((employees.current_salary_cents)::numeric * fx_rates.usd_per_unit), 0)) DESC NULLS LAST, employees.id DESC
        Sort Method: quicksort  Memory: 32kB
        ->  Nested Loop Left Join (actual time=0.185..0.424 rows=29 loops=1)
              ->  Bitmap Heap Scan on employees (actual time=0.164..0.370 rows=29 loops=1)
                    Recheck Cond: ((lower((((((((first_name)::text || ' '::text) || (last_name)::text) || ' '::text) || (email)::text) || ' '::text) || (employee_code)::text)) ~~ '%smi%'::text) AND ((country)::text = 'US'::text) AND ((department)::text = 'Engineering'::text))
                    Heap Blocks: exact=29
                    ->  BitmapAnd (actual time=0.144..0.145 rows=0 loops=1)
                          ->  Bitmap Index Scan on index_employees_on_search_document (actual time=0.061..0.061 rows=219 loops=1)
                                Index Cond: (lower((((((((first_name)::text || ' '::text) || (last_name)::text) || ' '::text) || (email)::text) || ' '::text) || (employee_code)::text)) ~~ '%smi%'::text)
                          ->  Bitmap Index Scan on index_employees_on_country_and_department (actual time=0.071..0.071 rows=1032 loops=1)
                                Index Cond: (((country)::text = 'US'::text) AND ((department)::text = 'Engineering'::text))
              ->  Memoize (actual time=0.001..0.001 rows=1 loops=29)
                    Cache Key: employees.current_salary_currency
                    Cache Mode: logical
                    Hits: 28  Misses: 1  Evictions: 0  Overflows: 0  Memory Usage: 1kB
                    ->  Index Scan using fx_rates_pkey on fx_rates (actual time=0.010..0.010 rows=1 loops=1)
                          Index Cond: ((currency)::text = (employees.current_salary_currency)::text)
Planning Time: 1.791 ms
Execution Time: 0.630 ms
```

### Directory: default sort, page 1

```
Limit (actual time=0.040..0.172 rows=25 loops=1)
  ->  Nested Loop Left Join (actual time=0.039..0.169 rows=25 loops=1)
        ->  Index Scan using index_employees_on_last_name_and_first_name_and_id on employees (actual time=0.021..0.121 rows=25 loops=1)
        ->  Memoize (actual time=0.001..0.001 rows=1 loops=25)
              Cache Key: employees.current_salary_currency
              Cache Mode: logical
              Hits: 24  Misses: 1  Evictions: 0  Overflows: 0  Memory Usage: 1kB
              ->  Index Scan using fx_rates_pkey on fx_rates (actual time=0.007..0.007 rows=1 loops=1)
                    Index Cond: ((currency)::text = (employees.current_salary_currency)::text)
Planning Time: 0.240 ms
Execution Time: 0.200 ms
```

### Search only

```
Limit (actual time=0.101..0.214 rows=25 loops=1)
  ->  Bitmap Heap Scan on employees (actual time=0.100..0.211 rows=25 loops=1)
        Recheck Cond: (lower((((((((first_name)::text || ' '::text) || (last_name)::text) || ' '::text) || (email)::text) || ' '::text) || (employee_code)::text)) ~~ '%kumar%'::text)
        Heap Blocks: exact=18
        ->  Bitmap Index Scan on index_employees_on_search_document (actual time=0.075..0.075 rows=154 loops=1)
              Index Cond: (lower((((((((first_name)::text || ' '::text) || (last_name)::text) || ' '::text) || (email)::text) || ' '::text) || (employee_code)::text)) ~~ '%kumar%'::text)
Planning Time: 0.148 ms
Execution Time: 0.238 ms
```

### Job titles in one country

```
GroupAggregate (actual time=0.169..1.331 rows=40 loops=1)
  Group Key: job_title
  ->  Index Only Scan using index_employees_on_country_job_title_salary on employees (actual time=0.044..0.715 rows=2494 loops=1)
        Index Cond: (country = 'IN'::text)
        Heap Fetches: 0
Planning Time: 0.194 ms
Execution Time: 1.369 ms
```

### Salary history for one employee

```
Limit (actual time=0.053..0.055 rows=3 loops=1)
  ->  Incremental Sort (actual time=0.052..0.053 rows=3 loops=1)
        Sort Key: effective_date DESC, id DESC
        Presorted Key: effective_date
        Full-sort Groups: 1  Sort Method: quicksort  Average Memory: 25kB  Peak Memory: 25kB
        ->  Index Scan using index_salaries_on_employee_id_and_effective_date on salaries (actual time=0.028..0.030 rows=3 loops=1)
              Index Cond: (employee_id = 10000)
Planning Time: 0.279 ms
Execution Time: 0.074 ms
```

## Index tuning found by this report

The first version of the job-title insight grouped by `(department, job_title)`. Postgres then used the
`(country, department)` index, fetched 2,494 heap rows and sorted them (**5.8 ms**). Job titles are
unique across departments, so grouping by `job_title` alone lets the covering index
`(country, job_title, current_salary_cents)` answer the query as an **index-only scan with 0 heap fetches
(1.2 ms)**, shown above. The department is derived from the title in Ruby.

## Guardrails in the test suite

- **Bullet raises in tests:** any N+1 fails the spec that caused it.
- **Query-count assertions:** the directory request spec proves the query count stays the same for 2 and 12
  employees (≤ 3 queries: user lookup, COUNT, page SELECT). Cached insight and `/meta/filters` specs prove
  that only the auth lookup hits the database.
- **Pagination bounds:** `per_page` is capped at 100, so no request can pull the whole table.
