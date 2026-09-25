require "rails_helper"

RSpec.describe Country do
  describe ".all" do
    it "loads every supported country from config" do
      expect(described_class.codes).to contain_exactly("US", "GB", "DE", "IN", "CA", "AU", "SG", "BR")
    end
  end

  describe ".find" do
    it "returns the country for a code, case-insensitively" do
      expect(described_class.find("de")).to have_attributes(code: "DE", name: "Germany", currency: "EUR")
    end

    it "returns nil for an unsupported code" do
      expect(described_class.find("FR")).to be_nil
    end
  end

  describe ".currency_for" do
    it "returns the pay currency of the country" do
      expect(described_class.currency_for("IN")).to eq("INR")
    end

    it "returns nil when the country is unknown or blank" do
      expect([ described_class.currency_for("XX"), described_class.currency_for(nil) ]).to all(be_nil)
    end
  end
end
