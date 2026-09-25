// Display formatting. Amounts arrive as integer minor units; every supported
// currency has two decimals, so dividing by 100 gives major units.
const MINOR_UNITS = 100

const moneyFormatters = new Map<string, Intl.NumberFormat>()

function moneyFormatter(currency: string, compact: boolean): Intl.NumberFormat {
  const key = `${currency}:${String(compact)}`
  let formatter = moneyFormatters.get(key)
  if (!formatter) {
    formatter = new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency,
      maximumFractionDigits: compact ? 1 : 0,
      notation: compact ? 'compact' : 'standard',
    })
    moneyFormatters.set(key, formatter)
  }
  return formatter
}

export function formatMoney(cents: number | null | undefined, currency: string, compact = false): string {
  if (cents === null || cents === undefined) return '—'
  return moneyFormatter(currency, compact).format(cents / MINOR_UNITS)
}

export const formatUsd = (cents: number | null | undefined, compact = false): string =>
  formatMoney(cents, 'USD', compact)

export const toCents = (majorUnits: number): number => Math.round(majorUnits * MINOR_UNITS)

export const toMajorUnits = (cents: number): number => cents / MINOR_UNITS

const countFormatter = new Intl.NumberFormat()
export const formatCount = (value: number): string => countFormatter.format(value)

export function formatPercent(value: number): string {
  return `${value > 0 ? '+' : ''}${value.toFixed(1)}%`
}

const dateFormatter = new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeZone: 'UTC' })
export function formatDate(isoDate: string | null | undefined): string {
  return isoDate ? dateFormatter.format(new Date(`${isoDate.slice(0, 10)}T00:00:00Z`)) : '—'
}

/** Today's date as YYYY-MM-DD in the user's local time zone. */
export function todayIso(): string {
  const now = new Date()
  const offsetMs = now.getTimezoneOffset() * 60_000
  return new Date(now.getTime() - offsetMs).toISOString().slice(0, 10)
}
