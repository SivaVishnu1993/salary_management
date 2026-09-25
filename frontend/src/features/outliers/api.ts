import { http } from '@/lib/http'
import { compactParams } from '@/lib/queryString'
import type { OutliersResult, PageMeta } from '@/types/api'

export interface OutlierParams {
  threshold_pct: number
  country?: string
  department?: string
  page: number
  per_page: number
}

export async function fetchOutliers(
  params: OutlierParams,
): Promise<{ data: OutliersResult; meta: PageMeta }> {
  const { data } = await http.get<{ data: OutliersResult; meta: PageMeta }>('/insights/outliers', {
    params: compactParams(params),
  })
  return data
}
