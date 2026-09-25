import Search from '@mui/icons-material/Search'
import { Button, InputAdornment, MenuItem, Stack, TextField } from '@mui/material'
import { useFilterOptions } from '@/features/meta/useFilterOptions'

export interface FilterValues {
  q?: string
  country?: string
  department?: string
  job_title?: string
}

type FilterField = keyof FilterValues

interface FilterBarProps {
  values: FilterValues
  onChange: (changes: FilterValues) => void
  fields: FilterField[]
  searchPlaceholder?: string
}

/** One row of filters shared by the directory, insights and outliers views. */
export function FilterBar({ values, onChange, fields, searchPlaceholder = 'Search' }: FilterBarProps) {
  const { data: options } = useFilterOptions()
  const show = (field: FilterField) => fields.includes(field)
  const jobTitles = (options?.departments ?? [])
    .filter((department) => !values.department || department.name === values.department)
    .flatMap((department) => department.job_titles.map((title) => title.name))
  const hasFilters = fields.some((field) => Boolean(values[field]))

  return (
    <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.5} sx={{ mb: 2 }}>
      {show('q') && (
        <TextField
          placeholder={searchPlaceholder}
          value={values.q ?? ''}
          onChange={(e) => {
            onChange({ q: e.target.value })
          }}
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <Search fontSize="small" />
                </InputAdornment>
              ),
            },
            htmlInput: { 'aria-label': 'Search employees' },
          }}
          sx={{ flex: 2 }}
        />
      )}
      {show('country') && (
        <TextField
          select
          label="Country"
          value={values.country ?? ''}
          onChange={(e) => {
            onChange({ country: e.target.value })
          }}
          sx={{ flex: 1, minWidth: 160 }}
        >
          <MenuItem value="">All countries</MenuItem>
          {(options?.countries ?? []).map((country) => (
            <MenuItem key={country.code} value={country.code}>
              {country.name}
            </MenuItem>
          ))}
        </TextField>
      )}
      {show('department') && (
        <TextField
          select
          label="Department"
          value={values.department ?? ''}
          onChange={(e) => {
            // A job title belongs to one department, so changing department clears it.
            onChange({ department: e.target.value, ...(show('job_title') ? { job_title: '' } : {}) })
          }}
          sx={{ flex: 1, minWidth: 160 }}
        >
          <MenuItem value="">All departments</MenuItem>
          {(options?.departments ?? []).map((department) => (
            <MenuItem key={department.name} value={department.name}>
              {department.name}
            </MenuItem>
          ))}
        </TextField>
      )}
      {show('job_title') && (
        <TextField
          select
          label="Job title"
          value={values.job_title ?? ''}
          onChange={(e) => {
            onChange({ job_title: e.target.value })
          }}
          sx={{ flex: 1.5, minWidth: 200 }}
        >
          <MenuItem value="">All job titles</MenuItem>
          {jobTitles.map((title) => (
            <MenuItem key={title} value={title}>
              {title}
            </MenuItem>
          ))}
        </TextField>
      )}
      {hasFilters && (
        <Button
          onClick={() => {
            onChange(Object.fromEntries(fields.map((field) => [field, ''])))
          }}
          sx={{ flexShrink: 0 }}
        >
          Clear
        </Button>
      )}
    </Stack>
  )
}
