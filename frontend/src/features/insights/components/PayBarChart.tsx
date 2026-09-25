import { BarChart } from '@mui/x-charts/BarChart'
import { useChartColor } from '@/hooks/useChartColor'
import { formatUsd } from '@/lib/format'

export interface BarDatum {
  label: string
  value: number
}

const ROW_HEIGHT = 36
const AXIS_ALLOWANCE = 48

/**
 * Single-series horizontal bar chart of a USD magnitude. Horizontal bars keep long
 * category names readable; one hue and no legend because the card title names
 * the series. Every bar has a hover tooltip, and the card offers a table view.
 */
export function PayBarChart({ data, ariaLabel }: { data: BarDatum[]; ariaLabel: string }) {
  const color = useChartColor()
  return (
    <BarChart
      aria-label={ariaLabel}
      dataset={data.map((d) => ({ ...d }))}
      layout="horizontal"
      height={data.length * ROW_HEIGHT + AXIS_ALLOWANCE}
      yAxis={[{ scaleType: 'band', dataKey: 'label', width: 120, disableTicks: true }]}
      xAxis={[{ valueFormatter: (value: number) => formatUsd(value, true), tickNumber: 4 }]}
      series={[{ dataKey: 'value', color, valueFormatter: (value) => formatUsd(value) }]}
      borderRadius={4}
      hideLegend
      grid={{ vertical: true }}
      margin={{ left: 0, right: 32, top: 8, bottom: 8 }}
    />
  )
}
