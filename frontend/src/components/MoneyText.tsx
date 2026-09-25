import { Box, Typography } from '@mui/material'
import { formatMoney, formatUsd } from '@/lib/format'

interface MoneyTextProps {
  cents: number | null | undefined
  currency: string
  /** Optional USD equivalent, shown as a secondary line for non-USD amounts. */
  usdCents?: number | null
}

export function MoneyText({ cents, currency, usdCents }: MoneyTextProps) {
  const showUsd = currency !== 'USD' && usdCents !== undefined && usdCents !== null
  return (
    <Box component="span" sx={{ display: 'inline-flex', flexDirection: 'column', lineHeight: 1.3 }}>
      <Typography component="span" variant="body2" sx={{ fontVariantNumeric: 'tabular-nums' }}>
        {formatMoney(cents, currency)}
      </Typography>
      {showUsd && (
        <Typography
          component="span"
          variant="caption"
          color="text.secondary"
          sx={{ fontVariantNumeric: 'tabular-nums' }}
        >
          ≈ {formatUsd(usdCents)}
        </Typography>
      )}
    </Box>
  )
}
