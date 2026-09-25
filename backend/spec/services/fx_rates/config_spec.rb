require "rails_helper"

RSpec.describe FxRates::Config do
  it "loads the version, as-of date and BigDecimal rates" do
    config = described_class.load

    expect(config.version).to be_a(Integer)
    expect(config.as_of).to be_a(Date)
    expect(config.usd_per_unit["INR"]).to eq(BigDecimal("0.012"))
  end

  it "covers the currency of every supported country" do
    expect(described_class.current.usd_per_unit.keys).to include(*Country.all.map(&:currency))
  end
end
