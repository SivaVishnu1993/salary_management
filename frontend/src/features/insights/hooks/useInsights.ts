import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { insightsKey } from '@/features/employees/queryKeys'
import type { InsightFilters } from '@/types/api'
import { fetchByCountry, fetchByDepartment, fetchJobTitles, fetchSummary } from '../api'

// Aggregates change only when payroll is written (which invalidates them), so a
// minute of staleness is safe and avoids refetching on every visit.
const STALE_TIME = 60_000

export function useSummary(filters: InsightFilters) {
  return useQuery({
    queryKey: [...insightsKey, 'summary', filters],
    queryFn: () => fetchSummary(filters),
    staleTime: STALE_TIME,
    placeholderData: keepPreviousData,
  })
}

export function useByCountry(filters: InsightFilters) {
  return useQuery({
    queryKey: [...insightsKey, 'by_country', filters],
    queryFn: () => fetchByCountry(filters),
    staleTime: STALE_TIME,
    placeholderData: keepPreviousData,
  })
}

export function useByDepartment(filters: InsightFilters) {
  return useQuery({
    queryKey: [...insightsKey, 'by_department', filters],
    queryFn: () => fetchByDepartment(filters),
    staleTime: STALE_TIME,
    placeholderData: keepPreviousData,
  })
}

export function useJobTitleStats(country: string, department?: string) {
  return useQuery({
    queryKey: [...insightsKey, 'job_titles', country, department],
    queryFn: () => fetchJobTitles(country, department),
    staleTime: STALE_TIME,
    placeholderData: keepPreviousData,
  })
}
