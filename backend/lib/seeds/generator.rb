module Seeds
  # Replaces all employees and salaries with a realistic, reproducible workforce.
  # The same seed and as_of date always produce identical data.
  #
  # Bulk-inserts in batches (no per-row callbacks) so 10k employees take seconds.
  # Model validations and callbacks are bypassed by insert_all: the spec asserts
  # the data still satisfies validations, and the insights cache is invalidated
  # explicitly (after_commit would normally do it).
  class Generator
    DEFAULT_COUNT = 10_000
    DEFAULT_RANDOM_SEED = 42
    BATCH_SIZE = 1_000
    EARLIEST_HIRE_DATE = Date.new(2012, 1, 1)
    MIN_TENURE_DAYS = 30

    COUNTRY_WEIGHTS = { "US" => 30, "IN" => 25, "GB" => 10, "DE" => 8, "CA" => 8, "BR" => 7, "AU" => 6, "SG" => 6 }.freeze
    DEPARTMENT_WEIGHTS = {
      "Engineering" => 35, "Sales" => 15, "Operations" => 12, "Product" => 8,
      "Marketing" => 8, "Finance" => 8, "HR" => 8, "Design" => 6
    }.freeze
    LEVEL_WEIGHTS = { 1 => 25, 2 => 30, 3 => 25, 4 => 14, 5 => 6 }.freeze

    Stats = Data.define(:employees, :salaries, :seconds)

    def self.call(...) = new(...).call

    def initialize(count: DEFAULT_COUNT, seed: DEFAULT_RANDOM_SEED, as_of: Date.current)
      @count = count
      @as_of = as_of
      @rng = Random.new(seed)
      @countries = WeightedSampler.new(COUNTRY_WEIGHTS, rng:)
      @departments = WeightedSampler.new(DEPARTMENT_WEIGHTS, rng:)
      @levels = WeightedSampler.new(LEVEL_WEIGHTS, rng:)
      @people = People.new(rng:)
    end

    def call
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      ActiveRecord::Base.transaction do
        reset!
        pay = SalaryBands.new(rng:, usd_per_unit: FxRate.pluck(:currency, :usd_per_unit).to_h)
        count.times.each_slice(BATCH_SIZE) { |batch| insert_batch(batch.size, pay) }
      end
      Insights::CacheVersion.bump!
      Stats.new(employees: Employee.count, salaries: Salary.count,
                seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).round(2))
    end

    private

    attr_reader :count, :as_of, :rng, :countries, :departments, :levels, :people

    # RESTART IDENTITY restarts ids, so employee codes (derived from id) are reproducible too.
    def reset!
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE salaries, employees RESTART IDENTITY")
    end

    def insert_batch(size, pay)
      employees = Array.new(size) { build_employee(pay) }
      ids = Employee.insert_all!(employees.map { |e| e[:row] }, returning: :id).rows.flatten
      Salary.insert_all!(ids.zip(employees).flat_map { |id, employee| salary_rows(id, employee) })
    end

    def build_employee(pay)
      country = countries.sample
      department = departments.sample
      level = levels.sample
      hire_date = random_hire_date
      person = people.build(country)
      history = pay.history(country:, department:, level:, hire_date:, as_of:)

      row = {
        first_name: person.first_name, last_name: person.last_name, email: person.email,
        department:, job_title: title_for(department, level), country:, hire_date:,
        current_salary_cents: history.last.amount_cents, current_salary_currency: Country.currency_for(country)
      }
      { row:, history: }
    end

    def salary_rows(employee_id, employee)
      currency = employee[:row][:current_salary_currency]
      employee[:history].map do |point|
        { employee_id:, amount_cents: point.amount_cents, currency:, effective_date: point.effective_date }
      end
    end

    def title_for(department, level)
      Department.find(department).job_titles.find { |title| title.level == level }.name
    end

    def random_hire_date
      EARLIEST_HIRE_DATE + rng.rand(0..(as_of - MIN_TENURE_DAYS - EARLIEST_HIRE_DATE).to_i)
    end
  end
end
