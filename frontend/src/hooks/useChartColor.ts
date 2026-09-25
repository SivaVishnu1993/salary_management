import { useColorScheme } from '@mui/material/styles'
import { SERIES_COLOR } from '@/app/theme'

/** The single-series chart colour for the active light/dark mode. */
export function useChartColor(): string {
  const { mode, systemMode } = useColorScheme()
  const resolved = mode === 'system' ? systemMode : mode
  return resolved === 'dark' ? SERIES_COLOR.dark : SERIES_COLOR.light
}
