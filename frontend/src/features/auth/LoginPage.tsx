import LockOutlined from '@mui/icons-material/LockOutlined'
import { Alert, Avatar, Box, Button, Paper, Stack, TextField, Typography } from '@mui/material'
import { useState, type SyntheticEvent } from 'react'
import { Navigate, useLocation, useNavigate, type Location } from 'react-router-dom'
import { errorMessage } from '@/lib/apiError'
import { useAuth } from './useAuth'

export function LoginPage() {
  const { status, login } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const from = (location.state as { from?: Location } | null)?.from?.pathname ?? '/employees'

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  if (status === 'authenticated') return <Navigate to={from} replace />

  const handleSubmit = async (event: SyntheticEvent) => {
    event.preventDefault()
    setSubmitting(true)
    setError(null)
    try {
      await login(email, password)
      void navigate(from, { replace: true })
    } catch (err) {
      setError(errorMessage(err, 'Sign-in failed.'))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Box
      sx={{ minHeight: '100vh', display: 'grid', placeItems: 'center', px: 2, bgcolor: 'background.default' }}
    >
      <Paper component="form" onSubmit={handleSubmit} sx={{ p: 4, width: '100%', maxWidth: 400 }} noValidate>
        <Stack spacing={2.5} sx={{ alignItems: 'center' }}>
          <Avatar sx={{ bgcolor: 'primary.main' }}>
            <LockOutlined />
          </Avatar>
          <Box sx={{ textAlign: 'center' }}>
            <Typography variant="h5" component="h1" sx={{ fontWeight: 600 }}>
              ACME Salary Management
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Sign in with your HR account
            </Typography>
          </Box>
          {error && (
            <Alert severity="error" sx={{ width: '100%' }}>
              {error}
            </Alert>
          )}
          <TextField
            label="Email"
            type="email"
            autoComplete="email"
            autoFocus
            required
            value={email}
            onChange={(e) => {
              setEmail(e.target.value)
            }}
          />
          <TextField
            label="Password"
            type="password"
            autoComplete="current-password"
            required
            value={password}
            onChange={(e) => {
              setPassword(e.target.value)
            }}
          />
          <Button
            type="submit"
            variant="contained"
            fullWidth
            size="large"
            disabled={submitting || !email || !password}
          >
            {submitting ? 'Signing in…' : 'Sign in'}
          </Button>
          {import.meta.env.DEV && (
            <Typography variant="caption" color="text.secondary">
              Demo account: hr@acme.test / password123
            </Typography>
          )}
        </Stack>
      </Paper>
    </Box>
  )
}
