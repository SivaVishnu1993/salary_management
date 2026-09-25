import {
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  ToggleButton,
  ToggleButtonGroup,
  Typography,
} from '@mui/material'
import { useState } from 'react'
import { QueryStateBoundary } from '@/components/QueryStateBoundary'
import { formatCount, formatUsd } from '@/lib/format'
import { PayBarChart } from './PayBarChart'

export interface BreakdownRow {
  key: string
  label: string
  headcount: number
  total_payroll_usd_cents: number
  median_salary_usd_cents: number | null
}

interface BreakdownCardProps {
  title: string
  subtitle: string
  rows: BreakdownRow[] | undefined
  isPending: boolean
  error: unknown
}

/** Payroll by one dimension, as a chart or (for exact values / accessibility) a table. */
export function BreakdownCard({ title, subtitle, rows, isPending, error }: BreakdownCardProps) {
  const [view, setView] = useState<'chart' | 'table'>('chart')

  return (
    <Paper sx={{ p: 2.5, height: '100%' }}>
      <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
        <div>
          <Typography variant="h6" component="h2">
            {title}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {subtitle}
          </Typography>
        </div>
        <ToggleButtonGroup
          size="small"
          exclusive
          value={view}
          onChange={(_event, next: 'chart' | 'table' | null) => {
            if (next) setView(next)
          }}
          aria-label={`${title} view`}
        >
          <ToggleButton value="chart">Chart</ToggleButton>
          <ToggleButton value="table">Table</ToggleButton>
        </ToggleButtonGroup>
      </Stack>
      <QueryStateBoundary
        isPending={isPending}
        error={error}
        isEmpty={rows?.length === 0}
        emptyMessage="No employees match these filters."
      >
        {rows && view === 'chart' && (
          <PayBarChart
            ariaLabel={title}
            data={rows.map((row) => ({ label: row.label, value: row.total_payroll_usd_cents }))}
          />
        )}
        {rows && view === 'table' && (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell />
                <TableCell align="right">Headcount</TableCell>
                <TableCell align="right">Total payroll</TableCell>
                <TableCell align="right">Median salary</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.key}>
                  <TableCell component="th" scope="row">
                    {row.label}
                  </TableCell>
                  <TableCell align="right">{formatCount(row.headcount)}</TableCell>
                  <TableCell align="right">{formatUsd(row.total_payroll_usd_cents)}</TableCell>
                  <TableCell align="right">{formatUsd(row.median_salary_usd_cents)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </QueryStateBoundary>
    </Paper>
  )
}
