import { useCallback, useMemo } from 'react'
import { useSearchParams } from 'react-router-dom'

type UrlState<K extends string> = Record<K, string>

/**
 * Keeps a flat set of string values in the URL query string, so filtered and
 * paginated views are shareable and survive reloads. Defaults are omitted from
 * the URL to keep it short.
 */
export function useUrlState<K extends string>(defaults: UrlState<K>) {
  const [searchParams, setSearchParams] = useSearchParams()

  const state = useMemo(() => {
    const entries = (Object.keys(defaults) as K[]).map((key) => [key, searchParams.get(key) ?? defaults[key]])
    return Object.fromEntries(entries) as UrlState<K>
  }, [searchParams, defaults])

  const update = useCallback(
    (changes: Partial<UrlState<K>>) => {
      setSearchParams(
        (current) => {
          const next = new URLSearchParams(current)
          for (const [key, value] of Object.entries(changes) as [K, string | undefined][]) {
            if (value === undefined || value === '' || value === defaults[key]) next.delete(key)
            else next.set(key, value)
          }
          return next
        },
        { replace: true },
      )
    },
    [setSearchParams, defaults],
  )

  return [state, update] as const
}
