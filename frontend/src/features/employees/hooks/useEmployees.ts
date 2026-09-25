import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { listEmployees, type EmployeeListParams } from '../api'
import { employeeKeys } from '../queryKeys'

/** One server-side page of the directory; keeps the previous page on screen while the next loads. */
export function useEmployees(params: EmployeeListParams) {
  return useQuery({
    queryKey: employeeKeys.list(params),
    queryFn: () => listEmployees(params),
    placeholderData: keepPreviousData,
  })
}
