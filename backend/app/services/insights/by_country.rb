module Insights
  # Headcount and pay per country, in local currency and USD. Largest payroll first.
  class ByCountry < Base
    def call
      rows = aggregate(
        employees_with_fx.group(:country),
        country: "employees.country", headcount: HEADCOUNT_SQL,
        total_local: TOTAL_LOCAL_SQL, median_local: MEDIAN_LOCAL_SQL,
        total_usd: TOTAL_USD_SQL, median_usd: MEDIAN_USD_SQL, average_usd: AVERAGE_USD_SQL
      )
      rows.map { |row| present(row) }.sort_by { |row| [ -row[:total_payroll_usd_cents], row[:country] ] }
    end

    private

    def present(row)
      country = Country.find(row[:country])
      {
        country: row[:country], country_name: country&.name, currency: country&.currency,
        headcount: row[:headcount],
        total_payroll_cents: cents(row[:total_local]), median_salary_cents: cents(row[:median_local]),
        total_payroll_usd_cents: cents(row[:total_usd]) || 0,
        median_salary_usd_cents: cents(row[:median_usd]), average_salary_usd_cents: cents(row[:average_usd])
      }
    end
  end
end
