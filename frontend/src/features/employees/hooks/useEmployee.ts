import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { getEmployee, listSalaries } from '../api'
import { employeeKeys } from '../queryKeys'

export function useEmployee(id: number) {
  return useQuery({
    queryKey: employeeKeys.detail(id),
    queryFn: () => getEmployee(id),
    enabled: Number.isFinite(id),
  })
}

export function useSalaryHistory(id: number, page: number, perPage: number) {
  return useQuery({
    queryKey: employeeKeys.salaries(id, page, perPage),
    queryFn: () => listSalaries(id, page, perPage),
    placeholderData: keepPreviousData,
    enabled: Number.isFinite(id),
  })
}
