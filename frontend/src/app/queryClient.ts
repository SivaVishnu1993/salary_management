import { QueryClient } from '@tanstack/react-query'
import { AxiosError } from 'axios'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      refetchOnWindowFocus: false,
      // Client errors (401/404/422) won't succeed on retry; network blips might.
      retry: (failureCount, error) =>
        failureCount < 2 && !(error instanceof AxiosError && (error.response?.status ?? 500) < 500),
    },
  },
})
