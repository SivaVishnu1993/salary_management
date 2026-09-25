import { Alert, Box, Button, CircularProgress, Typography } from '@mui/material'
import type { ReactNode } from 'react'
import { errorMessage } from '@/lib/apiError'

interface QueryStateBoundaryProps {
  isPending: boolean
  error: unknown
  isEmpty?: boolean
  emptyMessage?: string
  onRetry?: () => void
  minHeight?: number
  children: ReactNode
}

/** One consistent loading / error / empty treatment for every data view. */
export function QueryStateBoundary({
  isPending,
  error,
  isEmpty = false,
  emptyMessage = 'Nothing to show.',
  onRetry,
  minHeight = 160,
  children,
}: QueryStateBoundaryProps) {
  if (isPending) {
    return (
      <Box sx={{ minHeight, display: 'grid', placeItems: 'center' }} role="status" aria-label="Loading">
        <CircularProgress size={28} />
      </Box>
    )
  }
  if (error) {
    return (
      <Alert
        severity="error"
        action={
          onRetry && (
            <Button color="inherit" size="small" onClick={onRetry}>
              Retry
            </Button>
          )
        }
      >
        {errorMessage(error)}
      </Alert>
    )
  }
  if (isEmpty) {
    return (
      <Box sx={{ minHeight, display: 'grid', placeItems: 'center' }}>
        <Typography color="text.secondary">{emptyMessage}</Typography>
      </Box>
    )
  }
  return <>{children}</>
}
