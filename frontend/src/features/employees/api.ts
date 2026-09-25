import { http } from '@/lib/http'
import { compactParams } from '@/lib/queryString'
import type { ApiResponse, Employee, Paginated, Salary } from '@/types/api'

export type EmployeeSortKey =
  'name' | 'employee_code' | 'country' | 'department' | 'job_title' | 'hire_date' | 'salary_usd'

export interface EmployeeListParams {
  q?: string
  country?: string
  department?: string
  job_title?: string
  sort?: EmployeeSortKey
  direction?: 'asc' | 'desc'
  page: number
  per_page: number
}

export interface EmployeeProfileInput {
  first_name: string
  last_name: string
  email: string
  department: string
  job_title: string
  country: string
  hire_date: string
}

export interface SalaryInput {
  amount_cents: number
  effective_date: string
  note?: string
}

export async function listEmployees(params: EmployeeListParams): Promise<Paginated<Employee>> {
  const { data } = await http.get<Paginated<Employee>>('/employees', { params: compactParams(params) })
  return data
}

export async function getEmployee(id: number): Promise<Employee> {
  const { data } = await http.get<ApiResponse<Employee>>(`/employees/${id}`)
  return data.data
}

export async function createEmployee(profile: EmployeeProfileInput, salary: SalaryInput): Promise<Employee> {
  const { data } = await http.post<ApiResponse<Employee>>('/employees', { employee: { ...profile, salary } })
  return data.data
}

export async function updateEmployee(id: number, profile: Partial<EmployeeProfileInput>): Promise<Employee> {
  const { data } = await http.patch<ApiResponse<Employee>>(`/employees/${id}`, { employee: profile })
  return data.data
}

export async function deleteEmployee(id: number): Promise<void> {
  await http.delete(`/employees/${id}`)
}

export async function listSalaries(
  employeeId: number,
  page: number,
  perPage: number,
): Promise<Paginated<Salary>> {
  const { data } = await http.get<Paginated<Salary>>(`/employees/${employeeId}/salaries`, {
    params: { page, per_page: perPage },
  })
  return data
}

export async function changeSalary(employeeId: number, salary: SalaryInput): Promise<Salary> {
  const { data } = await http.post<ApiResponse<Salary>>(`/employees/${employeeId}/salaries`, { salary })
  return data.data
}
