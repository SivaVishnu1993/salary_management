require "rails_helper"

RSpec.describe Seeds::SalaryBands do
  subject(:bands) { described_class.new(rng: Random.new(42), usd_per_unit:) }

  let(:usd_per_unit) { { "USD" => BigDecimal(1), "INR" => BigDecimal("0.012") } }
  let(:hire_date) { Date.new(2018, 1, 1) }
  let(:as_of) { Date.new(2026, 1, 1) }

  def history(country: "US", department: "Engineering", level: 3, hire: hire_date)
    bands.history(country:, department:, level:, hire_date: hire, as_of:)
  end

  it "starts on the hire date with strictly increasing dates up to as_of" do
    dates = history.map(&:effective_date)

    expect(dates.first).to eq(hire_date)
    expect(dates).to eq(dates.sort.uniq)
    expect(dates.last).to be <= as_of
  end

  it "only ever raises pay" do
    amounts = Array.new(50) { history.map(&:amount_cents) }

    expect(amounts).to all(satisfy { |series| series == series.sort && series.uniq.size == series.size })
  end

  it "produces one salary row when there has been no time for a raise" do
    expect(history(hire: as_of - 10).size).to eq(1)
  end

  it "keeps typical US senior engineer pay near the band midpoint" do
    midpoint_cents = 135_000 * 1.10 * 100
    currents = Array.new(200) { history.last.amount_cents }

    expect(currents.sum / currents.size.to_f).to be_within(midpoint_cents * 0.05).of(midpoint_cents)
  end

  it "pays in local currency using the FX rate" do
    inr = history(country: "IN", level: 1).last.amount_cents / 100.0
    expected_inr = 75_000 * 1.10 * 0.28 / 0.012

    expect(inr).to be_within(expected_inr * 0.55).of(expected_inr)
  end

  it "rounds to whole hundreds of the local currency" do
    expect(Array.new(20) { history.map(&:amount_cents) }.flatten).to all(satisfy { |cents| (cents % 100_00).zero? })
  end
end
