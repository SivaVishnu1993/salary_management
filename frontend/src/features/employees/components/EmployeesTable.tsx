import type { GridColDef, GridPaginationModel, GridRowParams, GridSortModel } from '@mui/x-data-grid'
import { useNavigate } from 'react-router-dom'
import { MoneyText } from '@/components/MoneyText'
import { ServerDataGrid } from '@/components/ServerDataGrid'
import { formatDate, formatUsd } from '@/lib/format'
import type { Employee } from '@/types/api'
import type { EmployeeSortKey } from '../api'

// Grid column field -> API sort key (the API whitelists these).
const SORT_KEYS: Partial<Record<string, EmployeeSortKey>> = {
  full_name: 'name',
  employee_code: 'employee_code',
  country: 'country',
  department: 'department',
  job_title: 'job_title',
  hire_date: 'hire_date',
  current_salary_usd_cents: 'salary_usd',
}
const FIELD_FOR_SORT: Partial<Record<EmployeeSortKey, string>> = {}
for (const [field, key] of Object.entries(SORT_KEYS)) if (key) FIELD_FOR_SORT[key] = field

const COLUMNS: GridColDef<Employee>[] = [
  { field: 'employee_code', headerName: 'Code', width: 120 },
  { field: 'full_name', headerName: 'Name', flex: 1, minWidth: 170 },
  { field: 'job_title', headerName: 'Job title', flex: 1, minWidth: 190 },
  { field: 'department', headerName: 'Department', width: 130 },
  {
    field: 'country',
    headerName: 'Country',
    width: 140,
    valueGetter: (_value, row) => row.country_name ?? row.country,
  },
  {
    field: 'hire_date',
    headerName: 'Hired',
    width: 120,
    valueFormatter: (value: string) => formatDate(value),
  },
  {
    field: 'current_salary',
    headerName: 'Salary (local)',
    width: 150,
    sortable: false,
    align: 'right',
    headerAlign: 'right',
    renderCell: ({ row }) => (
      <MoneyText cents={row.current_salary.amount_cents} currency={row.current_salary.currency} />
    ),
  },
  {
    field: 'current_salary_usd_cents',
    headerName: 'Salary (USD)',
    width: 140,
    align: 'right',
    headerAlign: 'right',
    valueFormatter: (value: number | null) => formatUsd(value),
  },
]

interface EmployeesTableProps {
  rows: Employee[]
  rowCount: number
  loading: boolean
  page: number
  perPage: number
  sort: EmployeeSortKey
  direction: 'asc' | 'desc'
  onPageChange: (page: number, perPage: number) => void
  onSortChange: (sort: EmployeeSortKey, direction: 'asc' | 'desc') => void
}

export function EmployeesTable({
  rows,
  rowCount,
  loading,
  page,
  perPage,
  sort,
  direction,
  onPageChange,
  onSortChange,
}: EmployeesTableProps) {
  const navigate = useNavigate()
  const sortField = FIELD_FOR_SORT[sort]
  const sortModel: GridSortModel = sortField ? [{ field: sortField, sort: direction }] : []

  const handlePagination = (model: GridPaginationModel) => {
    onPageChange(model.page + 1, model.pageSize)
  }

  const handleSort = (model: GridSortModel) => {
    const [first] = model
    const key = first ? SORT_KEYS[first.field] : undefined
    if (first && key) onSortChange(key, first.sort ?? 'asc')
    else onSortChange('name', 'asc')
  }

  return (
    <ServerDataGrid<Employee>
      rows={rows}
      columns={COLUMNS}
      rowCount={rowCount}
      loading={loading}
      paginationModel={{ page: page - 1, pageSize: perPage }}
      onPaginationModelChange={handlePagination}
      sortModel={sortModel}
      onSortModelChange={handleSort}
      onRowClick={({ row }: GridRowParams<Employee>) => void navigate(`/employees/${row.id}`)}
      getRowHeight={() => 56}
      localeText={{ noRowsLabel: 'No employees match these filters' }}
    />
  )
}
