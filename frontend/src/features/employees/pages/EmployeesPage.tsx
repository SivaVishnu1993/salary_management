import Add from '@mui/icons-material/Add'
import { Button } from '@mui/material'
import { useEffect, useState } from 'react'
import { Link as RouterLink } from 'react-router-dom'
import { FilterBar, type FilterValues } from '@/components/FilterBar'
import { PageHeader } from '@/components/PageHeader'
import { QueryStateBoundary } from '@/components/QueryStateBoundary'
import { useDebouncedValue } from '@/hooks/useDebouncedValue'
import { useUrlState } from '@/hooks/useUrlState'
import { formatCount } from '@/lib/format'
import { PAGE_SIZE_OPTIONS } from '@/lib/pagination'
import type { EmployeeSortKey } from '../api'
import { EmployeesTable } from '../components/EmployeesTable'
import { useEmployees } from '../hooks/useEmployees'

const DEFAULTS = {
  q: '',
  country: '',
  department: '',
  job_title: '',
  sort: 'name',
  direction: 'asc',
  page: '1',
  per_page: '25',
}

const toPositiveInt = (value: string, fallback: number) => {
  const number = Number.parseInt(value, 10)
  return Number.isFinite(number) && number > 0 ? number : fallback
}

export function EmployeesPage() {
  const [state, update] = useUrlState(DEFAULTS)
  const [searchInput, setSearchInput] = useState(state.q)
  const debouncedSearch = useDebouncedValue(searchInput, 300)

  // Push the debounced search into the URL (and back to page 1) once typing pauses.
  useEffect(() => {
    if (debouncedSearch !== state.q) update({ q: debouncedSearch, page: '1' })
  }, [debouncedSearch, state.q, update])

  const perPage = toPositiveInt(state.per_page, 25)
  const params = {
    q: state.q,
    country: state.country,
    department: state.department,
    job_title: state.job_title,
    sort: state.sort as EmployeeSortKey,
    direction: state.direction === 'desc' ? ('desc' as const) : ('asc' as const),
    page: toPositiveInt(state.page, 1),
    per_page: PAGE_SIZE_OPTIONS.includes(perPage) ? perPage : 25,
  }
  const query = useEmployees(params)

  const handleFilters = ({ q, ...filters }: FilterValues) => {
    if (q !== undefined) setSearchInput(q)
    if (Object.keys(filters).length > 0) update({ ...filters, page: '1' })
  }

  return (
    <>
      <PageHeader
        title="Employees"
        subtitle={query.data ? `${formatCount(query.data.meta.total)} employees` : 'Directory'}
        actions={
          <Button component={RouterLink} to="/employees/new" variant="contained" startIcon={<Add />}>
            Add employee
          </Button>
        }
      />
      <FilterBar
        values={{ ...state, q: searchInput }}
        onChange={handleFilters}
        fields={['q', 'country', 'department', 'job_title']}
        searchPlaceholder="Search name, email or employee code"
      />
      <QueryStateBoundary
        isPending={query.isPending}
        error={query.error}
        onRetry={() => void query.refetch()}
      >
        <EmployeesTable
          rows={query.data?.data ?? []}
          rowCount={query.data?.meta.total ?? 0}
          loading={query.isFetching}
          page={params.page}
          perPage={params.per_page}
          sort={params.sort}
          direction={params.direction}
          onPageChange={(page, per_page) => {
            update({ page: String(page), per_page: String(per_page) })
          }}
          onSortChange={(sort, direction) => {
            update({ sort, direction, page: '1' })
          }}
        />
      </QueryStateBoundary>
    </>
  )
}
