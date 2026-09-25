import { http } from '@/lib/http'
import type { ApiResponse, FilterOptions } from '@/types/api'

export async function fetchFilterOptions(): Promise<FilterOptions> {
  const { data } = await http.get<ApiResponse<FilterOptions>>('/meta/filters')
  return data.data
}
