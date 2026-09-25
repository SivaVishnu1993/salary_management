import { useQuery } from '@tanstack/react-query'
import { fetchFilterOptions } from './api'

/** Countries, departments and job ladders. Reference data: fetched once per session. */
export function useFilterOptions() {
  return useQuery({ queryKey: ['meta', 'filters'], queryFn: fetchFilterOptions, staleTime: Infinity })
}
