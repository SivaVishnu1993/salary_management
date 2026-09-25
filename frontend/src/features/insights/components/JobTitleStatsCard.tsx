import {
  MenuItem,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material'
import { QueryStateBoundary } from '@/components/QueryStateBoundary'
import { useFilterOptions } from '@/features/meta/useFilterOptions'
import { formatCount, formatMoney } from '@/lib/format'
import { useJobTitleStats } from '../hooks/useInsights'

interface JobTitleStatsCardProps {
  country: string
  department?: string
  onCountryChange: (country: string) => void
}

/** "What do we pay a Senior Engineer in India?" — pay spread per title, in local currency. */
export function JobTitleStatsCard({ country, department, onCountryChange }: JobTitleStatsCardProps) {
  const { data: options } = useFilterOptions()
  const stats = useJobTitleStats(country, department)
  const currency = stats.data?.currency ?? 'USD'

  return (
    <Paper sx={{ p: 2.5 }}>
      <Stack
        direction={{ xs: 'column', sm: 'row' }}
        spacing={2}
        sx={{ justifyContent: 'space-between', mb: 2 }}
      >
        <div>
          <Typography variant="h6" component="h2">
            Pay by job title
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Annual base salary in local currency, so every figure is comparable within the country.
          </Typography>
        </div>
        <TextField
          select
          label="Country"
          value={country}
          onChange={(e) => {
            onCountryChange(e.target.value)
          }}
          sx={{ minWidth: 200, maxWidth: { sm: 240 } }}
        >
          {(options?.countries ?? []).map((c) => (
            <MenuItem key={c.code} value={c.code}>
              {c.name} ({c.currency})
            </MenuItem>
          ))}
        </TextField>
      </Stack>
      <QueryStateBoundary
        isPending={stats.isPending}
        error={stats.error}
        isEmpty={stats.data?.job_titles.length === 0}
        emptyMessage="No employees in this country for the selected filters."
      >
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Job title</TableCell>
                <TableCell>Department</TableCell>
                <TableCell align="right">Headcount</TableCell>
                <TableCell align="right">Min</TableCell>
                <TableCell align="right">Median</TableCell>
                <TableCell align="right">Average</TableCell>
                <TableCell align="right">Max</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {stats.data?.job_titles.map((row) => (
                <TableRow key={row.job_title} hover>
                  <TableCell component="th" scope="row">
                    {row.job_title}
                  </TableCell>
                  <TableCell>{row.department}</TableCell>
                  <TableCell align="right">{formatCount(row.headcount)}</TableCell>
                  <TableCell align="right">{formatMoney(row.min_cents, currency)}</TableCell>
                  <TableCell align="right" sx={{ fontWeight: 600 }}>
                    {formatMoney(row.median_cents, currency)}
                  </TableCell>
                  <TableCell align="right">{formatMoney(row.average_cents, currency)}</TableCell>
                  <TableCell align="right">{formatMoney(row.max_cents, currency)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </QueryStateBoundary>
    </Paper>
  )
}
