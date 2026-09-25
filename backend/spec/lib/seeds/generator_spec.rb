require "rails_helper"

RSpec.describe Seeds::Generator do
  let(:as_of) { Date.new(2026, 6, 30) }

  before { FxRates::Sync.call }

  def generate(count: 60, seed: 42) = described_class.call(count:, seed:, as_of:)

  it "creates the requested number of employees, each with 1-4 salary records" do
    stats = generate

    per_employee = Salary.group(:employee_id).count.values
    expect(stats.employees).to eq(60)
    expect(per_employee.size).to eq(60)
    expect(per_employee).to all(be_between(1, 4))
    expect(stats.salaries).to eq(per_employee.sum)
  end

  it "keeps the cached current salary equal to the latest salary record" do
    generate

    Employee.includes(:salaries).find_each do |employee|
      latest = employee.salaries.max_by(&:effective_date)
      expect([ employee.current_salary_cents, employee.current_salary_currency ])
        .to eq([ latest.amount_cents, latest.currency ])
    end
  end

  it "generates records that pass every model validation" do
    generate

    expect(Employee.all.reject(&:valid?)).to be_empty
    expect(Salary.includes(:employee).reject(&:valid?)).to be_empty
  end

  it "never dates a hire or salary after as_of" do
    generate

    expect(Employee.maximum(:hire_date)).to be <= as_of
    expect(Salary.maximum(:effective_date)).to be <= as_of
  end

  it "is deterministic for the same seed" do
    snapshot = -> { Employee.order(:id).pluck(:employee_code, :email, :job_title, :current_salary_cents) }

    generate
    first_run = snapshot.call
    generate

    expect(snapshot.call).to eq(first_run)
    expect(first_run.first.first).to eq("ACME-000001")
  end

  it "differs for a different seed" do
    generate(seed: 1)
    first = Employee.order(:id).pluck(:email)
    generate(seed: 2)

    expect(Employee.order(:id).pluck(:email)).not_to eq(first)
  end

  it "replaces existing employees instead of appending" do
    2.times { generate(count: 10) }

    expect(Employee.count).to eq(10)
  end

  it "invalidates cached insights, since bulk inserts skip model callbacks" do
    version = Insights::CacheVersion.current

    generate(count: 5)

    expect(Insights::CacheVersion.current).not_to eq(version)
  end

  it "inserts across multiple batches" do
    stub_const("#{described_class}::BATCH_SIZE", 7)

    expect(generate(count: 20).employees).to eq(20)
  end
end
