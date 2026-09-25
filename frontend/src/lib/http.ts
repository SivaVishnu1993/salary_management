import axios, { AxiosError } from 'axios'
import { tokenStorage } from './tokenStorage'

// The single configured HTTP client. Feature api.ts modules wrap it with typed
// functions; components never import axios directly.
export const http = axios.create({
  baseURL: (import.meta.env.VITE_API_URL as string | undefined) ?? '/api/v1',
  headers: { Accept: 'application/json' },
})

http.interceptors.request.use((config) => {
  const token = tokenStorage.get()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

type UnauthorizedHandler = () => void
let onUnauthorized: UnauthorizedHandler = () => undefined

/** Registered by AuthProvider: called when any request is rejected with 401. */
export function setUnauthorizedHandler(handler: UnauthorizedHandler): void {
  onUnauthorized = handler
}

http.interceptors.response.use(undefined, (error: unknown) => {
  const isLoginAttempt = error instanceof AxiosError && error.config?.url === '/auth/login'
  if (error instanceof AxiosError && error.response?.status === 401 && !isLoginAttempt) {
    tokenStorage.clear()
    onUnauthorized()
  }
  return Promise.reject(error instanceof Error ? error : new Error(String(error)))
})
