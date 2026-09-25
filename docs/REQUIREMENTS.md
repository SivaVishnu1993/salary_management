# ACME Salary Management — Requirements

## Goal

ACME's HR team manages salary data for about 10,000 employees in several countries using spreadsheets. We are replacing those spreadsheets with a web app that lets the **HR Manager**:

1. **Manage** employee and salary records reliably, with one source of truth and no copy/paste drift.
2. **Answer questions about how the org pays people**, such as *"What do we pay a Senior Engineer in India compared with Germany?"*, *"Which department costs the most?"* and *"Who is paid outside the normal range for their role?"*

The app counts as successful when an HR Manager can find any employee in seconds, update pay safely, and answer common pay questions without exporting to Excel.

## Users & assumptions

- **Single persona:** the HR Manager, who signs in and then has full access to all records.
- Each employee is paid in their country's local currency. We keep a **static FX table** so figures can be compared across countries in USD.
- Salary means **annual base salary**. Bonus, equity and allowances are not included.

## In scope

| # | Feature | Details |
|---|---------|---------|
| 1 | **Employee directory** | Server-side pagination, search (name, email, employee code), filters (country, department, job title), and sorting. It must stay fast at 10k+ rows. |
| 2 | **Employee CRUD** | Create, view, edit and delete employees, with validation (unique email/code, required fields, positive salary). |
| 3 | **Salary history** | A salary change adds a new **effective-dated record** instead of overwriting the old one. The employee page shows the history. Pay changes are auditable, which Excel could never guarantee. |
| 4 | **Pay insights dashboard** | Headcount and total payroll (USD) by country and by department. Min, median, average and max salary **by job title within a country**. |
| 5 | **Outlier view** | Lists employees paid more than ±X% from the median for their role and country. This turns data into an action: "who should I review?" |
| 6 | **Authentication (JWT)** | Email and password login for HR users (bcrypt-hashed passwords). The API issues a signed, short-lived JWT (HS256, about 8 hours) and requires it on every endpoint except login. The UI redirects to login on 401. A seeded HR Manager account is provided for the demo. |
| 7 | **Seed script** | Generates 10,000 realistic employees across about 8 countries and about 8 departments, with plausible country-specific salary bands. Runs in seconds and is deterministic (fixed random seed). |

## Deliberately out of scope (and why)

| Left out | Reasoning |
|----------|-----------|
| **RBAC, SSO, refresh tokens, password reset** | There is one persona, so every signed-in user is an HR Manager. Roles, SSO (e.g. Okta), refresh-token rotation and password-reset emails matter in production but add a lot of surface area. When a token expires, the user logs in again. |
| **Payroll processing, tax, payslips** | Different domain with heavy compliance requirements. The problem is *managing and understanding* salary data, not paying it. |
| **Live FX rates** | A static, versioned rate table keeps analytics deterministic and testable. Live rates add an external dependency and make numbers shift day to day. |
| **Excel/CSV bulk import** | Valuable for migration, but mapping and validating messy spreadsheets is a project of its own. The seed script covers the demo data. **CSV export** of filtered lists is a cheap next step. |
| **Approval workflows for pay changes** | Needs multiple personas (manager, finance). History tracking provides auditability without the workflow cost. |
| **Bonus, equity, benefits, performance data** | Keeps the data model focused. The schema can be extended with compensation components later. |
| **Multi-tenant / multi-org** | Single organization (ACME). |

## Non-functional requirements

- **Performance:** directory queries and dashboard aggregates respond in under 300 ms at 10k employees. The approach is indexed filter columns and aggregation in SQL (PostgreSQL `percentile_cont` for medians), not in Ruby.
- **Correctness:** money is stored as **integer minor units + ISO currency code**, never floats.
- **Quality:** fast, deterministic unit and request tests for models, services and API. Frontend tests for key components.
- **Security:** passwords hashed with bcrypt. The JWT secret comes from the environment, never from source. Strong parameters on every write.
- **Stack:** Rails 8 (API mode) + PostgreSQL; React + Vite + MUI. Deployment target to be decided.
