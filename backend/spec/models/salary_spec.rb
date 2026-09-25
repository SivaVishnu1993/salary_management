require "rails_helper"

RSpec.describe Salary do
  describe "associations" do
    it { is_expected.to belong_to(:employee) }
  end

  describe "validations" do
    subject(:salary) { build(:salary) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:effective_date) }
    it { is_expected.to validate_length_of(:note).is_at_most(Salary::NOTE_MAX_LENGTH) }

    it "rejects a currency that does not match the employee's country" do
      salary = build(:salary, employee: build(:employee, country: "GB"), currency: "USD")

      expect(validation_errors(salary, :currency)).to include("must be GBP for this country")
    end

    it "rejects an effective date in the future" do
      travel_to(Date.new(2026, 1, 10)) do
        salary.effective_date = Date.new(2026, 2, 1)

        expect(validation_errors(salary, :effective_date)).to include("can't be in the future")
      end
    end

    it "rejects an amount above the USD sanity limit (e.g. extra zeros)" do
      salary = build(:salary, employee: build(:employee, country: "AU"), amount_cents: 188_300_200_000_00)

      expect(validation_errors(salary, :amount_cents)).to include(a_string_starting_with("is above the $10,000,000 (USD)"))
    end

    it "accepts large but plausible local-currency amounts" do
      salary = build(:salary, employee: build(:employee, country: "IN"), amount_cents: 5_00_00_000_00) # 5 crore INR = $600k

      expect(validation_errors(salary, :amount_cents)).to be_empty
    end

    it "allows one salary per employee per effective date" do
      existing = create(:salary)
      duplicate = build(:salary, employee: existing.employee, effective_date: existing.effective_date)

      expect(validation_errors(duplicate, :effective_date)).to include("has already been taken")
    end
  end

  describe "#amount" do
    it "returns the amount as Money" do
      expect(build(:salary, amount_cents: 500_00, currency: "USD").amount)
        .to eq(Money.new(cents: 500_00, currency: "USD"))
    end
  end

  describe "immutability" do
    it "cannot be edited once persisted" do
      salary = create(:salary)

      expect { salary.update!(amount_cents: 1) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe "scopes" do
    let(:employee) { create(:employee, hire_date: Date.new(2020, 1, 1)) }
    let!(:first) { create(:salary, employee:, effective_date: Date.new(2020, 1, 1)) }
    let!(:second) { create(:salary, employee:, effective_date: Date.new(2022, 6, 1)) }
    let!(:third) { create(:salary, employee:, effective_date: Date.new(2024, 3, 1)) }

    it ".effective_on_or_before includes the boundary date and excludes later ones" do
      expect(described_class.effective_on_or_before(Date.new(2022, 6, 1))).to contain_exactly(first, second)
    end

    it ".chronological orders oldest first" do
      expect(described_class.chronological).to eq([ first, second, third ])
    end

    it ".latest_first orders newest first" do
      expect(described_class.latest_first).to eq([ third, second, first ])
    end
  end

  describe "database constraints" do
    it "enforces one salary per employee per day even without validations" do
      salary = create(:salary)
      attrs = salary.attributes.slice("employee_id", "amount_cents", "currency", "effective_date")

      expect { described_class.insert!(attrs) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "is removed when its employee is deleted" do
      salary = create(:salary)

      salary.employee.destroy!

      expect(described_class.exists?(salary.id)).to be(false)
    end
  end
end
