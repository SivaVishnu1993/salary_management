require "rails_helper"

RSpec.describe Employees::Create do
  let(:attributes) do
    { first_name: "Priya", last_name: "Iyer", email: "priya@acme.test", department: "Engineering",
      job_title: "Software Engineer II", country: "IN", hire_date: "2024-02-01" }
  end
  let(:salary) { { amount_cents: 1_800_000_00, effective_date: "2024-02-01", note: "Offer" } }

  before { travel_to(Date.new(2026, 1, 15)) }

  it "creates the employee with a first salary record and a matching cache" do
    result = described_class.call(attributes:, salary:)

    employee = result.value
    expect(result).to be_success
    expect(employee.salaries.sole).to have_attributes(amount_cents: 1_800_000_00, currency: "INR", note: "Offer")
    expect(employee.reload.current_salary).to eq(Money.new(cents: 1_800_000_00, currency: "INR"))
  end

  it "derives the currency from the country" do
    result = described_class.call(attributes: attributes.merge(country: "DE"), salary:)

    expect(result.value.salaries.first.currency).to eq("EUR")
  end

  it "defaults the salary effective date to the hire date" do
    result = described_class.call(attributes:, salary: salary.except(:effective_date))

    expect(result.value.salaries.first.effective_date).to eq(Date.new(2024, 2, 1))
  end

  it "returns employee and salary errors without persisting anything" do
    result = nil

    expect { result = described_class.call(attributes: attributes.merge(email: ""), salary: { amount_cents: 0 }) }
      .not_to change(Employee, :count)
    expect(result).to be_failure
    expect(result.error).to include(:email, :"salary.amount_cents")
  end

  it "does not duplicate salary errors under the employee's cache columns" do
    result = described_class.call(attributes:, salary: { amount_cents: -1 })

    expect(result.error.keys).to eq([ :"salary.amount_cents" ])
  end

  it "rejects a future-dated starting salary" do
    result = described_class.call(attributes:, salary: salary.merge(effective_date: "2026-02-01"))

    expect(result.error[:"salary.effective_date"]).to include("can't be in the future")
  end
end
