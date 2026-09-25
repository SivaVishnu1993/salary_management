// Contracts for the Rails API (/api/v1). Money is always integer minor units + ISO currency.

export interface Money {
  amount_cents: number
  currency: string
}

export interface PageMeta {
  page: number
  per_page: number
  total: number
  total_pages: number
}

export interface Paginated<T> {
  data: T[]
  meta: PageMeta
}

export interface ApiResponse<T> {
  data: T
}

export interface ApiErrorBody {
  error: {
    code: string
    message: string
    details?: Record<string, string[]>
  }
}

export interface User {
  id: number
  name: string
  email: string
}

export interface Session {
  token: string
  token_type: 'Bearer'
  expires_at: string
  user: User
}

export interface Employee {
  id: number
  employee_code: string
  first_name: string
  last_name: string
  full_name: string
  email: string
  department: string
  job_title: string
  country: string
  country_name: string | null
  hire_date: string
  current_salary: Money
  current_salary_usd_cents: number | null
  updated_at: string
}

export interface Salary {
  id: number
  amount_cents: number
  currency: string
  effective_date: string
  note: string | null
  recorded_at: string
}

export interface Country {
  code: string
  name: string
  currency: string
}

export interface JobTitle {
  name: string
  level: number
}

export interface Department {
  name: string
  job_titles: JobTitle[]
}

export interface FilterOptions {
  countries: Country[]
  departments: Department[]
  fx: { version: number; as_of: string }
}

export interface InsightFilters {
  country?: string
  department?: string
}

export interface Summary {
  headcount: number
  total_payroll_usd_cents: number
  median_salary_usd_cents: number | null
  average_salary_usd_cents: number | null
}

export interface CountryInsight {
  country: string
  country_name: string | null
  currency: string | null
  headcount: number
  total_payroll_cents: number
  median_salary_cents: number
  total_payroll_usd_cents: number
  median_salary_usd_cents: number | null
  average_salary_usd_cents: number | null
}

export interface DepartmentInsight {
  department: string
  headcount: number
  total_payroll_usd_cents: number
  median_salary_usd_cents: number | null
  average_salary_usd_cents: number | null
}

export interface JobTitleStat {
  department: string | null
  job_title: string
  level: number | null
  headcount: number
  min_cents: number
  median_cents: number
  average_cents: number
  max_cents: number
}

export interface JobTitleInsights {
  country: string
  currency: string
  job_titles: JobTitleStat[]
}

export interface Outlier {
  employee_id: number
  employee_code: string
  full_name: string
  department: string
  job_title: string
  country: string
  salary_cents: number
  currency: string
  peer_median_cents: number
  peer_count: number
  deviation_pct: number
}

export interface OutliersResult {
  threshold_pct: number
  min_peers: number
  rows: Outlier[]
}
