require "rails_helper"

RSpec.describe EmployeeSerializer do
  let(:employee) { create(:employee, country: "IN", current_salary_cents: 1_000_000_00) }

  it "includes the USD salary when loaded with FX rates" do
    create(:fx_rate, currency: "INR", usd_per_unit: BigDecimal("0.012"))

    json = described_class.one(Employee.with_usd_salary.find(employee.id))

    expect(json).to include(country_name: "India", current_salary_usd_cents: 12_000_00,
                            current_salary: { amount_cents: 1_000_000_00, currency: "INR" })
  end

  it "reports a nil USD salary when the currency has no FX rate" do
    expect(described_class.one(Employee.with_usd_salary.find(employee.id))[:current_salary_usd_cents]).to be_nil
  end

  it "reports a nil country name for a country removed from config" do
    employee # persist before stubbing: validations look countries up too
    allow(Country).to receive(:find).and_return(nil)

    expect(described_class.one(employee)[:country_name]).to be_nil
  end

  it "serializes dates as ISO 8601" do
    expect(described_class.one(employee)).to include(hire_date: "2021-03-15", updated_at: employee.updated_at.iso8601)
  end
end
