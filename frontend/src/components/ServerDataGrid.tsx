import { DataGrid, type DataGridProps, type GridValidRowModel } from '@mui/x-data-grid'
import { PAGE_SIZE_OPTIONS } from '@/lib/pagination'

type ServerDataGridProps<R extends GridValidRowModel> = Omit<
  DataGridProps<R>,
  'paginationMode' | 'sortingMode' | 'filterMode'
>

/**
 * DataGrid preconfigured for server-driven data: pagination, sorting and
 * filtering happen in the API, so the browser only ever holds one page.
 */
export function ServerDataGrid<R extends GridValidRowModel>(props: ServerDataGridProps<R>) {
  return (
    <DataGrid<R>
      paginationMode="server"
      sortingMode="server"
      filterMode="server"
      pageSizeOptions={PAGE_SIZE_OPTIONS}
      disableColumnFilter
      disableRowSelectionOnClick
      disableColumnMenu
      autoHeight
      sx={{
        bgcolor: 'background.paper',
        '& .MuiDataGrid-row': { cursor: props.onRowClick ? 'pointer' : 'default' },
      }}
      {...props}
    />
  )
}
