import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { insightsKey } from '@/features/employees/queryKeys'
import { fetchOutliers, type OutlierParams } from '../api'

export function useOutliers(params: OutlierParams) {
  return useQuery({
    queryKey: [...insightsKey, 'outliers', params],
    queryFn: () => fetchOutliers(params),
    staleTime: 60_000,
    placeholderData: keepPreviousData,
  })
}
