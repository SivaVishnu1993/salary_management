import {
  Alert,
  Box,
  Button,
  Divider,
  Grid,
  InputAdornment,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useState, type SyntheticEvent } from 'react'
import { useFilterOptions } from '@/features/meta/useFilterOptions'
import { toCents, todayIso } from '@/lib/format'
import type { EmployeeProfileInput, SalaryInput } from '../api'
import type { EmployeeFormValues } from './employeeFormValues'

// API error keys -> form field names.
const ERROR_FIELD: Record<string, keyof EmployeeFormValues> = {
  'salary.amount_cents': 'salary_amount',
  'salary.effective_date': 'salary_effective_date',
  'salary.note': 'salary_note',
}

interface EmployeeFormProps {
  mode: 'create' | 'edit'
  initialValues: EmployeeFormValues
  submitting: boolean
  serverErrors: Record<string, string>
  formError?: string | null
  onSubmit: (profile: EmployeeProfileInput, salary: SalaryInput) => void
  onCancel: () => void
}

/** Create/edit form. Starting salary is captured only on create; later changes go through "Change salary". */
export function EmployeeForm({
  mode,
  initialValues,
  submitting,
  serverErrors,
  formError,
  onSubmit,
  onCancel,
}: EmployeeFormProps) {
  const { data: options } = useFilterOptions()
  const [values, setValues] = useState(initialValues)

  const errors = Object.fromEntries(
    Object.entries(serverErrors).map(([field, message]) => [ERROR_FIELD[field] ?? field, message]),
  ) as Partial<Record<keyof EmployeeFormValues, string>>

  const currency = options?.countries.find((c) => c.code === values.country)?.currency
  const jobTitles = options?.departments.find((d) => d.name === values.department)?.job_titles ?? []

  const set = (field: keyof EmployeeFormValues) => (event: { target: { value: string } }) => {
    const value = event.target.value
    setValues((current) => ({
      ...current,
      [field]: value,
      ...(field === 'department' ? { job_title: '' } : {}),
    }))
  }

  const fieldProps = (field: keyof EmployeeFormValues) => ({
    value: values[field],
    onChange: set(field),
    error: Boolean(errors[field]),
    helperText: errors[field],
  })

  const handleSubmit = (event: SyntheticEvent) => {
    event.preventDefault()
    const { salary_amount, salary_effective_date, salary_note, ...profile } = values
    onSubmit(profile, {
      amount_cents: toCents(Number(salary_amount)),
      effective_date: salary_effective_date || profile.hire_date,
      note: salary_note || undefined,
    })
  }

  return (
    <Paper component="form" onSubmit={handleSubmit} sx={{ p: 3, maxWidth: 880 }} noValidate>
      {formError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {formError}
        </Alert>
      )}
      <Typography variant="h6" sx={{ mb: 2 }}>
        Profile
      </Typography>
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField label="First name" required {...fieldProps('first_name')} />
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField label="Last name" required {...fieldProps('last_name')} />
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField label="Work email" type="email" required {...fieldProps('email')} />
        </Grid>
        <Grid size={{ xs: 12, sm: 6 }}>
          <TextField
            label="Hire date"
            type="date"
            required
            slotProps={{ inputLabel: { shrink: true } }}
            {...fieldProps('hire_date')}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField
            select
            label="Country"
            required
            disabled={mode === 'edit'}
            {...fieldProps('country')}
            helperText={
              errors.country ??
              (mode === 'edit' ? 'Country sets the pay currency and cannot be changed here.' : undefined)
            }
          >
            {(options?.countries ?? []).map((country) => (
              <MenuItem key={country.code} value={country.code}>
                {country.name} ({country.currency})
              </MenuItem>
            ))}
          </TextField>
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField select label="Department" required {...fieldProps('department')}>
            {(options?.departments ?? []).map((department) => (
              <MenuItem key={department.name} value={department.name}>
                {department.name}
              </MenuItem>
            ))}
          </TextField>
        </Grid>
        <Grid size={{ xs: 12, sm: 4 }}>
          <TextField
            select
            label="Job title"
            required
            disabled={!values.department}
            {...fieldProps('job_title')}
          >
            {jobTitles.map((title) => (
              <MenuItem key={title.name} value={title.name}>
                {title.name}
              </MenuItem>
            ))}
          </TextField>
        </Grid>
      </Grid>

      {mode === 'create' && (
        <>
          <Divider sx={{ my: 3 }} />
          <Typography variant="h6" sx={{ mb: 2 }}>
            Starting salary
          </Typography>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, sm: 4 }}>
              <TextField
                label="Annual base salary"
                type="number"
                required
                disabled={!currency}
                {...fieldProps('salary_amount')}
                helperText={errors.salary_amount ?? (currency ? undefined : 'Choose a country first')}
                slotProps={{
                  input: {
                    startAdornment: currency && <InputAdornment position="start">{currency}</InputAdornment>,
                  },
                  htmlInput: { min: 0, step: 100 },
                }}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 4 }}>
              <TextField
                label="Effective date"
                type="date"
                slotProps={{ inputLabel: { shrink: true }, htmlInput: { max: todayIso() } }}
                {...fieldProps('salary_effective_date')}
                helperText={errors.salary_effective_date ?? 'Defaults to the hire date'}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 4 }}>
              <TextField label="Note" {...fieldProps('salary_note')} />
            </Grid>
          </Grid>
        </>
      )}

      <Box sx={{ mt: 3 }}>
        <Stack direction="row" spacing={1} sx={{ justifyContent: 'flex-end' }}>
          <Button onClick={onCancel} disabled={submitting}>
            Cancel
          </Button>
          <Button type="submit" variant="contained" disabled={submitting}>
            {submitting ? 'Saving…' : mode === 'create' ? 'Add employee' : 'Save changes'}
          </Button>
        </Stack>
      </Box>
    </Paper>
  )
}
