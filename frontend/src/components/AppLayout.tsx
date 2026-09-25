import BarChart from '@mui/icons-material/BarChart'
import DarkMode from '@mui/icons-material/DarkMode'
import LightMode from '@mui/icons-material/LightMode'
import Logout from '@mui/icons-material/Logout'
import Menu from '@mui/icons-material/Menu'
import People from '@mui/icons-material/People'
import ReportProblemOutlined from '@mui/icons-material/ReportProblemOutlined'
import {
  AppBar,
  Box,
  Drawer,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Tooltip,
  Typography,
} from '@mui/material'
import { useColorScheme } from '@mui/material/styles'
import { useState } from 'react'
import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '@/features/auth/useAuth'

const DRAWER_WIDTH = 232

const NAV_ITEMS = [
  { to: '/employees', label: 'Employees', icon: <People /> },
  { to: '/insights', label: 'Pay insights', icon: <BarChart /> },
  { to: '/outliers', label: 'Pay outliers', icon: <ReportProblemOutlined /> },
]

function Navigation({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <List component="nav" aria-label="Main" sx={{ px: 1 }}>
      {NAV_ITEMS.map((item) => (
        <ListItemButton
          key={item.to}
          component={NavLink}
          to={item.to}
          onClick={onNavigate}
          sx={{ borderRadius: 1, mb: 0.5, '&.active': { bgcolor: 'action.selected', fontWeight: 600 } }}
        >
          <ListItemIcon sx={{ minWidth: 40 }}>{item.icon}</ListItemIcon>
          <ListItemText primary={item.label} />
        </ListItemButton>
      ))}
    </List>
  )
}

function ThemeToggle() {
  const { mode, systemMode, setMode } = useColorScheme()
  const isDark = (mode === 'system' ? systemMode : mode) === 'dark'
  return (
    <Tooltip title={isDark ? 'Light mode' : 'Dark mode'}>
      <IconButton
        color="inherit"
        onClick={() => {
          setMode(isDark ? 'light' : 'dark')
        }}
        aria-label="Toggle colour mode"
      >
        {isDark ? <LightMode /> : <DarkMode />}
      </IconButton>
    </Tooltip>
  )
}

/** Authenticated app shell: top bar, side navigation, routed content. */
export function AppLayout() {
  const { user, logout } = useAuth()
  const [mobileOpen, setMobileOpen] = useState(false)

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: 'background.default' }}>
      <AppBar position="fixed" elevation={0} sx={{ zIndex: (t) => t.zIndex.drawer + 1 }}>
        <Toolbar>
          <IconButton
            color="inherit"
            edge="start"
            aria-label="Open navigation"
            onClick={() => {
              setMobileOpen(true)
            }}
            sx={{ mr: 1, display: { md: 'none' } }}
          >
            <Menu />
          </IconButton>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }} noWrap>
            ACME Salary Management
          </Typography>
          <Typography variant="body2" sx={{ mr: 1, display: { xs: 'none', sm: 'block' } }}>
            {user?.name}
          </Typography>
          <ThemeToggle />
          <Tooltip title="Sign out">
            <IconButton color="inherit" onClick={logout} aria-label="Sign out">
              <Logout />
            </IconButton>
          </Tooltip>
        </Toolbar>
      </AppBar>

      <Drawer
        variant="temporary"
        open={mobileOpen}
        onClose={() => {
          setMobileOpen(false)
        }}
        sx={{ display: { xs: 'block', md: 'none' }, '& .MuiDrawer-paper': { width: DRAWER_WIDTH } }}
      >
        <Toolbar />
        <Navigation
          onNavigate={() => {
            setMobileOpen(false)
          }}
        />
      </Drawer>
      <Drawer
        variant="permanent"
        sx={{
          display: { xs: 'none', md: 'block' },
          width: DRAWER_WIDTH,
          flexShrink: 0,
          '& .MuiDrawer-paper': { width: DRAWER_WIDTH, boxSizing: 'border-box' },
        }}
      >
        <Toolbar />
        <Box sx={{ pt: 1 }}>
          <Navigation />
        </Box>
      </Drawer>

      <Box component="main" sx={{ flexGrow: 1, minWidth: 0, p: { xs: 2, md: 3 } }}>
        <Toolbar />
        <Outlet />
      </Box>
    </Box>
  )
}
