import ArrowBack from '@mui/icons-material/ArrowBack'
import { Button } from '@mui/material'
import { Link as RouterLink, useNavigate, useParams } from 'react-router-dom'
import { PageHeader } from '@/components/PageHeader'
import { QueryStateBoundary } from '@/components/QueryStateBoundary'
import { errorMessage, fieldErrors } from '@/lib/apiError'
import type { Employee } from '@/types/api'
import { EmployeeForm } from '../components/EmployeeForm'
import { EMPTY_EMPLOYEE_FORM, type EmployeeFormValues } from '../components/employeeFormValues'
import { useEmployee } from '../hooks/useEmployee'
import { useCreateEmployee, useUpdateEmployee } from '../hooks/useEmployeeMutations'

const formValuesFor = (employee: Employee): EmployeeFormValues => ({
  ...EMPTY_EMPLOYEE_FORM,
  first_name: employee.first_name,
  last_name: employee.last_name,
  email: employee.email,
  department: employee.department,
  job_title: employee.job_title,
  country: employee.country,
  hire_date: employee.hire_date,
})

/** Mutation errors: field errors go next to inputs; anything else shows as a banner. */
function formErrorsFor(error: unknown) {
  const fields = fieldErrors(error)
  return { fields, banner: error && Object.keys(fields).length === 0 ? errorMessage(error) : null }
}

export function NewEmployeePage() {
  const navigate = useNavigate()
  const create = useCreateEmployee()
  const errors = formErrorsFor(create.error)

  return (
    <>
      <Button component={RouterLink} to="/employees" startIcon={<ArrowBack />} sx={{ mb: 1 }}>
        Employees
      </Button>
      <PageHeader title="Add employee" subtitle="Creates the employee with their starting salary." />
      <EmployeeForm
        mode="create"
        initialValues={EMPTY_EMPLOYEE_FORM}
        submitting={create.isPending}
        serverErrors={errors.fields}
        formError={errors.banner}
        onSubmit={(profile, salary) => {
          create.mutate(
            { profile, salary },
            { onSuccess: (employee) => void navigate(`/employees/${employee.id}`) },
          )
        }}
        onCancel={() => void navigate('/employees')}
      />
    </>
  )
}

export function EditEmployeePage() {
  const id = Number(useParams().id)
  const navigate = useNavigate()
  const employee = useEmployee(id)
  const update = useUpdateEmployee(id)
  const errors = formErrorsFor(update.error)

  return (
    <>
      <Button component={RouterLink} to={`/employees/${id}`} startIcon={<ArrowBack />} sx={{ mb: 1 }}>
        Back
      </Button>
      <PageHeader title="Edit employee" subtitle={employee.data?.full_name} />
      <QueryStateBoundary isPending={employee.isPending} error={employee.error}>
        {employee.data && (
          <EmployeeForm
            mode="edit"
            initialValues={formValuesFor(employee.data)}
            submitting={update.isPending}
            serverErrors={errors.fields}
            formError={errors.banner}
            onSubmit={({ country: _country, ...profile }) => {
              update.mutate(profile, { onSuccess: () => void navigate(`/employees/${id}`) })
            }}
            onCancel={() => void navigate(`/employees/${id}`)}
          />
        )}
      </QueryStateBoundary>
    </>
  )
}
