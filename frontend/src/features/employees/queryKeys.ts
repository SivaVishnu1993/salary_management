import type { EmployeeListParams } from './api'

// Hierarchical keys: invalidating `all` refreshes every employee query.
export const employeeKeys = {
  all: ['employees'] as const,
  lists: () => [...employeeKeys.all, 'list'] as const,
  list: (params: EmployeeListParams) => [...employeeKeys.lists(), params] as const,
  detail: (id: number) => [...employeeKeys.all, 'detail', id] as const,
  salaries: (id: number, page: number, perPage: number) =>
    [...employeeKeys.all, 'salaries', id, page, perPage] as const,
}

// Any payroll write changes the aggregates too.
export const insightsKey = ['insights'] as const
