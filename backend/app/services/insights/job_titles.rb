module Insights
  # Pay distribution per job title within ONE country, in that country's
  # currency. Answers "what do we pay a Senior Engineer in India?". Staying in one
  # country means one currency, so no FX conversion distorts the comparison.
  #
  # Groups by job_title alone (department is implied by the title) so Postgres can
  # answer from the covering (country, job_title, current_salary_cents) index.
  class JobTitles < Base
    def initialize(country:, department: nil)
      super
    end

    def call
      rows = aggregate(
        employees.group(:job_title),
        job_title: "employees.job_title", headcount: HEADCOUNT_SQL,
        min: MIN_LOCAL_SQL, median: MEDIAN_LOCAL_SQL, average: AVERAGE_LOCAL_SQL, max: MAX_LOCAL_SQL
      )
      job_titles = rows.map { |row| present(row) }.sort_by { |row| [ row[:department].to_s, row[:level].to_i ] }
      { country:, currency: Country.currency_for(country), job_titles: }
    end

    private

    def present(row)
      department = Department.for_job_title(row[:job_title])
      {
        department: department&.name, job_title: row[:job_title],
        level: department&.job_title(row[:job_title])&.level, headcount: row[:headcount],
        min_cents: cents(row[:min]), median_cents: cents(row[:median]),
        average_cents: cents(row[:average]), max_cents: cents(row[:max])
      }
    end
  end
end
