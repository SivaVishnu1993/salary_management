module Insights
  # Shared plumbing for pay insights. Every insight aggregates in SQL (one query)
  # and returns plain, JSON-ready data, which is what makes results cacheable.
  #
  # Filters are optional and compose Employee scopes, so every insight can be
  # narrowed to a country and/or department.
  class Base < ApplicationService
    USD = Employee::SALARY_USD_CENTS_SQL
    LOCAL = "employees.current_salary_cents".freeze

    HEADCOUNT_SQL = "COUNT(*)".freeze
    TOTAL_USD_SQL = "SUM(#{USD})".freeze
    MEDIAN_USD_SQL = "percentile_cont(0.5) WITHIN GROUP (ORDER BY #{USD})".freeze
    AVERAGE_USD_SQL = "AVG(#{USD})".freeze
    TOTAL_LOCAL_SQL = "SUM(#{LOCAL})".freeze
    MIN_LOCAL_SQL = "MIN(#{LOCAL})".freeze
    MEDIAN_LOCAL_SQL = "percentile_cont(0.5) WITHIN GROUP (ORDER BY #{LOCAL})".freeze
    AVERAGE_LOCAL_SQL = "AVG(#{LOCAL})".freeze
    MAX_LOCAL_SQL = "MAX(#{LOCAL})".freeze

    def initialize(country: nil, department: nil)
      @country = country
      @department = department
    end

    private

    attr_reader :country, :department

    def employees = Employee.in_country(country).in_department(department)

    def employees_with_fx = employees.left_joins(:fx_rate)

    def aggregate(relation, **columns)
      relation.pluck(*columns.values.map { |sql| Arel.sql(sql) }).map { |row| columns.keys.zip(row).to_h }
    end

    # Money aggregates arrive as BigDecimal/Float; the API speaks integer cents.
    def cents(value) = value&.round&.to_i
  end
end
