import ArrowDownward from '@mui/icons-material/ArrowDownward'
import ArrowUpward from '@mui/icons-material/ArrowUpward'
import { Chip } from '@mui/material'
import { formatPercent } from '@/lib/format'

/** Above-median pay reads as "error", below as "warning"; the arrow and text carry it without colour. */
export function DeviationChip({ value }: { value: number }) {
  const above = value > 0
  return (
    <Chip
      size="small"
      variant="outlined"
      color={above ? 'error' : 'warning'}
      icon={above ? <ArrowUpward /> : <ArrowDownward />}
      label={`${formatPercent(value)} ${above ? 'above' : 'below'}`}
      sx={{ fontVariantNumeric: 'tabular-nums' }}
    />
  )
}
