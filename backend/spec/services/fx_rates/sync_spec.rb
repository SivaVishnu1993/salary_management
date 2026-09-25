require "rails_helper"

RSpec.describe FxRates::Sync do
  it "loads every configured currency" do
    described_class.call

    expect(FxRate.find("INR").usd_per_unit).to eq(BigDecimal("0.012"))
    expect(FxRate.count).to eq(Country.all.map(&:currency).uniq.size)
  end

  it "is idempotent and updates changed rates" do
    create(:fx_rate, currency: "EUR", usd_per_unit: 9)

    2.times { described_class.call }

    expect(FxRate.where(currency: "EUR").pluck(:usd_per_unit)).to eq([ BigDecimal("1.08") ])
  end

  it "loads an injected config" do
    config = FxRates::Config.new(version: 2, as_of: Date.new(2026, 1, 1), usd_per_unit: { "USD" => BigDecimal(1) })

    expect(described_class.call(config:).value).to eq(1)
  end
end
