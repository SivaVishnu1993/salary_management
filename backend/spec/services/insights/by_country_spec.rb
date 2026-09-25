require "rails_helper"

RSpec.describe Insights::ByCountry do
  before { create_sample_payroll }

  it "reports local and USD pay per country, largest payroll first" do
    rows = described_class.call

    expect(rows.pluck(:country)).to eq(%w[US GB IN])
    expect(rows.last).to eq(
      country: "IN", country_name: "India", currency: "INR", headcount: 2,
      total_payroll_cents: 4_000_000_00, median_salary_cents: 2_000_000_00,
      total_payroll_usd_cents: usd(40_000), median_salary_usd_cents: usd(20_000), average_salary_usd_cents: usd(20_000)
    )
  end

  it "still reports a country that has been removed from config, without a name or currency" do
    allow(Country).to receive(:find).and_call_original
    allow(Country).to receive(:find).with("GB").and_return(nil)

    expect(described_class.call.find { |row| row[:country] == "GB" })
      .to include(country_name: nil, currency: nil, headcount: 1)
  end

  it "narrows to a department" do
    expect(described_class.call(department: "Sales").pluck(:country, :headcount)).to eq([ [ "GB", 1 ], [ "US", 1 ] ])
  end
end
