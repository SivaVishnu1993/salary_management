import { Box, Paper, Slider, Stack, Typography } from '@mui/material'
import type { GridColDef, GridRowParams } from '@mui/x-data-grid'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { FilterBar } from '@/components/FilterBar'
import { PageHeader } from '@/components/PageHeader'
import { QueryStateBoundary } from '@/components/QueryStateBoundary'
import { ServerDataGrid } from '@/components/ServerDataGrid'
import { useUrlState } from '@/hooks/useUrlState'
import { formatCount, formatMoney } from '@/lib/format'
import type { Outlier } from '@/types/api'
import { DeviationChip } from '../components/DeviationChip'
import { useOutliers } from '../hooks/useOutliers'

const DEFAULTS = { threshold: '20', country: '', department: '', page: '1', per_page: '25' }
const THRESHOLD_MARKS = [10, 20, 30, 50].map((value) => ({ value, label: `${value}%` }))

const COLUMNS: GridColDef<Outlier>[] = [
  { field: 'full_name', headerName: 'Employee', flex: 1, minWidth: 170 },
  { field: 'job_title', headerName: 'Job title', flex: 1, minWidth: 190 },
  { field: 'country', headerName: 'Country', width: 90 },
  {
    field: 'salary_cents',
    headerName: 'Salary',
    width: 150,
    align: 'right',
    headerAlign: 'right',
    valueFormatter: (value: number, row) => formatMoney(value, row.currency),
  },
  {
    field: 'peer_median_cents',
    headerName: 'Peer median',
    width: 150,
    align: 'right',
    headerAlign: 'right',
    valueFormatter: (value: number, row) => formatMoney(value, row.currency),
  },
  { field: 'peer_count', headerName: 'Peers', width: 80, align: 'right', headerAlign: 'right' },
  {
    field: 'deviation_pct',
    headerName: 'Deviation',
    width: 160,
    renderCell: ({ row }) => <DeviationChip value={row.deviation_pct} />,
  },
]

const toInt = (value: string, fallback: number) => {
  const number = Number.parseInt(value, 10)
  return Number.isFinite(number) && number > 0 ? number : fallback
}

export function OutliersPage() {
  const navigate = useNavigate()
  const [state, update] = useUrlState(DEFAULTS)
  const threshold = toInt(state.threshold, 20)
  const [sliderValue, setSliderValue] = useState(threshold)

  const params = {
    threshold_pct: threshold,
    country: state.country || undefined,
    department: state.department || undefined,
    page: toInt(state.page, 1),
    per_page: toInt(state.per_page, 25),
  }
  const query = useOutliers(params)
  const result = query.data

  return (
    <>
      <PageHeader
        title="Pay outliers"
        subtitle="Employees paid far from the median of their peers — the same job title in the same country."
      />
      <Paper sx={{ p: 2.5, mb: 2 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={3} sx={{ alignItems: { md: 'center' } }}>
          <Box sx={{ minWidth: 260, px: 1 }}>
            <Typography variant="body2" id="threshold-label" gutterBottom>
              Flag when pay differs from the peer median by more than <strong>±{sliderValue}%</strong>
            </Typography>
            <Slider
              aria-labelledby="threshold-label"
              value={sliderValue}
              min={5}
              max={60}
              step={5}
              marks={THRESHOLD_MARKS}
              onChange={(_event, value) => {
                setSliderValue(value)
              }}
              onChangeCommitted={(_event, value) => {
                update({ threshold: String(value), page: '1' })
              }}
            />
          </Box>
          <Box sx={{ flex: 1 }}>
            <FilterBar
              values={state}
              onChange={(changes) => {
                update({ ...changes, page: '1' })
              }}
              fields={['country', 'department']}
            />
          </Box>
        </Stack>
        {result && (
          <Typography variant="body2" color="text.secondary">
            {formatCount(result.meta.total)} employees flagged. Peer groups with fewer than{' '}
            {result.data.min_peers} people are skipped because their median isn&apos;t a reliable benchmark.
          </Typography>
        )}
      </Paper>

      <QueryStateBoundary
        isPending={query.isPending}
        error={query.error}
        onRetry={() => void query.refetch()}
      >
        <ServerDataGrid<Outlier>
          rows={result?.data.rows ?? []}
          columns={COLUMNS}
          getRowId={(row) => row.employee_id}
          rowCount={result?.meta.total ?? 0}
          loading={query.isFetching}
          paginationModel={{ page: params.page - 1, pageSize: params.per_page }}
          onPaginationModelChange={(model) => {
            update({ page: String(model.page + 1), per_page: String(model.pageSize) })
          }}
          disableColumnSorting
          onRowClick={({ row }: GridRowParams<Outlier>) => void navigate(`/employees/${row.employee_id}`)}
          localeText={{ noRowsLabel: 'No outliers at this threshold' }}
        />
      </QueryStateBoundary>
    </>
  )
}
