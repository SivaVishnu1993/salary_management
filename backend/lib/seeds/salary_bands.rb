module Seeds
  # Pay model for demo data: plausible annual base salaries by level, department
  # and country, plus a raise history leading up to the current salary.
  class SalaryBands
    # Typical US base pay per level (USD, major units).
    US_BASE_USD = { 1 => 75_000, 2 => 100_000, 3 => 135_000, 4 => 175_000, 5 => 230_000 }.freeze
    DEPARTMENT_FACTOR = {
      "Engineering" => 1.10, "Product" => 1.10, "Design" => 1.00, "Finance" => 1.00,
      "Sales" => 0.95, "Marketing" => 0.90, "HR" => 0.85, "Operations" => 0.85
    }.freeze
    # Local market pay relative to the US, in USD terms.
    COUNTRY_FACTOR = {
      "US" => 1.00, "SG" => 0.85, "DE" => 0.80, "CA" => 0.80,
      "AU" => 0.80, "GB" => 0.75, "BR" => 0.30, "IN" => 0.28
    }.freeze
    TYPICAL_SPREAD = 0.12       # most people sit within ±12% of their band midpoint
    OUTLIER_RATE = 0.03         # ~3% are paid well off-band, so the outlier view has signal
    OUTLIER_SWING = (0.30..0.50)
    RAISE_RANGE = (0.03..0.10)
    MAX_RAISES = 3              # => 1..4 salary rows per employee
    DAYS_BETWEEN_RAISES = (365..425)
    ROUND_TO_UNITS = 100        # salaries are whole hundreds of local currency

    SalaryPoint = Data.define(:effective_date, :amount_cents)

    def initialize(rng:, usd_per_unit:)
      @rng = rng
      @usd_per_unit = usd_per_unit
    end

    # Oldest first; the last point is the current salary.
    def history(country:, department:, level:, hire_date:, as_of:)
      dates = raise_dates(hire_date, as_of)
      amounts = [ current_cents(country, department, level) ]
      (dates.size - 1).times { amounts.unshift(round_cents(amounts.first / (1 + rng.rand(RAISE_RANGE)))) }

      dates.zip(amounts).map { |date, cents| SalaryPoint.new(effective_date: date, amount_cents: cents) }
    end

    private

    attr_reader :rng, :usd_per_unit

    def current_cents(country, department, level)
      usd = US_BASE_USD.fetch(level) * DEPARTMENT_FACTOR.fetch(department) * COUNTRY_FACTOR.fetch(country)
      local = usd * variation / usd_per_unit.fetch(Country.currency_for(country)).to_f
      round_cents(local * 100)
    end

    def variation
      return 1 + rng.rand(-TYPICAL_SPREAD..TYPICAL_SPREAD) unless rng.rand < OUTLIER_RATE

      swing = rng.rand(OUTLIER_SWING)
      rng.rand < 0.5 ? 1 + swing : 1 - swing
    end

    def raise_dates(hire_date, as_of)
      dates = [ hire_date ]
      rng.rand(0..MAX_RAISES).times do
        next_date = dates.last + rng.rand(DAYS_BETWEEN_RAISES)
        break if next_date > as_of

        dates << next_date
      end
      dates
    end

    def round_cents(cents)
      unit_cents = ROUND_TO_UNITS * 100
      (cents / unit_cents).round * unit_cents
    end
  end
end
