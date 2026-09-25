import { createTheme } from '@mui/material/styles'

// Data-viz series colour (reference palette slot 1), stepped separately for each
// mode rather than auto-inverted. Used as the brand primary so UI and charts agree.
export const SERIES_COLOR = { light: '#2a78d6', dark: '#3987e5' } as const

export const theme = createTheme({
  cssVariables: { colorSchemeSelector: 'data-theme' },
  colorSchemes: {
    light: { palette: { primary: { main: SERIES_COLOR.light }, background: { default: '#f6f7f9' } } },
    dark: { palette: { primary: { main: SERIES_COLOR.dark } } },
  },
  shape: { borderRadius: 8 },
  typography: { h4: { fontWeight: 600 }, h6: { fontWeight: 600 } },
  components: {
    MuiButton: { defaultProps: { disableElevation: true } },
    MuiPaper: { defaultProps: { variant: 'outlined' } },
    MuiTextField: { defaultProps: { size: 'small', fullWidth: true } },
  },
})
