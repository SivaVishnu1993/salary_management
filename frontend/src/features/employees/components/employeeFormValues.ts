import type { EmployeeProfileInput } from '../api'

export interface EmployeeFormValues extends EmployeeProfileInput {
  salary_amount: string
  salary_effective_date: string
  salary_note: string
}

export const EMPTY_EMPLOYEE_FORM: EmployeeFormValues = {
  first_name: '',
  last_name: '',
  email: '',
  department: '',
  job_title: '',
  country: '',
  hire_date: '',
  salary_amount: '',
  salary_effective_date: '',
  salary_note: '',
}
