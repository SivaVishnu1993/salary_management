import { AxiosError } from 'axios'
import type { ApiErrorBody } from '@/types/api'

function body(error: unknown): ApiErrorBody | undefined {
  if (error instanceof AxiosError) {
    const data = error.response?.data as Partial<ApiErrorBody> | undefined
    if (data?.error) return data as ApiErrorBody
  }
  return undefined
}

/** Human-readable message for any failed request. */
export function errorMessage(error: unknown, fallback = 'Something went wrong. Please try again.'): string {
  return (
    body(error)?.error.message ??
    (error instanceof AxiosError && !error.response ? 'Cannot reach the server.' : fallback)
  )
}

/** Field-level validation messages from a 422 response ({ field: [messages] }). */
export function fieldErrors(error: unknown): Record<string, string> {
  const details = body(error)?.error.details ?? {}
  return Object.fromEntries(Object.entries(details).map(([field, messages]) => [field, messages.join(', ')]))
}
