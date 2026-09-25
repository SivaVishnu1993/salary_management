import { Box, CircularProgress } from '@mui/material'

export function FullPageSpinner() {
  return (
    <Box sx={{ minHeight: '60vh', display: 'grid', placeItems: 'center' }} role="status" aria-label="Loading">
      <CircularProgress />
    </Box>
  )
}
