import type { GridColDef, GridPaginationModel } from '@mui/x-data-grid'
import { ServerDataGrid } from '@/components/ServerDataGrid'
import { formatDate, formatMoney, formatPercent } from '@/lib/format'
import type { Salary } from '@/types/api'

type SalaryRow = Salary & { change_pct: number | null }

const COLUMNS: GridColDef<SalaryRow>[] = [
  {
    field: 'effective_date',
    headerName: 'Effective',
    width: 140,
    valueFormatter: (value: string) => formatDate(value),
  },
  {
    field: 'amount_cents',
    headerName: 'Annual salary',
    width: 170,
    align: 'right',
    headerAlign: 'right',
    valueFormatter: (value: number, row) => formatMoney(value, row.currency),
  },
  {
    field: 'change_pct',
    headerName: 'Change',
    width: 110,
    align: 'right',
    headerAlign: 'right',
    valueFormatter: (value: number | null) => (value === null ? '—' : formatPercent(value)),
  },
  {
    field: 'note',
    headerName: 'Note',
    flex: 1,
    minWidth: 160,
    valueFormatter: (value: string | null) => value ?? '',
  },
  {
    field: 'recorded_at',
    headerName: 'Recorded',
    width: 140,
    valueFormatter: (value: string) => formatDate(value),
  },
]

/** Adds % change versus the next-older record on the same page. */
function withChanges(salaries: Salary[]): SalaryRow[] {
  return salaries.map((salary, index) => {
    const previous = salaries[index + 1]
    const change_pct = previous
      ? ((salary.amount_cents - previous.amount_cents) / previous.amount_cents) * 100
      : null
    return { ...salary, change_pct }
  })
}

interface SalaryHistoryTableProps {
  salaries: Salary[]
  rowCount: number
  loading: boolean
  page: number
  perPage: number
  onPageChange: (page: number, perPage: number) => void
}

export function SalaryHistoryTable({
  salaries,
  rowCount,
  loading,
  page,
  perPage,
  onPageChange,
}: SalaryHistoryTableProps) {
  return (
    <ServerDataGrid<SalaryRow>
      rows={withChanges(salaries)}
      columns={COLUMNS}
      rowCount={rowCount}
      loading={loading}
      paginationModel={{ page: page - 1, pageSize: perPage }}
      onPaginationModelChange={(model: GridPaginationModel) => {
        onPageChange(model.page + 1, model.pageSize)
      }}
      pageSizeOptions={[10, 25]}
      density="compact"
      localeText={{ noRowsLabel: 'No salary records' }}
    />
  )
}
