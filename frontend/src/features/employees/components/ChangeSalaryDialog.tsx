import {
  Alert,
  Button,
  Checkbox,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  InputAdornment,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useState, type SyntheticEvent } from 'react'
import { errorMessage, fieldErrors } from '@/lib/apiError'
import { formatMoney, formatPercent, toCents, todayIso, toMajorUnits } from '@/lib/format'
import type { Employee } from '@/types/api'
import { useChangeSalary } from '../hooks/useEmployeeMutations'

// Changes this large are usually typos (an extra zero) and need explicit confirmation.
const LARGE_CHANGE_PCT = 50

interface ChangeSalaryDialogProps {
  employee: Employee
  open: boolean
  onClose: () => void
}

/** Records a new effective-dated salary. History is append-only, so this never edits past records. */
export function ChangeSalaryDialog({ employee, open, onClose }: ChangeSalaryDialogProps) {
  const { currency, amount_cents: currentCents } = employee.current_salary
  const [amount, setAmount] = useState(String(toMajorUnits(currentCents)))
  const [effectiveDate, setEffectiveDate] = useState(todayIso())
  const [note, setNote] = useState('')
  const [confirmedLarge, setConfirmedLarge] = useState(false)
  const mutation = useChangeSalary(employee.id)

  const newCents = toCents(Number(amount))
  const changePct = currentCents > 0 && newCents > 0 ? ((newCents - currentCents) / currentCents) * 100 : null
  const errors = fieldErrors(mutation.error)
  const hasFieldErrors = Object.keys(errors).length > 0
  const isLargeChange = changePct !== null && Math.abs(changePct) >= LARGE_CHANGE_PCT

  const handleClose = () => {
    mutation.reset()
    onClose()
  }

  const handleSubmit = (event: SyntheticEvent) => {
    event.preventDefault()
    mutation.mutate(
      { amount_cents: newCents, effective_date: effectiveDate, note: note || undefined },
      { onSuccess: handleClose },
    )
  }

  return (
    <Dialog open={open} onClose={mutation.isPending ? undefined : handleClose} maxWidth="sm" fullWidth>
      <form onSubmit={handleSubmit} noValidate>
        <DialogTitle>Change salary — {employee.full_name}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ pt: 1 }}>
            {mutation.isError && !hasFieldErrors && (
              <Alert severity="error">{errorMessage(mutation.error)}</Alert>
            )}
            <Typography variant="body2" color="text.secondary">
              Current salary: {formatMoney(currentCents, currency)}
            </Typography>
            <TextField
              label="New annual base salary"
              type="number"
              required
              autoFocus
              value={amount}
              onChange={(e) => {
                setAmount(e.target.value)
                setConfirmedLarge(false)
              }}
              error={Boolean(errors.amount_cents)}
              helperText={
                errors.amount_cents ?? (changePct === null ? ' ' : `${formatPercent(changePct)} vs current`)
              }
              slotProps={{
                input: { startAdornment: <InputAdornment position="start">{currency}</InputAdornment> },
                htmlInput: { min: 0, step: 100 },
              }}
            />
            {isLargeChange && (
              <Alert severity="warning">
                This is a {formatPercent(changePct)} change, from {formatMoney(currentCents, currency)} to{' '}
                {formatMoney(newCents, currency)}.
                <FormControlLabel
                  sx={{ display: 'flex', mt: 0.5 }}
                  control={
                    <Checkbox
                      size="small"
                      checked={confirmedLarge}
                      onChange={(e) => {
                        setConfirmedLarge(e.target.checked)
                      }}
                    />
                  }
                  label="I've double-checked this amount"
                />
              </Alert>
            )}
            <TextField
              label="Effective date"
              type="date"
              required
              value={effectiveDate}
              onChange={(e) => {
                setEffectiveDate(e.target.value)
              }}
              error={Boolean(errors.effective_date)}
              helperText={
                errors.effective_date ?? 'Back-dated corrections are allowed; future dates are not.'
              }
              slotProps={{ inputLabel: { shrink: true }, htmlInput: { max: todayIso() } }}
            />
            <TextField
              label="Reason / note"
              placeholder="e.g. Annual review, promotion"
              value={note}
              onChange={(e) => {
                setNote(e.target.value)
              }}
              error={Boolean(errors.note)}
              helperText={errors.note}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} disabled={mutation.isPending}>
            Cancel
          </Button>
          <Button
            type="submit"
            variant="contained"
            disabled={
              mutation.isPending ||
              !(newCents > 0) ||
              newCents === currentCents ||
              (isLargeChange && !confirmedLarge)
            }
          >
            {mutation.isPending ? 'Saving…' : 'Record change'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  )
}
