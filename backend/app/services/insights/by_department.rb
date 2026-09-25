module Insights
  # Headcount and USD pay per department. Largest payroll first.
  class ByDepartment < Base
    def call
      rows = aggregate(
        employees_with_fx.group(:department),
        department: "employees.department", headcount: HEADCOUNT_SQL,
        total_usd: TOTAL_USD_SQL, median_usd: MEDIAN_USD_SQL, average_usd: AVERAGE_USD_SQL
      )
      rows.map { |row| present(row) }.sort_by { |row| [ -row[:total_payroll_usd_cents], row[:department] ] }
    end

    private

    def present(row)
      {
        department: row[:department], headcount: row[:headcount],
        total_payroll_usd_cents: cents(row[:total_usd]) || 0,
        median_salary_usd_cents: cents(row[:median_usd]), average_salary_usd_cents: cents(row[:average_usd])
      }
    end
  end
end
