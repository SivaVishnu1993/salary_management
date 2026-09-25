import ArrowBack from '@mui/icons-material/ArrowBack'
import DeleteOutline from '@mui/icons-material/DeleteOutlined'
import Edit from '@mui/icons-material/Edit'
import TrendingUp from '@mui/icons-material/TrendingUp'
import { Alert, Box, Button, Chip, Grid, Paper, Stack, Typography } from '@mui/material'
import { useState, type ReactNode } from 'react'
import { Link as RouterLink, useNavigate, useParams } from 'react-router-dom'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { PageHeader } from '@/components/PageHeader'
import { QueryStateBoundary } from '@/components/QueryStateBoundary'
import { errorMessage } from '@/lib/apiError'
import { formatDate, formatMoney, formatUsd } from '@/lib/format'
import type { Employee } from '@/types/api'
import { ChangeSalaryDialog } from '../components/ChangeSalaryDialog'
import { SalaryHistoryTable } from '../components/SalaryHistoryTable'
import { useEmployee, useSalaryHistory } from '../hooks/useEmployee'
import { useDeleteEmployee } from '../hooks/useEmployeeMutations'

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <Box>
      <Typography variant="caption" color="text.secondary" component="p">
        {label}
      </Typography>
      <Typography variant="body1" component="div">
        {children}
      </Typography>
    </Box>
  )
}

function ProfileCard({ employee }: { employee: Employee }) {
  const { amount_cents, currency } = employee.current_salary
  return (
    <Paper sx={{ p: 3 }}>
      <Grid container spacing={3}>
        <Grid size={{ xs: 12, md: 4 }}>
          <Field label="Current annual salary">
            <Typography variant="h5" component="span" sx={{ fontVariantNumeric: 'tabular-nums' }}>
              {formatMoney(amount_cents, currency)}
            </Typography>
            {currency !== 'USD' && (
              <Typography variant="body2" color="text.secondary">
                ≈ {formatUsd(employee.current_salary_usd_cents)} at static rates
              </Typography>
            )}
          </Field>
        </Grid>
        <Grid size={{ xs: 6, md: 2 }}>
          <Field label="Department">{employee.department}</Field>
        </Grid>
        <Grid size={{ xs: 6, md: 2 }}>
          <Field label="Country">{employee.country_name ?? employee.country}</Field>
        </Grid>
        <Grid size={{ xs: 6, md: 2 }}>
          <Field label="Hired">{formatDate(employee.hire_date)}</Field>
        </Grid>
        <Grid size={{ xs: 6, md: 2 }}>
          <Field label="Email">
            <Typography variant="body2" sx={{ wordBreak: 'break-all' }}>
              {employee.email}
            </Typography>
          </Field>
        </Grid>
      </Grid>
    </Paper>
  )
}

function SalaryHistorySection({ employeeId }: { employeeId: number }) {
  const [page, setPage] = useState(1)
  const [perPage, setPerPage] = useState(10)
  const history = useSalaryHistory(employeeId, page, perPage)

  return (
    <Box sx={{ mt: 3 }}>
      <Typography variant="h6" component="h2" sx={{ mb: 1.5 }}>
        Salary history
      </Typography>
      <QueryStateBoundary isPending={history.isPending} error={history.error}>
        <SalaryHistoryTable
          salaries={history.data?.data ?? []}
          rowCount={history.data?.meta.total ?? 0}
          loading={history.isFetching}
          page={page}
          perPage={perPage}
          onPageChange={(nextPage, nextPerPage) => {
            setPage(nextPage)
            setPerPage(nextPerPage)
          }}
        />
      </QueryStateBoundary>
    </Box>
  )
}

export function EmployeeDetailPage() {
  const id = Number(useParams().id)
  const navigate = useNavigate()
  const employee = useEmployee(id)
  const deletion = useDeleteEmployee()
  const [salaryDialogOpen, setSalaryDialogOpen] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)

  const handleDelete = () => {
    deletion.mutate(id, { onSuccess: () => void navigate('/employees', { replace: true }) })
  }

  return (
    <>
      <Button component={RouterLink} to="/employees" startIcon={<ArrowBack />} sx={{ mb: 1 }}>
        Employees
      </Button>
      <QueryStateBoundary isPending={employee.isPending} error={employee.error} minHeight={300}>
        {employee.data && (
          <>
            <PageHeader
              title={employee.data.full_name}
              subtitle={
                <Stack direction="row" spacing={1} component="span" sx={{ alignItems: 'center' }}>
                  <span>{employee.data.job_title}</span>
                  <Chip label={employee.data.employee_code} size="small" variant="outlined" />
                </Stack>
              }
              actions={
                <>
                  <Button
                    variant="contained"
                    startIcon={<TrendingUp />}
                    onClick={() => {
                      setSalaryDialogOpen(true)
                    }}
                  >
                    Change salary
                  </Button>
                  <Button component={RouterLink} to={`/employees/${id}/edit`} startIcon={<Edit />}>
                    Edit
                  </Button>
                  <Button
                    color="error"
                    startIcon={<DeleteOutline />}
                    onClick={() => {
                      setConfirmDelete(true)
                    }}
                  >
                    Delete
                  </Button>
                </>
              }
            />
            {deletion.isError && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {errorMessage(deletion.error)}
              </Alert>
            )}
            <ProfileCard employee={employee.data} />
            <SalaryHistorySection employeeId={id} />
            {salaryDialogOpen && (
              <ChangeSalaryDialog
                employee={employee.data}
                open
                onClose={() => {
                  setSalaryDialogOpen(false)
                }}
              />
            )}
            <ConfirmDialog
              open={confirmDelete}
              title="Delete employee?"
              message={`${employee.data.full_name} and their entire salary history will be permanently removed.`}
              confirmLabel="Delete"
              pending={deletion.isPending}
              onConfirm={handleDelete}
              onClose={() => {
                setConfirmDelete(false)
              }}
            />
          </>
        )}
      </QueryStateBoundary>
    </>
  )
}
