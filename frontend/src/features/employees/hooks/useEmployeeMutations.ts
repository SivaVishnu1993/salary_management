import { useMutation, useQueryClient } from '@tanstack/react-query'
import {
  changeSalary,
  createEmployee,
  deleteEmployee,
  updateEmployee,
  type EmployeeProfileInput,
  type SalaryInput,
} from '../api'
import { employeeKeys, insightsKey } from '../queryKeys'

/** Refetches everything a payroll write can affect: employee views and aggregates. */
function useInvalidatePayroll() {
  const queryClient = useQueryClient()
  return () =>
    Promise.all([
      queryClient.invalidateQueries({ queryKey: employeeKeys.all }),
      queryClient.invalidateQueries({ queryKey: insightsKey }),
    ])
}

export function useCreateEmployee() {
  const invalidate = useInvalidatePayroll()
  return useMutation({
    mutationFn: ({ profile, salary }: { profile: EmployeeProfileInput; salary: SalaryInput }) =>
      createEmployee(profile, salary),
    onSuccess: invalidate,
  })
}

export function useUpdateEmployee(id: number) {
  const invalidate = useInvalidatePayroll()
  return useMutation({
    mutationFn: (profile: Partial<EmployeeProfileInput>) => updateEmployee(id, profile),
    onSuccess: invalidate,
  })
}

export function useDeleteEmployee() {
  const queryClient = useQueryClient()
  const invalidate = useInvalidatePayroll()
  return useMutation({
    mutationFn: (id: number) => deleteEmployee(id),
    onSuccess: async (_data, id) => {
      queryClient.removeQueries({ queryKey: employeeKeys.detail(id) })
      await invalidate()
    },
  })
}

export function useChangeSalary(id: number) {
  const invalidate = useInvalidatePayroll()
  return useMutation({ mutationFn: (salary: SalaryInput) => changeSalary(id, salary), onSuccess: invalidate })
}
