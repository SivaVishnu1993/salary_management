import { Grid } from '@mui/material'
import { FilterBar } from '@/components/FilterBar'
import { PageHeader } from '@/components/PageHeader'
import { QueryStateBoundary } from '@/components/QueryStateBoundary'
import { StatTile } from '@/components/StatTile'
import { useFilterOptions } from '@/features/meta/useFilterOptions'
import { useUrlState } from '@/hooks/useUrlState'
import { formatCount, formatDate, formatUsd } from '@/lib/format'
import { BreakdownCard } from '../components/BreakdownCard'
import { JobTitleStatsCard } from '../components/JobTitleStatsCard'
import { useByCountry, useByDepartment, useSummary } from '../hooks/useInsights'

const DEFAULTS = { country: '', department: '', titles_country: 'US' }

export function InsightsPage() {
  const [state, update] = useUrlState(DEFAULTS)
  const filters = { country: state.country || undefined, department: state.department || undefined }
  const { data: options } = useFilterOptions()

  const summary = useSummary(filters)
  const byCountry = useByCountry(filters)
  const byDepartment = useByDepartment(filters)

  const fxNote = options?.fx.as_of
    ? `USD at static FX rates as of ${formatDate(options.fx.as_of)}`
    : 'USD at static FX rates'

  return (
    <>
      <PageHeader title="Pay insights" subtitle={`Annual base salary across the organisation. ${fxNote}.`} />
      <FilterBar
        values={state}
        onChange={(changes) => {
          update({ ...changes, ...(changes.country ? { titles_country: changes.country } : {}) })
        }}
        fields={['country', 'department']}
      />

      <QueryStateBoundary isPending={false} error={summary.error}>
        <Grid container spacing={2} sx={{ mb: 2 }}>
          <Grid size={{ xs: 6, md: 3 }}>
            <StatTile
              label="Headcount"
              value={formatCount(summary.data?.headcount ?? 0)}
              loading={summary.isPending}
            />
          </Grid>
          <Grid size={{ xs: 6, md: 3 }}>
            <StatTile
              label="Annual payroll"
              value={formatUsd(summary.data?.total_payroll_usd_cents, true)}
              caption="USD"
              loading={summary.isPending}
            />
          </Grid>
          <Grid size={{ xs: 6, md: 3 }}>
            <StatTile
              label="Median salary"
              value={formatUsd(summary.data?.median_salary_usd_cents)}
              caption="USD"
              loading={summary.isPending}
            />
          </Grid>
          <Grid size={{ xs: 6, md: 3 }}>
            <StatTile
              label="Average salary"
              value={formatUsd(summary.data?.average_salary_usd_cents)}
              caption="USD"
              loading={summary.isPending}
            />
          </Grid>
        </Grid>
      </QueryStateBoundary>

      <Grid container spacing={2} sx={{ mb: 2 }}>
        <Grid size={{ xs: 12, lg: 6 }}>
          <BreakdownCard
            title="Payroll by country"
            subtitle="Total annual base salary, USD"
            isPending={byCountry.isPending}
            error={byCountry.error}
            rows={byCountry.data?.map((row) => ({
              key: row.country,
              label: row.country_name ?? row.country,
              ...row,
            }))}
          />
        </Grid>
        <Grid size={{ xs: 12, lg: 6 }}>
          <BreakdownCard
            title="Payroll by department"
            subtitle="Total annual base salary, USD"
            isPending={byDepartment.isPending}
            error={byDepartment.error}
            rows={byDepartment.data?.map((row) => ({ key: row.department, label: row.department, ...row }))}
          />
        </Grid>
      </Grid>

      <JobTitleStatsCard
        country={state.titles_country}
        department={filters.department}
        onCountryChange={(titles_country) => {
          update({ titles_country })
        }}
      />
    </>
  )
}
