require "rails_helper"

RSpec.describe FxRate do
  describe "validations" do
    subject { build(:fx_rate, currency: "EUR", usd_per_unit: 1.08) }

    it { is_expected.to allow_value("GBP").for(:currency) }
    it { is_expected.not_to allow_value("gbp", "GB", "GBPX").for(:currency) }
    it { is_expected.to validate_numericality_of(:usd_per_unit).is_greater_than(0) }
  end

  it "rejects non-positive rates at the database level" do
    expect { described_class.insert!({ currency: "EUR", usd_per_unit: 0 }) }
      .to raise_error(ActiveRecord::StatementInvalid, /fx_rates_usd_per_unit_positive/)
  end
end
