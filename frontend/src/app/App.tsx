import { lazy, Suspense } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import { AppLayout } from '@/components/AppLayout'
import { FullPageSpinner } from '@/components/FullPageSpinner'
import { NotFoundPage } from '@/components/NotFoundPage'
import { LoginPage } from '@/features/auth/LoginPage'
import { RequireAuth } from '@/features/auth/RequireAuth'
import { EmployeeDetailPage } from '@/features/employees/pages/EmployeeDetailPage'
import { EditEmployeePage, NewEmployeePage } from '@/features/employees/pages/EmployeeFormPage'
import { EmployeesPage } from '@/features/employees/pages/EmployeesPage'

// Charts are the heaviest dependency; load those pages on demand.
const InsightsPage = lazy(() =>
  import('@/features/insights/pages/InsightsPage').then((module) => ({ default: module.InsightsPage })),
)
const OutliersPage = lazy(() =>
  import('@/features/outliers/pages/OutliersPage').then((module) => ({ default: module.OutliersPage })),
)

export function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<RequireAuth />}>
        <Route element={<AppLayout />}>
          <Route index element={<Navigate to="/employees" replace />} />
          <Route path="employees" element={<EmployeesPage />} />
          <Route path="employees/new" element={<NewEmployeePage />} />
          <Route path="employees/:id" element={<EmployeeDetailPage />} />
          <Route path="employees/:id/edit" element={<EditEmployeePage />} />
          <Route
            path="insights"
            element={
              <Suspense fallback={<FullPageSpinner />}>
                <InsightsPage />
              </Suspense>
            }
          />
          <Route
            path="outliers"
            element={
              <Suspense fallback={<FullPageSpinner />}>
                <OutliersPage />
              </Suspense>
            }
          />
          <Route path="*" element={<NotFoundPage />} />
        </Route>
      </Route>
    </Routes>
  )
}
