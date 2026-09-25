require "rails_helper"

RSpec.describe Money do
  describe "#to_usd" do
    it "converts minor units using the USD-per-unit rate" do
      expect(described_class.new(cents: 1_000_000_00, currency: "INR").to_usd(BigDecimal("0.012")))
        .to eq(described_class.new(cents: 12_000_00, currency: "USD"))
    end

    it "rounds half up to the nearest cent without float drift" do
      expect(described_class.new(cents: 5, currency: "GBP").to_usd(BigDecimal("0.1")).cents).to eq(1)
    end
  end
end
