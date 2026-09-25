# Directory query: composes Employee filter scopes, then applies a whitelisted
# sort. Unknown sort keys fall back to name; id breaks ties so pages are stable.
class EmployeesQuery
  DEFAULT_SORT = "name".freeze
  DIRECTIONS = %w[asc desc].freeze

  # Strategy table: sort key => order expressions for a direction.
  SORTS = {
    "name" => ->(dir) { [ { last_name: dir }, { first_name: dir } ] },
    "employee_code" => ->(dir) { [ { employee_code: dir } ] },
    "country" => ->(dir) { [ { country: dir } ] },
    "department" => ->(dir) { [ { department: dir } ] },
    "job_title" => ->(dir) { [ { job_title: dir } ] },
    "hire_date" => ->(dir) { [ { hire_date: dir } ] },
    "salary_usd" => ->(dir) { [ Arel.sql("#{Employee::SALARY_USD_CENTS_SQL} #{dir.upcase} NULLS LAST") ] }
  }.freeze

  def self.call(...) = new(...).call

  def initialize(params = {}, relation: Employee.all)
    @params = params
    @relation = relation
  end

  def call
    relation
      .with_usd_salary
      .in_country(params[:country])
      .in_department(params[:department])
      .with_job_title(params[:job_title])
      .search(params[:q])
      .order(*sort_order, id: direction)
  end

  private

  attr_reader :params, :relation

  def sort_order = SORTS.fetch(sort_key).call(direction)

  def sort_key = SORTS.key?(params[:sort]) ? params[:sort] : DEFAULT_SORT

  def direction = DIRECTIONS.include?(params[:direction]) ? params[:direction].to_sym : :asc
end
