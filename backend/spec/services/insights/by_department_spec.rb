require "rails_helper"

RSpec.describe Insights::ByDepartment do
  before { create_sample_payroll }

  it "reports USD pay per department, largest payroll first" do
    # Engineering: 100k, 200k, 10k, 30k -> median (30k + 100k) / 2 = 65k
    # Sales: 50k, 60k
    expect(described_class.call).to eq([
      { department: "Engineering", headcount: 4, total_payroll_usd_cents: usd(340_000),
        median_salary_usd_cents: usd(65_000), average_salary_usd_cents: usd(85_000) },
      { department: "Sales", headcount: 2, total_payroll_usd_cents: usd(110_000),
        median_salary_usd_cents: usd(55_000), average_salary_usd_cents: usd(55_000) }
    ])
  end

  it "narrows to a country" do
    expect(described_class.call(country: "IN")).to contain_exactly(
      include(department: "Engineering", headcount: 2, total_payroll_usd_cents: usd(40_000))
    )
  end
end
