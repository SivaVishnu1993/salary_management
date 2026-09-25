module Insights
  # Org-wide (or filtered) headline numbers, normalized to USD.
  class Summary < Base
    def call
      row = aggregate(employees_with_fx, headcount: HEADCOUNT_SQL, total: TOTAL_USD_SQL,
                                         median: MEDIAN_USD_SQL, average: AVERAGE_USD_SQL).first
      {
        headcount: row[:headcount],
        total_payroll_usd_cents: cents(row[:total]) || 0,
        median_salary_usd_cents: cents(row[:median]),
        average_salary_usd_cents: cents(row[:average])
      }
    end
  end
end
