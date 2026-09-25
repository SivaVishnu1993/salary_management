import { http } from '@/lib/http'
import { compactParams } from '@/lib/queryString'
import type {
  ApiResponse,
  CountryInsight,
  DepartmentInsight,
  InsightFilters,
  JobTitleInsights,
  Summary,
} from '@/types/api'

async function getInsight<T>(path: string, params: object): Promise<T> {
  const { data } = await http.get<ApiResponse<T>>(`/insights/${path}`, { params: compactParams(params) })
  return data.data
}

export const fetchSummary = (filters: InsightFilters) => getInsight<Summary>('summary', filters)

export const fetchByCountry = (filters: InsightFilters) => getInsight<CountryInsight[]>('by_country', filters)

export const fetchByDepartment = (filters: InsightFilters) =>
  getInsight<DepartmentInsight[]>('by_department', filters)

export const fetchJobTitles = (country: string, department?: string) =>
  getInsight<JobTitleInsights>('job_titles', { country, department })
