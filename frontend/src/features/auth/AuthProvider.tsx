import { useQueryClient } from '@tanstack/react-query'
import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { setUnauthorizedHandler } from '@/lib/http'
import { tokenStorage } from '@/lib/tokenStorage'
import type { User } from '@/types/api'
import { fetchCurrentUser, login as loginRequest } from './api'
import { AuthContext, type AuthContextValue, type AuthStatus } from './AuthContext'

/** Owns the session: restores it on load, logs in/out, and reacts to 401s. */
export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient()
  const [user, setUser] = useState<User | null>(null)
  const [status, setStatus] = useState<AuthStatus>(() => (tokenStorage.get() ? 'loading' : 'anonymous'))

  const endSession = useCallback(() => {
    tokenStorage.clear()
    setUser(null)
    setStatus('anonymous')
    queryClient.clear()
  }, [queryClient])

  // Any 401 (expired or revoked token) ends the session; RequireAuth then redirects to /login.
  useEffect(() => {
    setUnauthorizedHandler(endSession)
  }, [endSession])

  // Restore a persisted session by asking the API who the token belongs to.
  useEffect(() => {
    if (status !== 'loading') return
    fetchCurrentUser()
      .then((current) => {
        setUser(current)
        setStatus('authenticated')
      })
      .catch(endSession)
  }, [status, endSession])

  const login = useCallback(async (email: string, password: string) => {
    const session = await loginRequest(email, password)
    tokenStorage.set(session.token)
    setUser(session.user)
    setStatus('authenticated')
  }, [])

  const value = useMemo<AuthContextValue>(
    () => ({ status, user, login, logout: endSession }),
    [status, user, login, endSession],
  )

  return <AuthContext value={value}>{children}</AuthContext>
}
