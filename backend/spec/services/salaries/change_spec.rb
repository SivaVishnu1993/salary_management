require "rails_helper"

RSpec.describe Salaries::Change do
  let(:employee) do
    create(:employee, country: "GB", hire_date: Date.new(2022, 1, 1), current_salary_cents: 60_000_00)
  end

  before do
    travel_to(Date.new(2026, 1, 15))
    create(:salary, employee:, amount_cents: 60_000_00, effective_date: Date.new(2022, 1, 1))
  end

  def record_change(**args)
    described_class.call(employee:, amount_cents: 66_000_00, effective_date: Date.new(2025, 4, 1), **args)
  end

  it "appends a salary record in the employee's currency" do
    result = record_change(note: "Annual review")

    expect(result).to be_success
    expect(result.value).to have_attributes(amount_cents: 66_000_00, currency: "GBP", note: "Annual review")
    expect(employee.salaries.count).to eq(2)
  end

  it "updates the current salary cache to the new latest salary" do
    record_change

    expect(employee.reload.current_salary_cents).to eq(66_000_00)
  end

  it "keeps the cache on the latest salary when a back-dated change is recorded" do
    record_change
    described_class.call(employee:, amount_cents: 62_000_00, effective_date: Date.new(2023, 6, 1))

    expect(employee.reload.current_salary_cents).to eq(66_000_00)
    expect(employee.salaries.latest_first.map(&:amount_cents)).to eq([ 66_000_00, 62_000_00, 60_000_00 ])
  end

  it "rejects a future effective date" do
    result = record_change(effective_date: Date.new(2026, 1, 16))

    expect(result.error[:effective_date]).to include("can't be in the future")
  end

  it "rejects a second change on the same date" do
    record_change
    result = record_change(amount_cents: 70_000_00)

    expect(result.error[:effective_date]).to include("has already been taken")
  end

  it "rejects a non-positive amount and leaves the cache untouched" do
    result = record_change(amount_cents: 0)

    expect(result).to be_failure
    expect(employee.reload.current_salary_cents).to eq(60_000_00)
  end

  it "rolls back the salary record when the cache update fails" do
    allow(employee).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(employee))

    expect { record_change }.not_to change(Salary, :count)
  end

  it "locks the employee row while recording the change" do
    allow(employee).to receive(:lock!).and_call_original

    record_change

    expect(employee).to have_received(:lock!)
  end
end
