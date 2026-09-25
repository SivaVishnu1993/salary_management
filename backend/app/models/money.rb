# Immutable monetary amount in minor units (cents, pence, paise) plus an ISO 4217
# currency code. Integer minor units avoid floating-point rounding errors.
Money = Data.define(:cents, :currency) do
  # Converts using a USD-per-unit rate. Minor units cancel out because every
  # supported currency has two decimal places.
  def to_usd(usd_per_unit)
    Money.new(cents: (BigDecimal(cents) * BigDecimal(usd_per_unit.to_s)).round.to_i, currency: "USD")
  end
end
