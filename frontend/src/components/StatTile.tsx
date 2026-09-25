import { Paper, Skeleton, Typography } from '@mui/material'

interface StatTileProps {
  label: string
  value: string
  caption?: string
  loading?: boolean
}

/** A single headline number. Used where a chart would add nothing. */
export function StatTile({ label, value, caption, loading = false }: StatTileProps) {
  return (
    <Paper sx={{ p: 2.5, height: '100%' }}>
      <Typography variant="overline" color="text.secondary" component="p">
        {label}
      </Typography>
      <Typography variant="h4" component="p" sx={{ fontVariantNumeric: 'tabular-nums' }}>
        {loading ? <Skeleton width="60%" /> : value}
      </Typography>
      {caption && (
        <Typography variant="caption" color="text.secondary">
          {caption}
        </Typography>
      )}
    </Paper>
  )
}
