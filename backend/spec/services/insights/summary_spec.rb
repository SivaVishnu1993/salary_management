require "rails_helper"

RSpec.describe Insights::Summary do
  before { create_sample_payroll }

  it "aggregates headcount and USD pay across currencies" do
    # USD values: 10k, 30k, 50k, 60k, 100k, 200k -> total 450k, mean 75k,
    # median of an even count = (50k + 60k) / 2 = 55k
    expect(described_class.call).to eq(
      headcount: 6,
      total_payroll_usd_cents: usd(450_000),
      median_salary_usd_cents: usd(55_000),
      average_salary_usd_cents: usd(75_000)
    )
  end

  it "narrows to a country" do
    # 100k, 200k, 50k -> median 100k, mean 116,666.67
    expect(described_class.call(country: "US")).to include(
      headcount: 3, median_salary_usd_cents: usd(100_000), average_salary_usd_cents: 11_666_667
    )
  end

  it "returns zeros and nils when nothing matches" do
    expect(described_class.call(department: "Design")).to eq(
      headcount: 0, total_payroll_usd_cents: 0, median_salary_usd_cents: nil, average_salary_usd_cents: nil
    )
  end
end
